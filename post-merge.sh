#!/usr/bin/env bash
# deps-alert-hook
# Script ejecutado por Git despues de un merge o pull exitoso
CURRENT_VERSION="v1.0.6"

# 1. Analisis de repositorio
changed_files=$(git diff-tree -r --name-only ORIG_HEAD HEAD 2>/dev/null || true)

# 2. Chequeo de dependencias
dependency_files=(
  "package.json" "package-lock.json" "yarn.lock" "pnpm-lock.yaml"
  "requirements.txt" "Pipfile" "Pipfile.lock" "poetry.lock" "pyproject.toml"
  "Gemfile.lock" "composer.lock" "go.mod" "go.sum" "Cargo.lock"
  "build.gradle" "pom.xml"
)

# Leer configuracion personalizada si existe (.depsalertrc)
if [ -f ".depsalertrc" ]; then
  while IFS= read -r line; do
    # Ignorar lineas vacias y comentarios (que empiecen con #)
    if [[ -n "$line" && ! "$line" =~ ^# ]]; then
      dependency_files+=("$line")
    fi
  done <".depsalertrc"
fi

found_changes=false
changed_deps=""

# Comprobar si los archivos modificados estan en nuestra lista
for current_file in $changed_files; do
  for dep_file in "${dependency_files[@]}"; do
    if [[ "$(basename "$current_file")" == "$dep_file" ]]; then
      found_changes=true
      changed_deps="$changed_deps\n  - $current_file"
      break
    fi
  done
done

# 3. Alerta visual
if [ "$found_changes" = true ]; then
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  NC='\033[0m'
  echo -e "\n${YELLOW}======================================================================${NC}"
  echo -e "  ${RED}ATENCION:${NC} ${YELLOW}Se modificaron archivos de dependencias:${NC}"
  echo -e "$changed_deps"
  echo -e "\n  ${YELLOW}Verifica si necesitas instalar o actualizar paquetes.${NC}"
  echo -e "${YELLOW}======================================================================${NC}\n"
fi

# 4. Auto-Actualizacion
CHANGELOG_URL="https://raw.githubusercontent.com/JuanFerber/deps-alert/main/CHANGELOG.txt"
INSTALL_URL="https://raw.githubusercontent.com/JuanFerber/deps-alert/main/install.sh"

if remote_changelog=$(curl -s -m 3 "$CHANGELOG_URL" 2>/dev/null); then
  latest_version=$(echo "$remote_changelog" | head -n 1)

  # Validar que la version exista y sea mayor a la actual
  if [[ "$latest_version" != "$CURRENT_VERSION" && "$latest_version" =~ ^v[0-9] ]]; then
    CYAN='\033[0;36m'
    NC='\033[0m'
    echo -e "\n${CYAN}💡 Hay una nueva versión de deps-alert disponible ($latest_version).${NC}"
    echo -e "${CYAN}Novedades:${NC}"

    # Extraer todas las novedades en una variable
    changelog_updates=$(echo "$remote_changelog" | awk -v curr="$CURRENT_VERSION" '
      NR>1 {
        if ($0 == curr) exit
        print "  " $0
      }
    ')

    total_lines=$(echo "$changelog_updates" | wc -l)

    # Mostrar novedades (limitado a 15)
    if [ "$total_lines" -gt 15 ]; then
      echo "$changelog_updates" | head -n 15
      echo -e ""
      echo -n "¿Actualizar? (y=si, n=no, f=expandir $((total_lines - 15)) lineas ocultas): "
    else
      echo "$changelog_updates"
      echo -e ""
      echo -n "¿Deseas actualizar deps-alert de forma automática? (y/n): "
    fi

    # Iniciar flujo interactivo seguro para actualizar
    if [ -c /dev/tty ] && [ -t 1 ]; then
      while true; do
        # read -n 1 lee exactamente 1 caracter sin esperar a que el usuario presione Enter
        if read -n 1 -r update_response </dev/tty; then
          # Si presiona Enter accidentalmente (cadena vacia), lo ignoramos
          if [[ -z "$update_response" ]]; then
            continue
          fi
          
          echo "" # Salto de linea visual para que no se pegue el texto

          if [[ "$update_response" =~ ^[Yy] ]]; then
            echo "Descargando e instalando actualización..."
            curl -sL "$INSTALL_URL" | bash
            break
          elif [[ "$update_response" =~ ^[Nn] ]]; then
            break
          elif [[ "$update_response" =~ ^[Ff] && "$total_lines" -gt 15 ]]; then
            # Imprimir el resto del historial a partir de la linea 16
            echo "$changelog_updates" | tail -n +16
            echo -e ""
            echo -n "¿Deseas actualizar deps-alert de forma automática? (y/n): "
            total_lines=0 # Desactivamos la tecla 'f' para el resto del bucle
          else
            # Input invalido
            if [ "$total_lines" -gt 15 ]; then
              echo -n "(y/n/f): "
            else
              echo -n "(y/n): "
            fi
          fi
        else
          break
        fi
      done
    fi
  fi
fi

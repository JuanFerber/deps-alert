#!/usr/bin/env bash

# URL de donde se descargara el script principal de deps-alert
HOOK_URL="https://raw.githubusercontent.com/JuanFerber/deps-alert/main/post-merge.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Iniciando instalacion de deps-alert..."

# Validar que Git este instalado
if ! command -v git &>/dev/null; then
  echo -e "${RED}Error: Git no esta instalado en el sistema.${NC}"
  exit 1
fi

# Validar que estemos dentro de un proyecto de Git
if ! GIT_DIR=$(git rev-parse --git-dir 2>/dev/null); then
  echo -e "${RED}Error: No estas dentro de un proyecto Git.${NC}"
  exit 1
fi

# Preparar la carpeta de hooks
HOOKS_DIR="${GIT_DIR}/hooks"
HOOK_FILE="${HOOKS_DIR}/post-merge"

if [ ! -d "$HOOKS_DIR" ]; then
  echo "Creando carpeta de hooks..."
  mkdir "$HOOKS_DIR"
fi

# Validar existencia previa de un hook e interactuar con el usuario
if [ -f "$HOOK_FILE" ]; then
  # Prevenir bucle infinito: Si deps-alert ya esta instalado, solo lo actualizamos
  if grep -q "deps-alert" "$HOOK_FILE" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  deps-alert ya se encuentra instalado en este repositorio.${NC}"
    if [ -f "${HOOK_FILE}.deps-alert" ]; then
      echo "Actualizando el script secundario..."
      if command -v curl &>/dev/null; then
        curl -s -f -L "$HOOK_URL" -o "${HOOK_FILE}.deps-alert"
      else
        wget -q -O "${HOOK_FILE}.deps-alert" "$HOOK_URL"
      fi
      chmod +x "${HOOK_FILE}.deps-alert"
    else
      echo "Actualizando el script principal..."
      if command -v curl &>/dev/null; then
        curl -s -f -L "$HOOK_URL" -o "$HOOK_FILE"
      else
        wget -q -O "$HOOK_FILE" "$HOOK_URL"
      fi
      chmod +x "$HOOK_FILE"
    fi
    echo -e "${GREEN}✅ deps-alert actualizado a la ultima version correctamente.${NC}"
    exit 0
  fi

  echo -e "\n${YELLOW}⚠️  Detectamos que ya tienes un archivo 'post-merge' configurado en tu proyecto.${NC}"
  echo "Para no romper tu configuracion, podemos crear un 'dispatcher' que ejecute tu codigo actual y luego el nuestro."

  # Pregunta interactiva segura. Prevenimos fallos en entornos CI/CD (GitHub Actions, Docker) donde /dev/tty no existe
  user_response="y" # Respuesta por defecto
  if [ -c /dev/tty ] && [ -t 1 ]; then
    if read -r -p "¿Deseas que integremos deps-alert automaticamente? (y/n): " prompt_response </dev/tty 2>/dev/null; then
      user_response=${prompt_response:-y}
    fi
  else
    echo -e "Entorno no interactivo detectado. Asumiendo integracion automatica (y)..."
  fi

  if [[ "$user_response" =~ ^[Yy] ]]; then
    echo -e "\nIntegrando automaticamente..."

    # Movemos el hook del usuario a post-merge.local
    mv "$HOOK_FILE" "${HOOK_FILE}.local"

    # Descargamos deps-alert como post-merge.deps-alert
    if command -v curl &>/dev/null; then
      curl -s -f -L "$HOOK_URL" -o "${HOOK_FILE}.deps-alert"
    else
      wget -q -O "${HOOK_FILE}.deps-alert" "$HOOK_URL"
    fi
    chmod +x "${HOOK_FILE}.deps-alert"

    # Creamos el dispatcher (el nuevo post-merge)
    cat <<'EOF' >"$HOOK_FILE"
#!/usr/bin/env bash
# Dispatcher autogenerado por deps-alert

# 1. Ejecutar el hook original del usuario (si existe y es ejecutable)
if [ -x "$(dirname "$0")/post-merge.local" ]; then
    "$(dirname "$0")/post-merge.local" "$@"
fi

# 2. Ejecutar deps-alert
if [ -x "$(dirname "$0")/post-merge.deps-alert" ]; then
    "$(dirname "$0")/post-merge.deps-alert" "$@"
fi
EOF
    chmod +x "$HOOK_FILE"
    echo -e "${GREEN}✅ Integracion automatica completada. Tu codigo anterior sigue a salvo en 'post-merge.local'.${NC}"

  else
    echo -e "\nModo manual seleccionado."

    # Descargamos deps-alert aisladamente
    if command -v curl &>/dev/null; then
      curl -s -f -L "$HOOK_URL" -o "${HOOK_FILE}.deps-alert"
    else
      wget -q -O "${HOOK_FILE}.deps-alert" "$HOOK_URL"
    fi
    chmod +x "${HOOK_FILE}.deps-alert"

    echo -e "${GREEN}✅ Se ha descargado la herramienta como '.git/hooks/post-merge.deps-alert'${NC}"
    echo -e "${YELLOW}👉 IMPORTANTE: Para que funcione, debes abrir tu archivo '.git/hooks/post-merge' original y agregar la siguiente linea donde creas conveniente:${NC}\n"
    echo -e "    \"$(dirname \"\$0\")/post-merge.deps-alert\" \"\$@\"\n"
  fi

else
  # Instalacion normal si no habia hook previo
  echo "Descargando la herramienta..."
  if command -v curl &>/dev/null; then
    curl -s -f -L "$HOOK_URL" -o "$HOOK_FILE"
  else
    wget -q -O "$HOOK_FILE" "$HOOK_URL"
  fi

  if [ ! -f "$HOOK_FILE" ] || [ ! -s "$HOOK_FILE" ]; then
    echo -e "${RED}Error: No se pudo descargar el script.${NC}"
    exit 1
  fi

  chmod +x "$HOOK_FILE"
  echo -e "${GREEN}✅ ¡deps-alert se instalo correctamente!${NC}"
fi

#!/usr/bin/env bash
# deps-alert-hook
# Script ejecutado por Git despues de un merge o pull exitoso

# Obtener los archivos modificados en el ultimo pull
changed_files=$(git diff-tree -r --name-only ORIG_HEAD HEAD)

# Archivos de dependencias comunes a verificar
dependency_files=(
  "package.json" "package-lock.json" "yarn.lock" "pnpm-lock.yaml"
  "requirements.txt" "Pipfile" "Pipfile.lock" "poetry.lock" "pyproject.toml"
  "Gemfile.lock" "composer.lock" "go.mod" "go.sum" "Cargo.lock"
  "build.gradle" "pom.xml"
)

found_changes=false
changed_deps=""

# Verificar si alguno de los archivos modificados coincide con nuestra lista
for current_file in $changed_files; do
  for dep_file in "${dependency_files[@]}"; do
    if [[ "$(basename "$current_file")" == "$dep_file" ]]; then
      found_changes=true
      changed_deps="$changed_deps\n  - $current_file"
      break
    fi
  done
done

# Mostrar advertencia si hubo cambios
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

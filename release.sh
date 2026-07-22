#!/usr/bin/env bash

set -e # Detener si hay un error

if [ -z "$1" ]; then
  echo "Uso: ./release.sh <nueva_version> (Ejemplo: ./release.sh v1.0.3)"
  exit 1
fi

NEW_VERSION=$1
SCRIPT_FILE="post-merge.sh"
CHANGELOG_FILE="CHANGELOG.txt"

echo "🚀 Iniciando proceso de release para $NEW_VERSION"

# 1. Actualizar CURRENT_VERSION de forma universal (compatible con Linux y Mac)
sed -i.tmp "s/CURRENT_VERSION=\".*\"/CURRENT_VERSION=\"$NEW_VERSION\"/" "$SCRIPT_FILE"
rm -f "${SCRIPT_FILE}.tmp"
chmod +x "$SCRIPT_FILE"
echo "✅ Variable CURRENT_VERSION actualizada en $SCRIPT_FILE"

# 2. Pedir titulo del commit
echo -n "Escribe el titulo corto del commit (ej. feat: soporte configs): "
read -r COMMIT_TITLE
if [ -z "$COMMIT_TITLE" ]; then
  COMMIT_TITLE="chore: release $NEW_VERSION"
fi

# 3. Pedir novedades abriendo el editor de texto preferido del usuario (por defecto nano)
echo "$NEW_VERSION" >temp_changelog.txt
echo "- (Escribe tus cambios aqui. Borra este parentesis. Guarda y cierra el editor cuando termines)" >>temp_changelog.txt

# Abrir editor
${EDITOR:-nano} temp_changelog.txt

# Extraer el cuerpo del mensaje (saltando la linea 1 que tiene la version)
COMMIT_BODY=$(tail -n +2 temp_changelog.txt)

# Unir el texto nuevo con el changelog viejo
cat "$CHANGELOG_FILE" >>temp_changelog.txt
mv temp_changelog.txt "$CHANGELOG_FILE"
echo "✅ $CHANGELOG_FILE actualizado"

# 4. Operaciones de Git (Add, Commit, Tag, Push)
git add .
git commit -m "$COMMIT_TITLE" -m "$COMMIT_BODY"
git tag "$NEW_VERSION"
git push origin main
git push origin "$NEW_VERSION"

echo "🎉 Release $NEW_VERSION subido exitosamente a GitHub!"

# 🚨 deps-alert

[![ShellCheck](https://github.com/JuanFerber/deps-alert/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/JuanFerber/deps-alert/actions/workflows/shellcheck.yml)

¡Nunca más olvides instalar dependencias después de un `git pull`!

**deps-alert** es una herramienta global, simple y ligera escrita en Bash que se instala como un Git Hook (`post-merge`). Su única función es avisarte si un compañero de equipo modificó algún archivo de dependencias (como `package.json`, `requirements.txt`, `go.mod`, etc.) durante el último merge o pull.

_No instala nada automáticamente, solo te avisa para que tú tomes la decisión._

---

## 🚀 Instalación rápida

Puedes instalar **deps-alert** en cualquier repositorio ejecutando este único comando en tu terminal (asegúrate de estar en la raíz de tu proyecto):

```bash
curl -sL https://raw.githubusercontent.com/JuanFerber/deps-alert/main/install.sh | bash
```

### ¿Qué hace el instalador?

1. Verifica que estés dentro de un proyecto Git.
2. Descarga el script de alerta en `.git/hooks/post-merge`.
3. **¿Ya tienes un hook configurado?** ¡No hay problema! El instalador te preguntará de forma interactiva si quieres integrarlo automáticamente (creando un _dispatcher_ seguro que no borra tu código) o si prefieres agregar la línea de ejecución manualmente.

## 🛠️ Archivos soportados por defecto

Actualmente, el script vigila cambios en los siguientes archivos:

- Node.js: `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
- Python: `requirements.txt`, `Pipfile`, `Pipfile.lock`, `poetry.lock`, `pyproject.toml`
- Go: `go.mod`, `go.sum`
- Rust: `Cargo.lock`
- Java: `pom.xml`, `build.gradle`
- PHP/Ruby: `composer.lock`, `Gemfile.lock`

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Siéntete libre de abrir un issue o enviar un Pull Request si quieres agregar soporte para nuevos lenguajes o mejorar el script.

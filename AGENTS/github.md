
# Trabajar con GitHub

Como tiene que trabajar el agente de IA con GitHub:

### Commits y Estrrucutra

Los commits se estructuraran con un encabezado:

- **docs(commit):** Para commits de documentación
- **chore(commit):** Para commits de mantenimeinto y github workflows
- **bugfix(commit):** Para commits de corrección de bugs reportados
- **fix(commit):** Para commits de correcciónes
- **feature(commit):** Para commits de nuevas funcionalidades
- **release(commit):** Para commits de preparación para release
- **test(commit):** Para commits de tests
- **script(commit):** Para commits de scripts

### Ramas

Las ramas se estructuraran por vesiones, por defecto se trabaja en main.

- **v0.1.0** Branch que clone [main] para el MVP.
- **v1.0.0** Branch de producción que clone [main]

### Releases y Tags

Cuando tengamos una version estable prepararemos un release (producción) + un tag.

Por ejemplo:

- **@veyra-1.0.0** y un tag unido al release **v1.0.0**

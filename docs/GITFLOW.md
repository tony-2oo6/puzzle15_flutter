# Flujo de trabajo con Gitflow

## Ramas

| Rama | Propósito | Se crea desde | Se integra en |
|---|---|---|---|
| `main` | Versión publicada. Cada merge despliega a GitHub Pages. | — | — |
| `develop` | Integración del trabajo terminado. | `main` | `release/*` |
| `feature/<nombre>` | Una funcionalidad. | `develop` | `develop` (pull request) |
| `release/<versión>` | Preparar una versión (ajustes finales, versión en `pubspec.yaml`). | `develop` | `main` y `develop` |
| `hotfix/<nombre>` | Corrección urgente de producción. | `main` | `main` y `develop` |

Reglas:

- Nadie hace push directo a `main` ni a `develop`: todo entra por pull request revisado por el compañero.
- Protege `main` y `develop` en **Settings → Branches** exigiendo que pase el workflow `CI/CD · Flutter Web + PWA`.
- Antes de abrir un PR: `dart format .`, `flutter analyze` y `flutter test`.

## Convención de commits

Formato [Conventional Commits](https://www.conventionalcommits.org/es/) en español:

```
<tipo>(<ámbito>): <qué cambia, en imperativo>

<por qué, si no es obvio>
```

Tipos: `feat`, `fix`, `refactor`, `test`, `docs`, `style`, `ci`, `chore`.

Lo que pide el enunciado:

- Cada commit debe dejar el proyecto compilando y aportar algo real (funcionalidad, corrección o mejora).
- Nada de commits vacíos ni de borrar algo y volver a añadirlo en el siguiente commit.
- Los commits que solo cambian dependencias no cuentan: agrega cada dependencia junto con el código que la usa.

## Reparto sugerido para la pareja

Cada persona trabaja en sus ramas `feature/*`, abre el PR y la otra lo revisa. Así el historial muestra autoría y revisión de ambos. Orden recomendado (cada fila es una rama; los mensajes son ejemplos):

| # | Rama | Responsable | Archivos | Commits de ejemplo |
|---|---|---|---|---|
| 1 | `feature/board-logic` | Persona A | `lib/logic/puzzle_board.dart`, `test/puzzle_board_test.dart` | `feat(logic): generar tablero aleatorio resoluble por paridad de inversiones` · `feat(logic): mover piezas y deslizar filas/columnas` · `test(logic): verificar resolubilidad con BFS en 3x3` |
| 2 | `feature/settings-persistence` | Persona B | `lib/models/`, `lib/data/`, `lib/controllers/`, `test/persistence_test.dart` | `feat(data): persistir preferencias con shared_preferences` · `feat(data): guardar récords por dificultad` |
| 3 | `feature/theme-and-shell` | Persona B | `lib/core/`, `lib/app.dart`, `lib/main.dart`, fuentes | `feat(ui): tema claro/oscuro/automático con fuentes empaquetadas` |
| 4 | `feature/game-session` | Persona A | `lib/logic/puzzle_game.dart`, `test/puzzle_game_test.dart` | `feat(logic): cronómetro, pausa, victoria y derrota por tiempo` |
| 5 | `feature/game-screen` | Persona A | `lib/screens/game_screen.dart`, `lib/widgets/puzzle_board_view.dart`, `tile_face.dart`, `puzzle_art.dart` | `feat(game): tablero animado con estilos de piezas` · `feat(game): teclado, gestos y pausa automática` |
| 6 | `feature/splash-menu` | Persona B | `splash_screen.dart`, `menu_screen.dart`, `animated_menu_button.dart`, `appear.dart`, `themed_background.dart`, `game_logo.dart` | `feat(menu): splash y menú con animaciones de entrada y presión` |
| 7 | `feature/settings-screen` | Persona B | `settings_screen.dart`, `difficulty_picker.dart`, `common.dart` | `feat(settings): pantalla de configuración con vista previa de estilos` |
| 8 | `feature/high-scores` | Persona A | `high_scores_screen.dart`, `game_over_dialog.dart` | `feat(scores): marcadores por dificultad y pantalla de fin de partida` |
| 9 | `feature/instructions` | Persona B | `instructions_screen.dart` | `feat(help): pantalla de instrucciones` |
| 10 | `feature/pwa-ci` | Persona A + B | `web/`, `tool/pwa/`, `.github/workflows/` | `ci: build web, verificación PWA y despliegue en GitHub Pages` |
| 11 | `release/1.0.0` | Ambos | `pubspec.yaml`, `README.md` | `docs: README con arquitectura y despliegue` · `chore(release): versión 1.0.0` |

## Comandos de referencia

```bash
# Inicio del repositorio
git init -b main
git add README.md .gitignore pubspec.yaml analysis_options.yaml
git commit -m "chore: estructura inicial del proyecto Flutter"
git push -u origin main
git switch -c develop && git push -u origin develop

# Funcionalidad
git switch develop && git pull
git switch -c feature/board-logic
# ... trabajo y commits ...
git push -u origin feature/board-logic   # abrir PR hacia develop

# Versión
git switch develop && git pull
git switch -c release/1.0.0
# ... ajustes finales ...
# PR release/1.0.0 → main (despliega) y merge de vuelta a develop
git tag -a v1.0.0 -m "Versión 1.0.0" && git push --tags
```

Si usan la extensión `git flow` (`git flow init -d`), los comandos `git flow feature start <nombre>` / `finish` hacen lo mismo.

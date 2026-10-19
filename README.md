# 15-Puzzle Flutter

Rompecabezas deslizante (sliding puzzle) hecho con Flutter: tres dificultades, cinco estilos de piezas, tema claro/oscuro/automático, marcadores persistentes, modo contrarreloj y versión web instalable que funciona sin conexión (PWA) desplegada automáticamente en GitHub Pages.

## Funcionalidades

| Requisito | Dónde está |
|---|---|
| Splash con animación de entrada y botón "Saltar" | `lib/screens/splash_screen.dart` |
| Menú con botones grandes animados (escala + color) y aparición con `animate_do` | `lib/screens/menu_screen.dart`, `lib/widgets/animated_menu_button.dart` |
| Configuración: dificultad 3×3 / 4×4 / 5×5, tema claro/oscuro/automático, estilo de piezas (clásico, colorido, retro, minimalista, imagen), sonido, animaciones, contrarreloj | `lib/screens/settings_screen.dart` |
| Marcadores por dificultad: mejor tiempo, menos movimientos, fecha; mensaje si está vacío; borrar con confirmación | `lib/screens/high_scores_screen.dart`, `lib/data/high_score_repository.dart` |
| Instrucciones, condición de victoria y cuándo se pierde | `lib/screens/instructions_screen.dart` |
| Tablero aleatorio **siempre resoluble** (paridad de inversiones) | `lib/logic/puzzle_board.dart` |
| Contador de movimientos y cronómetro que arranca con el primer movimiento | `lib/logic/puzzle_game.dart` |
| Pantalla de fin de partida (¡Ganaste! / Perdiste, resumen, "¡Nuevo récord!", Reiniciar / Continuar / Menú) | `lib/widgets/game_over_dialog.dart` |
| Persistencia local de preferencias y récords | `lib/data/` (`shared_preferences`) |
| Diseño responsive (móvil, tablet, escritorio) | `LayoutBuilder` en `game_screen.dart`, `high_scores_screen.dart`, `settings_screen.dart` |
| CI/CD con GitHub Actions, despliegue en GitHub Pages y verificación PWA | `.github/workflows/ci-cd.yml`, `tool/pwa/` |

### Detalles de producto ("lo obvio" que pide el preparador)

- Se puede mover con toque, deslizando el dedo sobre el tablero o con el teclado (flechas / WASD). Tocar una pieza lejana en la fila o columna del hueco desliza toda la línea; cada pieza movida cuenta como un movimiento.
- Pausa con botón, tecla P o espacio. El tablero se oculta durante la pausa y la partida se pausa sola si la app pasa a segundo plano.
- Confirmación antes de salir, reiniciar o rendirse con una partida en curso (también con el botón "atrás" de Android).
- La primera vez que se pulsa "Jugar" se pide la dificultad; después se recuerda y se puede cambiar desde el menú.
- Indicador de piezas colocadas y punto en las piezas que ya están en su sitio.
- En modo contrarreloj el tiempo se vuelve rojo en los últimos 30 segundos.
- Fuentes (Nunito y Fredoka, licencia OFL) empaquetadas: el texto se ve igual en todas las plataformas y sin conexión.
- Accesibilidad: etiquetas semánticas en las piezas, tooltips, foco de teclado y respeto de "Animaciones desactivadas".

### ¿Se puede perder?

En el modo clásico no: todo tablero generado tiene solución. Para cumplir con la pantalla de derrota se añadió el **modo contrarreloj** (Configuración): si el tiempo llega a cero (Fácil 3 min · Medio 8 min · Difícil 15 min) la partida se pierde. En cualquier modo también se puede **rendirse**, lo que cuenta como derrota.

## Arquitectura

```
lib/
├── main.dart                 # Carga SharedPreferences y arranca la app
├── app.dart                  # MaterialApp + tema según preferencias
├── core/                     # Tema, transiciones, formato de tiempo/fecha, feedback
├── models/                   # Difficulty, TileStyle, AppSettings, ScoreEntry… (Dart puro)
├── logic/                    # Reglas del juego (Dart puro, 100 % testeable)
│   ├── puzzle_board.dart     # Tablero, barajado resoluble, movimientos, victoria
│   └── puzzle_game.dart      # Partida: estados, movimientos, cronómetro, derrota
├── data/                     # Persistencia (shared_preferences)
├── controllers/              # SettingsController (ChangeNotifier) + AppScope
├── screens/                  # Una pantalla por archivo
└── widgets/                  # Componentes reutilizables (tablero, piezas, diálogos…)
```

**Separación lógica / UI.** `logic/` y `models/` no importan Flutter: generan el tablero, validan movimientos y detectan victoria/derrota. Las pantallas solo traducen interacciones en llamadas a esa lógica y redibujan.

**Gestión de estado (sin paquetes externos).**

- `StatelessWidget` para pantallas sin estado propio: Menú, Instrucciones.
- `StatefulWidget` + `setState` donde el estado cambia en la propia pantalla:
  - **Juego**: cada movimiento, cada tick del cronómetro (100 ms), pausa y fin de partida.
  - **Marcadores**: récords cargados y su borrado.
  - **Configuración**: aviso "Guardado" al persistir un cambio.
  - **Splash**: temporizador de navegación.
- Las **preferencias** se comparten con un `ChangeNotifier` (`SettingsController`) expuesto mediante un `InheritedNotifier` (`AppScope`), ambos incluidos en Flutter. Así un cambio de tema o de estilo se refleja al instante en todas las pantallas sin pasar callbacks entre ellas.

**Algoritmo de barajado.** Se baraja con Fisher–Yates y se comprueba la paridad de inversiones: en anchos impares el tablero es resoluble si las inversiones son pares; en anchos pares, si `inversiones + fila del hueco contada desde abajo` es impar. Si no lo es, se intercambian dos piezas (una transposición invierte la paridad) y queda resoluble. La regla se verificó de forma exhaustiva sobre las 362 880 permutaciones del 3×3, y `test/puzzle_board_test.dart` lo comprueba con BFS.

## Cómo ejecutar

Requisitos: Flutter estable 3.32 o superior (Dart 3.8+).

```bash
# Solo la primera vez: genera las carpetas nativas (no sobrescribe lib/, web/ ni test/)
flutter create . --platforms=android,ios,web,windows,macos,linux --project-name puzzle15_flutter

flutter pub get
flutter run                 # dispositivo/emulador
flutter run -d chrome       # web
flutter test                # pruebas unitarias y de widgets
flutter analyze
dart format .               # antes de cada commit
```

### Probar la PWA en local

```bash
flutter build web --release --no-web-resources-cdn
cd tool/pwa && npm ci && npx playwright install chromium && cd ../..
node tool/pwa/generate_service_worker.mjs build/web
node tool/pwa/verify_pwa.mjs build/web --runtime
```

## Despliegue (GitHub Pages)

1. En el repositorio: **Settings → Pages → Build and deployment → Source: GitHub Actions**.
2. Cada push a `main` ejecuta `.github/workflows/ci-cd.yml`:
   1. `quality`: `flutter analyze` y `flutter test`.
   2. `build-web`: `flutter build web` con el `base-href` del repositorio, genera `sw.js`, y **verifica que sigue siendo PWA** (manifest, iconos, service worker, recursos en caché) abriendo la app en Chromium, cortando la red y comprobando que vuelve a cargar sin conexión.
   3. `deploy`: publica en `https://<usuario>.github.io/<repositorio>/`.
3. Los pull requests a `develop` o `main` ejecutan las mismas comprobaciones sin desplegar.

**Por qué un service worker propio:** desde Flutter 3.27 el `flutter_service_worker.js` generado ya no guarda la app en caché (solo se desregistra), así que el build por defecto no funciona offline. `web/flutter_bootstrap.js` registra `sw.js`, que `tool/pwa/generate_service_worker.mjs` crea tras cada build con la lista de archivos y un hash de versión.

## Flujo de trabajo en equipo

Ver [docs/GITFLOW.md](docs/GITFLOW.md): ramas, convención de commits y reparto de trabajo sugerido.

## Licencias

Código: uso académico. Fuentes Nunito y Fredoka: SIL Open Font License (`assets/fonts/OFL-*.txt`).

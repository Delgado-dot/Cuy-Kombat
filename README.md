# 🐹 Cuy Kombat

**Cuy Kombat** es un videojuego de peleas 3D local inspirado en juegos de combate físico y caricaturesco como *Gang Beasts*. El jugador controla un cuy dentro de diferentes arenas y debe utilizar sus habilidades físicas para enfrentarse a los demás jugadores y expulsarlos del escenario.

El objetivo principal es crear una experiencia de combate **divertida, sencilla y caótica**, donde el movimiento y la física tengan un papel importante.

---

## 🎮 Concepto del juego

En **Cuy Kombat**, entre 2 y 4 jugadores compiten dentro de una arena.

Los jugadores pueden:

* Moverse libremente por el escenario.
* Chocar y empujarse físicamente.
* Realizar tackles.
* Cargar el tackle antes de ejecutarlo.
* Lanzar al rival mediante knockback.
* Aturdir al rival con un tackle completamente cargado.
* Utilizar posteriormente objetos del escenario.
* Utilizar diferentes ataques y habilidades.

La principal forma de ganar una ronda será **expulsar a los demás jugadores de la arena**.

### Flujo básico

```text
┌──────────────┐
│ Inicia partida│
└──────┬───────┘
       ↓
┌──────────────┐
│ Aparecen los │
│   jugadores  │
└──────┬───────┘
       ↓
┌──────────────┐
│   Combate    │
│   físico     │
└──────┬───────┘
       ↓
┌──────────────┐
│ Tackle /     │
│ Knockback    │
└──────┬───────┘
       ↓
┌──────────────┐
│ Jugador sale │
│ de la arena  │
└──────┬───────┘
       ↓
┌──────────────┐
│    Victoria  │
└──────────────┘
```

---

# 🎯 Objetivo

El objetivo de cada jugador es permanecer dentro de la arena mientras intenta sacar a sus oponentes.

El jugador que permanezca dentro de la arena será el ganador de la ronda.

---

# 🥊 Mecánicas principales

## Movimiento

El jugador puede desplazarse libremente por la arena mediante controles 3D.

El movimiento busca tener una sensación caricaturesca y física.

---

## 🤜 Contacto físico

Los jugadores pueden chocar entre sí.

El contacto normal produce únicamente un **pequeño empuje**, evitando que los personajes se atraviesen.

El contacto normal:

* No produce knockback fuerte.
* No produce stun.
* No funciona como ataque.
* Permite que los jugadores se bloqueen y se separen ligeramente.

---

## 💨 Tackle

El tackle es una de las principales mecánicas de combate.

El jugador mantiene presionado el botón correspondiente para cargarlo.

```text
0% ───── 50% ───── 100%
                     ↓
                  TACKLE
```

Cuando alcanza el 100%:

* Se ejecuta el tackle.
* Impacta al jugador contrario.
* Produce knockback.
* Puede provocar aturdimiento.
* Inicia su cooldown.

Actualmente el prototipo utiliza el tackle completamente cargado como ataque principal.

---

## 💥 Knockback

El knockback es el desplazamiento fuerte que recibe un jugador al ser golpeado por un tackle.

A diferencia del contacto normal, el knockback:

* Desplaza considerablemente al jugador.
* Mantiene la dirección del impacto.
* Tiene una fuerza mayor que el empuje normal.
* Puede utilizarse para sacar jugadores de la arena.

```text
Jugador atacante
       🐹💨
         │
         ▼
        💥
         │
         ▼
       🐹 ─────────→
          Knockback
```

---

## 😵 Stunned

Cuando un jugador recibe un tackle completamente cargado, puede entrar en estado **STUNNED**.

Mientras está aturdido:

* No puede caminar.
* No puede atacar.
* No puede utilizar tackle.
* No puede realizar acciones.

El estado dura durante el tiempo configurado en `stun_duration`.

Después recupera automáticamente el control.

### Indicador visual

El jugador aturdido utiliza un efecto visual de **parpadeo rojo**, permitiendo identificar rápidamente su estado durante el combate.

---

# 🏟️ Arenas

El juego contará con diferentes escenarios donde se desarrollarán los combates.

Cada arena debe contar con:

* Modelo 3D.
* Colisiones.
* Límites.
* Spawn Points.
* Zona de caída / DeathZone.
* Iluminación.
* Materiales.

La arena es especialmente importante porque el objetivo principal del combate es **expulsar al rival del escenario**.

---

# 👥 Jugadores

El proyecto está diseñado para partidas multijugador local.

### Prototipo inicial

* 2 jugadores.

### Objetivo

* Hasta 4 jugadores locales.

Cada jugador deberá poder diferenciarse visualmente mediante:

* Color.
* Modelo.
* Identificador visual.

---

# 🎥 Cámara

La cámara está diseñada para mantener la acción visible durante el combate.

El sistema deberá:

* Seguir a los jugadores.
* Mantener a los jugadores dentro de la vista.
* Adaptar el zoom según la distancia.
* Prepararse para partidas de hasta 4 jugadores.
* Evitar problemas con la geometría de las arenas.

---

# 🧱 Objetos e interacción

Las arenas podrán contener objetos interactivos.

Ejemplos:

* Cajas.
* Barriles.
* Rocas.
* Obstáculos.
* Trampas.

En futuras versiones estos objetos podrán utilizarse para:

* Agarrar.
* Levantar.
* Lanzar.
* Golpear.
* Romper.

---

# 🔊 Audio

El juego contará con música y efectos de sonido para mejorar la sensación de combate.

Se contemplan sonidos para:

* Menú.
* Combate.
* Tackle.
* Impactos.
* Stun.
* Caída de la arena.
* Victoria.

---

# 🛠️ Tecnología

| Tecnología           | Versión / Uso          |
| -------------------- | ---------------------- |
| Godot                | 4.7.1                  |
| Renderer             | Compatibility / OpenGL |
| Lenguaje             | GDScript               |
| Plataforma principal | PC                     |
| Modo de juego        | Multijugador local     |
| Jugadores            | 2–4                    |

El proyecto no depende de assets externos para el prototipo base.

---

# 📁 Estructura general

La estructura puede organizarse de la siguiente manera:

```text
Cuy-Kombat/
│
├── entities/
│   └── player/
│       ├── player.tscn
│       └── player.gd
│
├── gameplay/
│   ├── game_manager.gd
│   └── spawn_manager.gd
│
├── scenes/
│   ├── arenas/
│   ├── gameplay/
│   └── ui/
│
├── assets/
│   ├── models/
│   ├── audio/
│   └── textures/
│
├── scripts/
│
├── project.godot
└── README.md
```

La estructura puede cambiar conforme avance el desarrollo, pero se busca mantener separados los sistemas de **Player, Gameplay, Arenas, UI, Audio y Objetos**.

---

# 👨‍💻 Equipo de desarrollo

## Kevin — Gameplay y Combate

Responsable de:

* Movimiento y estados del jugador.
* Tackle.
* Carga del tackle.
* Cooldown.
* Knockback.
* Stun.
* Futuras mecánicas de combate.
* Puños.
* Agarre.
* Lanzamiento de jugadores.

---

## Iker — Arenas y Escenarios

Responsable de:

* Importación de modelos 3D.
* Colisiones.
* Spawn Points.
* DeathZone.
* Límites del escenario.
* Iluminación.
* Materiales.
* Optimización de las arenas.

---

## Samuel — GameManager y Flujo de Partida

Responsable de:

* GameManager.
* SpawnManager.
* Administración de jugadores.
* Inicio de partidas.
* Reinicio de partidas.
* Sistema de rondas.
* Detección de ganador.
* Preparación para 2–4 jugadores.

---

## Saiko — Interfaz

Responsable de:

* Menú principal.
* HUD.
* Menú de pausa.
* Cuenta regresiva.
* Barra de carga del tackle.
* Indicadores de juego.
* Pantalla de victoria.

---

## Adrián — Modelos

Responsable de:

* Modelos 3D de los cuyes.
* Materiales.
* Colores.
* Caras.
* Expresiones.
* Preparación de modelos para animaciones.

---

## Christopher Delgado — Objetos e Interacción

Responsable de:

* Objetos interactivos.
* Cajas.
* Barriles.
* Rocas.
* Trampas.
* Obstáculos.
* Sistema base de interacción.
* Preparación para agarre y lanzamiento de objetos.

---

## Christopher Montoya — Audio

Responsable de:

* Música.
* Sonidos de combate.
* Sonido del tackle.
* Impactos.
* Stun.
* Caídas.
* Victoria.
* Organización del sistema de audio.

---

## Dilan — Cámara y Efectos Visuales

Responsable de:

* Cámara principal.
* Seguimiento de jugadores.
* Zoom dinámico.
* Soporte visual para 2–4 jugadores.
* Efectos de impacto.
* Efectos de victoria.
* Partículas y pulido visual.

---

# 🌿 Organización de Git

Cada integrante trabaja en su propia rama para evitar conflictos.

```text
main
│
├── kevin-gameplay
├── iker-arena
├── samuel-game-manager
├── saiko-ui
├── adrian-models
├── delgado-objects
├── montoya-audio
└── dilan-camera
```

Las ramas deben probarse antes de integrarse a `main`.

### Reglas

* No modificar archivos pertenecientes a otro módulo sin coordinación.
* Realizar commits pequeños y descriptivos.
* Probar los cambios antes de hacer Pull Request.
* No subir código roto deliberadamente.
* Mantener una copia funcional en `main`.

---

# 🚧 Estado actual del prototipo

### Implementado

* [x] Proyecto base en Godot 4.7.1.
* [x] Renderer Compatibility / OpenGL.
* [x] Player 3D.
* [x] Movimiento básico.
* [x] Arena inicial.
* [x] Colisiones.
* [x] Jugadores locales.
* [x] Contacto físico entre jugadores.
* [x] Empuje suave por contacto.
* [x] Tackle.
* [x] Carga del tackle.
* [x] Cooldown.
* [x] Knockback.
* [x] STUNNED.
* [x] Indicador visual de stun.

### En desarrollo

* [ ] Ajustar física caricaturesca.
* [ ] Mejorar lanzamiento del tackle.
* [ ] Puños.
* [ ] Agarre de jugadores.
* [ ] Lanzamiento de jugadores.
* [ ] Objetos interactivos.
* [ ] Cámara definitiva.
* [ ] UI definitiva.
* [ ] Sistema completo de rondas.
* [ ] Audio.
* [ ] Modelos definitivos.
* [ ] Efectos visuales.

---

# 🎯 Meta del primer prototipo

La primera versión jugable debe permitir que dos jugadores:

1. Entren a una arena.
2. Se muevan libremente.
3. Se encuentren y choquen.
4. Se empujen ligeramente.
5. Carguen un tackle.
6. Golpeen al oponente.
7. Produzcan knockback.
8. Aturdan al oponente.
9. Intenten expulsarlo de la arena.
10. Determinen un ganador.

El objetivo es tener una **versión pequeña pero completamente jugable**, sobre la cual posteriormente se puedan añadir nuevas mecánicas, personajes, arenas, objetos y contenido.

---

# 🚀 Visión futura

La versión final de Cuy Kombat busca convertirse en un juego de peleas local de estilo caricaturesco donde la física y las interacciones entre jugadores sean el centro de la experiencia.

Se planea incorporar:

* Combate cuerpo a cuerpo.
* Puños.
* Agarre.
* Lanzamiento.
* Objetos utilizables.
* Diferentes arenas.
* Trampas.
* Personajes diferenciados.
* Efectos visuales.
* Sistema de rondas.
* Hasta 4 jugadores locales.

**Cuy Kombat: pelea, empuja y sobrevive. 🐹💥**

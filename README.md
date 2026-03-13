# PuchiAssists: Midnight BiS

## Objetivo del addon
Crear un addon para **World of Warcraft (Midnight)** que ayude al jugador a identificar rápidamente su equipo **BiS (Best in Slot)** por clase, mostrando:

1. Ubicaciones de raids y dungeons de Midnight en el mapa.
2. Tooltip por instancia con el resumen de ítems BiS relevantes.
3. Tooltip por boss (dentro de la instancia) con ítems BiS filtrados por la clase activa del jugador.

---

## Alcance funcional inicial (MVP)

### 1) Detección de clase del jugador
- Usar APIs nativas (`UnitClass("player")`) para obtener clase y token (`WARRIOR`, `MAGE`, etc.).
- Mantener la clase en caché al cargar el addon y refrescar en eventos relevantes (`PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`).

### 2) Marcadores en mapa de raids/dungeons de Midnight
- Mostrar iconos en mapa del mundo para todas las instancias objetivo de la expansión Midnight.
- Asociar cada marcador con metadatos:
  - Nombre de la instancia
  - Tipo (`raid` o `dungeon`)
  - Zona / mapa
  - Lista de bosses incluidos
- Al pasar el ratón sobre el icono: tooltip con resumen de ítems BiS por boss (filtrado por clase del jugador).

### 3) Tooltip por boss dentro de la instancia
- Detectar el boss bajo el cursor (nameplate, tooltip unit, o integración de tooltip según contexto).
- Si el boss existe en la base de datos del addon, anexar sección al tooltip con:
  - Nombre del boss
  - Ítems BiS para la clase actual
  - Slot del ítem y dificultad (si aplica)

---

## Arquitectura propuesta

### Módulos
- `Core`
  - Inicialización, eventos, utilidades comunes.
- `Data`
  - Base de datos de instancias, bosses y tabla BiS por clase/spec.
- `MapPins`
  - Registro y render de iconos en mapa (preferible soporte vía HandyNotes como integración opcional).
- `Tooltip`
  - Inyección de información BiS en tooltips de mapa y de unidades/bosses.
- `ClassResolver`
  - Resolución de clase y spec del jugador.

### Flujo alto nivel
1. Carga del addon.
2. Identificación de clase/spec.
3. Registro de pines en mapa para instancias de Midnight.
4. Interacción del usuario (hover en pin o boss).
5. Construcción dinámica del tooltip con datos BiS filtrados.

---

## Estrategia de datos BiS

### Fuente de datos
- Definir un formato interno para datos BiS por:
  - Instancia -> Boss -> Clase -> Spec -> Lista de ítems.
- Empezar con dataset manual validado (MVP) y luego contemplar pipeline semi-automático de actualización.

### Estructura sugerida
```lua
BIS_DATA = {
  [instanceId] = {
    name = "Nombre Instancia",
    type = "raid",
    mapId = 0,
    bosses = {
      [bossId] = {
        name = "Boss",
        loot = {
          MAGE = {
            ARCANE = {
              { itemId = 0, slot = "TRINKET", difficulty = "MYTHIC" }
            }
          }
        }
      }
    }
  }
}
```

---

## Fases de desarrollo

### Fase 0 — Definición y preparación
- [ ] Confirmar listado final de raids y dungeons de Midnight.
- [ ] Definir clases/specs objetivo para primera entrega.
- [x] Crear estructura base del addon (`.toc`, `Core`, `Data`, `MapPins`, `Tooltip`).

### Fase 1 — Núcleo técnico
- [x] Inicialización del addon y registro de eventos.
- [x] Resolver clase del jugador de forma robusta.
- [ ] Logging/debug básico activable por configuración.

### Fase 2 — Datos BiS
- [ ] Diseñar esquema final de datos.
- [x] Cargar dataset inicial (al menos 1 raid + 1 dungeon para pruebas).
- [ ] Validaciones de consistencia (bosses, item IDs, clases/specs).

### Fase 3 — Mapa de instancias
- [x] Dibujar iconos en mapa de mundo.
- [x] Tooltip de pin con resumen BiS para clase activa.
- [ ] Ajustes de rendimiento (evitar reconstrucción excesiva de tooltip).

### Fase 4 — Tooltip de boss en instancia
- [x] Hook del tooltip de unidad/boss.
- [x] Match de boss por nombre/ID.
- [x] Mostrar loot BiS filtrado por clase/spec.

### Fase 5 — Configuración y UX
- [ ] Opciones básicas (`/puchi`): activar/desactivar pines y tooltips.
- [ ] Formato de tooltip legible (slots, dificultad, orden por prioridad).
- [ ] Localización inicial ES/EN.

### Fase 6 — QA y publicación
- [ ] Pruebas en mundo abierto, entrada de instancia, combate y cambios de spec.
- [ ] Revisión de errores Lua y compatibilidad con otros addons comunes.
- [ ] Empaquetado y versionado inicial.

---

## Riesgos y decisiones importantes
- **Disponibilidad de datos Midnight:** puede requerir actualización frecuente en temporada.
- **Identificación fiable de bosses:** algunos contextos de tooltip no exponen toda la metadata.
- **Escalabilidad del dataset:** separar datos de lógica para facilitar mantenimiento.
- **Compatibilidad con addons de mapa/tooltips:** validar conflictos con HandyNotes, DBM, etc.

---

## Criterios de éxito (MVP)
- El addon detecta correctamente la clase del jugador.
- Se visualizan todas las instancias de Midnight en mapa con icono.
- Hover en icono muestra ítems BiS por boss para la clase actual.
- Hover en boss dentro de instancia muestra ítems BiS correspondientes.
- Sin errores Lua críticos en flujo normal de juego.

---

## Próximos pasos inmediatos
1. Implementar hook inicial de tooltip para bosses.
2. Añadir configuración básica (`/puchi`) para activar/desactivar módulos.
3. Validar IDs de mapa y bosses de Midnight con datos finales de juego.
4. Reemplazar dataset de ejemplo por datos reales de temporada.

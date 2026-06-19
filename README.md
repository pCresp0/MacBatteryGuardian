# MacBatteryGuardian

<p align="center">
  <strong>Monitor de batería y sistema para macOS — nativo, ligero y siempre en la barra de menú.</strong><br>
  <sub>Apple Silicon · Swift 6 · SwiftUI · Sin telemetría · 100 % local</sub><br>
  <sub>Desarrollado por <a href="https://github.com/pCresp0">Pablo Crespo Bellido</a></sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS%2014%2B%20(Sonoma)-required-000000?style=flat-square&logo=apple&logoColor=white" alt="macOS 14+ required"/>
  <img src="https://img.shields.io/badge/Apple%20Silicon-M1%20→%20M5-0071e3?style=flat-square&logo=apple&logoColor=white" alt="Apple Silicon"/>
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 6"/>
  <img src="https://img.shields.io/badge/SwiftUI-✓-007AFF?style=flat-square" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT License"/>
</p>

<p align="center">
  <img src="docs/screenshots/popover.png" alt="Popover de MacBatteryGuardian en la barra de menú" width="420"/>
</p>

<p align="center">
  <em>Vista rápida desde la barra de menú: batería, CPU, RAM, temperatura y acceso al análisis completo.</em>
</p>

---

## Índice

- [Qué es](#qué-es)
- [Requisitos del sistema](#requisitos-del-sistema)
- [Capturas de pantalla](#capturas-de-pantalla)
- [Cómo usar la app](#cómo-usar-la-app)
- [Descargar e instalar](#descargar-e-instalar)
- [Compilar desde código fuente](#compilar-desde-código-fuente)
- [Características](#características)
- [Arquitectura](#arquitectura)
- [Privacidad](#privacidad)
- [Limitaciones conocidas](#limitaciones-conocidas)
- [Licencia y autor](#licencia-y-autor)

---

## Qué es

**MacBatteryGuardian** es una utilidad nativa para macOS que se instala en la **barra de menú superior** (junto al icono de Wi‑Fi, batería del sistema, etc.) y monitoriza en segundo plano:

- Nivel y salud de la batería
- Consumo energético estimado (`%/h`)
- Uso de CPU y memoria RAM
- Estado térmico del sistema
- Procesos con mayor impacto energético

No es una app de Dock ni una web embebida: es **100 % nativa**, escrita en **Swift 6 + SwiftUI**, sin cuentas, sin telemetría y sin conexiones de red. Todos los datos se guardan **solo en tu Mac**.

---

## Requisitos del sistema

> **Necesitas macOS 14.0 (Sonoma) o superior** para ejecutar MacBatteryGuardian.

| Requisito | Detalle |
|-----------|---------|
| **macOS** | **14.0 Sonoma** o superior (14.x, 15.x Sequoia, 26.x…) |
| **Procesador** | **Apple Silicon** (M1, M2, M3, M4, M5…) |
| **RAM** | 8 GB mínimo recomendado |
| **Espacio** | ~15 MB para la app + historial local |

> ⚠️ **No compatible con Mac Intel (x86_64)** en esta versión.  
> ⚠️ Para **compilar** desde código fuente necesitas además **Xcode 16+** y **XcodeGen**.

---

## Capturas de pantalla

### Barra de menú — vista rápida (Popover)

Al pulsar el icono en la barra de menú se abre un **panel compacto** con lo esencial:

- Porcentaje de batería y tiempo estimado de agotamiento
- Consumo medio (`%/h`)
- CPU y RAM con indicador de presión
- Temperatura estimada del sistema
- Botón para activar **Modo Bajo Consumo**
- Enlace **"Ver análisis completo →"** que abre la ventana principal

<p align="center">
  <img src="docs/screenshots/popover.png" alt="Popover" width="400"/>
</p>

---

### Ventana principal — pestaña General

Resumen ejecutivo con **tarjetas clicables**. Pulsando en cualquier tarjeta (Batería, CPU, RAM…) saltas directamente a esa pestaña con el detalle completo.

<p align="center">
  <img src="docs/screenshots/general.png" alt="Pestaña General" width="720"/>
</p>

---

### Pestaña Batería

Estado actual, gráficas de nivel y consumo en el tiempo, medias por ventana temporal (15 min, 30 min, 1 h, 3 h) y datos de salud de la batería (ciclos, capacidad, mAh).

<p align="center">
  <img src="docs/screenshots/battery.png" alt="Pestaña Batería" width="720"/>
</p>

---

### Pestaña CPU

Uso total, de usuario y del sistema. Gráfica temporal, desglose de núcleos **P-cores / E-cores** en Apple Silicon, estado térmico y procesos ordenados por impacto energético.

<p align="center">
  <img src="docs/screenshots/cpu.png" alt="Pestaña CPU" width="720"/>
</p>

---

### Pestaña Memoria RAM

Uso en GB, presión de memoria, evolución temporal y **desglose segmentado** al estilo Almacenamiento de macOS (wired, comprimida, apps activas, caché recuperable y libre).

<p align="center">
  <img src="docs/screenshots/memory.png" alt="Pestaña Memoria RAM" width="720"/>
</p>

> También disponibles: **Histórico** (gráficas de días/semanas), **Salud** (índice 0–100 con recomendaciones) y **Ajustes** (configuración completa).

---

## Cómo usar la app

### 1. Localizar el icono

Tras instalar o ejecutar la app, **no aparece en el Dock**. Busca el icono de **MacBatteryGuardian** en la **barra de menú superior** de macOS (parte derecha, junto a los iconos del sistema).

El icono muestra:
- El **nivel de batería** (si lo activas en Ajustes)
- El **consumo estimado** en `%/h` (si lo activas en Ajustes)

### 2. Vista rápida — pulsar el icono

**Clic en el icono** → se abre el **popover** con el resumen instantáneo:

| Elemento | Qué hace |
|----------|----------|
| **Batería (círculo)** | Nivel actual, estado de carga/descarga, hora estimada de agotamiento |
| **CPU / RAM** | Uso actual; **clic** → abre la ventana en esa pestaña |
| **Temperatura** | Estimación basada en estado térmico del sistema |
| **Procesos** | Apps que más consumen en este momento |
| **Activar modo bajo consumo** | Activa el Low Power Mode de macOS |
| **Ver análisis completo →** | Abre la ventana principal |

### 3. Ventana principal — análisis detallado

Desde el popover o directamente, abre la **ventana completa** con 7 pestañas:

| Pestaña | Para qué sirve |
|---------|----------------|
| **General** | Dashboard con tarjetas navegables |
| **Batería** | Detalle de carga, autonomía, tendencias y salud |
| **CPU** | Uso, núcleos Apple Silicon, térmico, procesos |
| **Memoria RAM** | Presión, gráfica temporal y desglose de memoria |
| **Histórico** | Evolución en el tiempo (hoy / 7 días / 30 días) |
| **Salud** | Índice de salud del Mac (0–100) y recomendaciones |
| **Ajustes** | Configuración de la app |

**Tip:** en la pestaña General, pulsa **"Abrir ›"** o la propia tarjeta para ir al detalle de esa métrica.

### 4. Configurar la app — pestaña Ajustes

En **Ajustes** puedes personalizar:

- **Inicio automático** al arrancar el Mac
- Qué mostrar en la **barra de menú** (% batería, consumo %/h)
- **Intervalo de monitorización** (1–15 min)
- **Notificaciones** de consumo anómalo (con cooldown)
- **Modo Bajo Consumo automático** según consumo crítico
- **Retención del historial** (7–90 días)
- Restablecer configuración por defecto

### 5. Primer uso — permisos

La primera vez que uses ciertas funciones, macOS puede pedirte:

| Permiso | Motivo |
|---------|--------|
| **Notificaciones** | Alertas de consumo elevado |
| **Helper del sistema** | Activar/desactivar Modo Bajo Consumo (`pmset`) |
| **Login Item** | Si activas "Iniciar al arrancar" |

### 6. Cerrar la ventana sin cerrar la app

Al cerrar la ventana principal (✕), la app **sigue en la barra de menú** monitorizando en segundo plano. Para salir del todo, usa **Salir** desde el menú contextual del icono o `⌘Q` con la ventana enfocada.

---

## Descargar e instalar

### Opción A — Compilar tú mismo (recomendado por ahora)

Actualmente la forma de obtener la app es **compilar desde el código fuente**. Sigue la guía de [Compilar desde código fuente](#compilar-desde-código-fuente) más abajo.

Tras compilar, arrastra `MacBatteryGuardian.app` a **Aplicaciones**:

```bash
# Ruta típica tras compilar en Debug:
cp -R ~/Library/Developer/Xcode/DerivedData/MacBatteryGuardian-*/Build/Products/Debug/MacBatteryGuardian.app /Applications/
```

Luego ábrela desde **Aplicaciones** o con Spotlight (`⌘Espacio` → "MacBatteryGuardian").

> La primera ejecución desde una app descargada/compilada puede requerir clic derecho → **Abrir** si macOS la bloquea por no estar notarizada.

### Opción B — Releases (próximamente)

Cuando publique releases en GitHub, podrás descargar un `.app` o `.dmg` desde:

👉 **[github.com/pCresp0/MacBatteryGuardian/releases](https://github.com/pCresp0/MacBatteryGuardian/releases)**

---

## Compilar desde código fuente

### Requisitos de desarrollo

- macOS **14.0+**
- **Xcode 16** o superior ([App Store](https://apps.apple.com/app/xcode/id497799835))
- **XcodeGen**: `brew install xcodegen`
- Cuenta de desarrollador Apple (gratuita vale para uso personal)

### Pasos

```bash
# 1. Clonar
git clone https://github.com/pCresp0/MacBatteryGuardian.git
cd MacBatteryGuardian

# 2. Generar proyecto Xcode
xcodegen generate

# 3. Abrir en Xcode
open MacBatteryGuardian.xcodeproj
```

En Xcode → **Signing & Capabilities** de ambos targets (`MacBatteryGuardian` y `MacBatteryGuardianHelper`):

1. Selecciona tu **Team**.
2. Activa **Automatically manage signing**.

Compilar y ejecutar: **`⌘R`**

O desde terminal:

```bash
xcodebuild -scheme MacBatteryGuardian -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/MacBatteryGuardian-*/Build/Products/Debug/MacBatteryGuardian.app
```

---

## Características

### Barra de menú
- Icono dinámico con batería y/o consumo `%/h`
- Popover interactivo con acceso a cada métrica
- Activación de Modo Bajo Consumo en un clic

### Monitorización inteligente
- Ciclo periódico configurable (por defecto cada 5 min)
- Consumo `%/h` con suavizado al arrancar (evita lecturas falsas)
- Índice de salud 0–100 con recomendaciones accionables
- Historial local persistido en disco
- Notificaciones nativas con cooldown
- Pausa automática cuando el Mac entra en reposo

### Interfaz
- Diseño **Liquid Glass** en macOS 26+ con fallback en macOS 14+
- Ventana con altura adaptativa por pestaña
- Gráficas temporales con **Swift Charts**
- Desglose de RAM estilo Almacenamiento de macOS

---

## Stack tecnológico

| Capa | Tecnología |
|------|------------|
| Lenguaje | **Swift 6** (strict concurrency) |
| UI | **SwiftUI** + **Swift Charts** |
| Patrón | **MVVM** + servicios `actor` |
| APIs del sistema | **IOKit**, **sysctl**, **proc_info**, **ProcessInfo** |
| Energía / batería | **IOPS**, **IORegistry** |
| Privilegios | **SMJobBless** + helper XPC |
| Proyecto | **XcodeGen** |

---

## Arquitectura

```
Barra de menú (PopoverView)
        │
        ▼
Ventana principal (7 pestañas SwiftUI)
        │
        ▼
ViewModels (@MainActor)
        │
        ▼
MonitoringManager ──► Services (IOKit, sysctl, proc_info…)
        │                    │
        │                    └── MacBatteryGuardianHelper (pmset)
        ▼
Persistencia local (JSON en Application Support)
```

---

## Privacidad

| | |
|---|---|
| Telemetría | ❌ Ninguna |
| Red | ❌ Sin conexiones |
| Cuentas | ❌ No requeridas |
| Datos | ✅ Solo en `~/Library/Application Support/MacBatteryGuardian/` |

---

## Limitaciones conocidas

| Funcionalidad | Estado |
|---------------|--------|
| Temperatura CPU (°C exactos) | ⚠️ Apple no la expone en Apple Silicon; se estima vía `thermalState` |
| Ventiladores (RPM) | ❌ No disponible vía APIs públicas |
| Impacto por proceso | ⚠️ Estimado (CPU + memoria + threads) |
| Low Power Mode | ⚠️ Requiere helper firmado + autorización del usuario |

---

## Roadmap

- [x] Capturas de pantalla en el README
- [ ] Release `.dmg` en GitHub Releases
- [ ] Tests unitarios
- [ ] Localización EN
- [ ] Soporte Intel si hay demanda

---

## Licencia y autor

**MIT License** — ver [LICENSE](LICENSE).

**Pablo Crespo Bellido**

<p align="center">
  <a href="https://github.com/pCresp0">GitHub — más proyectos</a>
  &nbsp;·&nbsp;
  <a href="https://www.linkedin.com/in/pablocrespobellido">LinkedIn</a>
</p>

<p align="center">
  <sub>Si te resulta útil, considera darle una ⭐ al repositorio.</sub>
</p>

# MacBatteryGuardian

<p align="center">
  <strong>Monitor de batería y sistema para macOS — nativo, ligero y en la barra de menú.</strong><br>
  <sub>Apple Silicon · Swift 6 · SwiftUI · Sin telemetría · 100 % local</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-000000?style=flat-square&logo=apple&logoColor=white" alt="macOS 14+"/>
  <img src="https://img.shields.io/badge/arch-Apple%20Silicon-0071e3?style=flat-square&logo=apple&logoColor=white" alt="Apple Silicon"/>
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 6"/>
  <img src="https://img.shields.io/badge/SwiftUI-✓-007AFF?style=flat-square" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT License"/>
</p>

---

## Qué es

**MacBatteryGuardian** es una utilidad nativa para macOS que vive en la **barra de menú** y te da visibilidad real sobre batería, consumo energético, CPU, memoria RAM y salud general del sistema — sin dashboards web, sin cuentas y sin enviar datos a ningún servidor.

Diseñada para usuarios de portátiles Apple Silicon que quieren entender *por qué* se les va la batería y *qué* pueden hacer al respecto.

---

## Características principales

### Barra de menú
- Icono dinámico con nivel de batería y consumo estimado (`%/h`)
- Popover compacto con batería, CPU, RAM, temperatura estimada y procesos más activos
- Acceso directo a cada pestaña de la ventana principal

### Ventana principal (7 pestañas)
| Pestaña | Contenido |
|---------|-----------|
| **General** | Resumen ejecutivo con tarjetas navegables |
| **Batería** | Nivel, ciclos, estado de carga, tiempo estimado |
| **CPU** | Uso por núcleos P/E, gráfica temporal en vivo |
| **Memoria RAM** | Presión, evolución y desglose estilo Almacenamiento de macOS |
| **Histórico** | Gráficas de batería, consumo y CPU (hoy / 7 días / 30 días) |
| **Salud** | Índice 0–100 con factores desglosados y recomendaciones |
| **Ajustes** | Intervalos, notificaciones, LPM automático, retención de historial |

### Inteligencia del sistema
- **Motor de decisiones** con alertas de consumo anómalo (suavizado al arrancar, cap realista)
- **Índice de salud** compuesto: batería, térmico, CPU, memoria, consumo y uptime
- **Modo Bajo Consumo automático** vía helper privilegiado (`pmset`)
- **Historial local** persistido en disco con estadísticas por período
- **Notificaciones nativas** con cooldown configurable

### Experiencia visual
- Interfaz **Liquid Glass** en macOS 26+ con fallback translúcido en macOS 14+
- Ventana con **altura adaptativa** por pestaña
- Gráficas temporales con **Swift Charts**
- Barra de título translúcida legible y arrastrable

---

## Stack tecnológico

| Capa | Tecnología |
|------|------------|
| Lenguaje | **Swift 6** (strict concurrency) |
| UI | **SwiftUI** + **Swift Charts** |
| Patrón | **MVVM** + capa de servicios con `actor` |
| APIs del sistema | **IOKit**, **sysctl**, **proc_info**, **ProcessInfo**, **UserNotifications** |
| Energía / batería | **IOPS** (Power Sources), **IORegistry** |
| Privilegios | **SMJobBless** + helper XPC (`MacBatteryGuardianHelper`) |
| Proyecto | **XcodeGen** (`project.yml`) |
| Calidad | **SwiftLint** |
| Destino | **macOS 14+**, **arm64** (Apple Silicon) |

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                     Barra de menú (NSStatusItem)            │
│              PopoverView  ←→  StatusItemController          │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                    MainWindowView (SwiftUI)                 │
│   General · Batería · CPU · RAM · Histórico · Salud · Ajustes│
└──────────────────────────────┬──────────────────────────────┘
                               │ @EnvironmentObject
┌──────────────────────────────▼──────────────────────────────┐
│              ViewModelStore + ViewModels (@MainActor)       │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                   MonitoringManager                         │
│  Orquesta ciclo periódico · sleep/wake · publica snapshots  │
└──────┬──────────┬──────────┬──────────┬──────────┬─────────┘
       │          │          │          │          │
   Services    Managers   Repositories  Persistence  Notifications
   (actors)    (lógica)   (settings,    (JSON local) (UNUserNotification)
                          history)
       │
   IOKit · sysctl · proc_info · ThermalService · PowerManagementService
       │
   MacBatteryGuardianHelper (XPC) → pmset lowpowermode
```

### Principios de diseño

- **Separación estricta**: `Models` (datos puros) → `Services` (I/O del sistema) → `Managers` (reglas de negocio) → `ViewModels` (presentación) → `Views` (SwiftUI).
- **Concurrencia segura**: servicios como `actor`, ViewModels en `@MainActor`, modelos `Sendable`.
- **Sin red**: cero telemetría; todo en `~/Library/Application Support/MacBatteryGuardian/`.
- **Eficiencia**: escaneo completo de procesos cada N ciclos; monitorización pausada en sleep del sistema.

---

## Estructura del repositorio

```
MacBatteryGuardian/
├── MacBatteryGuardian/
│   ├── App/              # AppDelegate, ciclo de vida, ventana NSWindow
│   ├── Models/           # BatterySnapshot, SystemSnapshot, HealthScore…
│   ├── Services/         # BatteryService, SystemMetricsService, Persistence…
│   ├── Managers/         # MonitoringManager, DecisionEngine, HealthScore…
│   ├── Repositories/     # SettingsRepository, HistoryRepository
│   ├── ViewModels/       # Un ViewModel por pestaña + Popover + MenuBar
│   ├── Views/            # SwiftUI: Main, Tabs, MenuBar, Components
│   ├── Utilities/        # IOKitBridge, SysctlBridge, ProcInfoBridge…
│   └── Extensions/       # LiquidGlassStyle, formateo, colores semánticos
├── MacBatteryGuardianHelper/   # Helper XPC para Low Power Mode
├── project.yml                 # Definición XcodeGen
├── .swiftlint.yml
└── README.md
```

---

## Requisitos

- **macOS 14.0** (Sonoma) o superior
- **Xcode 16** o superior
- **Apple Silicon** (M1 / M2 / M3 / M4 / M5)
- **XcodeGen** (generación del proyecto)

---

## Instalación y compilación

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU_USUARIO/MacBatteryGuardian.git
cd MacBatteryGuardian
```

### 2. Instalar XcodeGen

```bash
brew install xcodegen
```

### 3. Generar el proyecto Xcode

```bash
xcodegen generate
open MacBatteryGuardian.xcodeproj
```

### 4. Configurar firma de código

En **Signing & Capabilities** de ambos targets (`MacBatteryGuardian` y `MacBatteryGuardianHelper`):

1. Selecciona tu **Team** de desarrollo.
2. Activa **Automatically manage signing**.
3. En el helper, activa **Hardened Runtime**.

> El helper XPC requiere firma válida para activar el Modo Bajo Consumo. En desarrollo, macOS puede solicitar autorización al usuario la primera vez.

### 5. Compilar y ejecutar

`⌘R` en Xcode, o desde terminal:

```bash
xcodebuild -scheme MacBatteryGuardian -configuration Debug build
```

La app **no aparece en el Dock** (`LSUIElement`). Búscala en la barra de menú superior.

---

## Cómo funciona la monitorización

1. `MonitoringManager` ejecuta un ciclo periódico (por defecto cada **5 minutos**, configurable).
2. En cada ciclo se capturan snapshots de batería, CPU, memoria, procesos y estado térmico.
3. `DecisionEngine` calcula consumo `%/h` con ventana mínima de 5 min y tope de 100 %/h para evitar lecturas falsas al arrancar.
4. `HealthScoreManager` genera un índice 0–100 y recomendaciones accionables.
5. `PersistenceService` guarda registros históricos en disco según la retención configurada.
6. `AlertManager` envía notificaciones nativas cuando se superan umbrales, respetando cooldown.

---

## Privacidad

| | |
|---|---|
| Telemetría | ❌ Ninguna |
| Conexiones de red | ❌ Ninguna |
| Cuentas / login | ❌ No requerido |
| Almacenamiento | ✅ Solo local en Application Support |
| Analytics de terceros | ❌ Ninguno |

---

## Limitaciones conocidas (APIs de Apple)

| Funcionalidad | Estado |
|---------------|--------|
| Temperatura del procesador (°C) | ⚠️ No expuesta en Apple Silicon. Se usa `ProcessInfo.thermalState` como proxy |
| Velocidad de ventiladores | ❌ No disponible vía APIs públicas |
| Impacto energético por proceso | ⚠️ Estimado vía CPU time + memoria + threads (`proc_pidinfo`) |
| Low Power Mode (escritura) | ⚠️ Requiere helper firmado + autorización del usuario |

---

## Distribución (notarización)

Para distribución fuera del Mac App Store:

1. Firma con **Developer ID Application**
2. Notariza con `xcrun notarytool`
3. Grapa el ticket con `xcrun stapler`
4. El helper usa **SMJobBless** — el usuario verá el diálogo estándar de autorización del sistema

Documentación: [Updating Helper Executables](https://developer.apple.com/documentation/servicemanagement/updating_helper_executables_from_earlier_versions_of_mac_os)

---

## Roadmap

- [ ] Capturas de pantalla en el README
- [ ] Tests unitarios para `DecisionEngine` y `HealthScoreManager`
- [ ] Sparkline exportable / widget de Centro de control
- [ ] Soporte Intel (x86_64) si hay demanda
- [ ] Localización EN

---

## Licencia

MIT — ver [LICENSE](LICENSE) para más detalles.

---

## Autor

Desarrollado con Swift nativo para macOS.

<p align="center">
  <sub>Si te resulta útil, considera darle una ⭐ al repositorio.</sub>
</p>

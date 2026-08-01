# BodyPress

[![CI — Download Build APK](https://github.com/the-governor-hq/bodyPress-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/the-governor-hq/bodyPress-flutter/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.9.2%2B-blue?logo=flutter)
![Version](https://img.shields.io/badge/version-1.0.24-informational)
![License](https://img.shields.io/badge/license-MIT-green)

> Your body writes a journal every day — BodyPress reads it.

A cross-platform Flutter app that collects physiological, environmental, and behavioural signals from device sensors, then synthesises them into a daily first-person narrative: a blog written _by_ your body, _for_ you.

---

## Screenshots

<table>
  <tr>
    <td><img width="200" src="https://github.com/user-attachments/assets/400c148d-80cc-4614-b224-e1b11ff16a29" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/89eb3103-79c0-4b05-8a16-2f077ef2c46b" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/6afd6d98-23a1-4cd2-9c2d-cd3e9c2d3841" /></td>
     <td><img width="200" alt="image" src="https://github.com/user-attachments/assets/39a1ab62-2769-49e0-a195-0bc4d4386df8" /></td>
    <td><img width="200" alt="Journal" src="https://github.com/user-attachments/assets/83c0a31e-1cfe-48e3-9478-9fcbf6c12dcc" /></td>
    <td><img width="200" alt="Capture" src="https://github.com/user-attachments/assets/4a6de629-54b0-40f4-af2a-b8650b305fd2" /></td>
    <td><img width="200" alt="Patterns" src="https://github.com/user-attachments/assets/7b58bd67-4dc1-4cd4-88a7-6a177d931bb1" /></td>
    <td><img width="200" alt="Detail" src="https://github.com/user-attachments/assets/1c07cc5f-6dfd-4f66-9294-19f1bf20e8d8" /></td>
  </tr>
</table>

<details>
<summary>More screenshots</summary>

<table>
  <tr>
    <td><img width="200" src="https://github.com/user-attachments/assets/ecee3855-2836-4e5b-a559-c9edac9166a7" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/4b7bb0b1-2f92-40b1-a170-49a67ac802c8" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/8834a150-3d16-4fcc-bb7f-a184a9b91c48" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/b76caba3-f7ee-449f-ab20-9795bbcff717" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/ce5c09cf-0021-4f67-bb28-31bc0b6fcdfe" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/4f7cb624-64e7-4728-a1d4-ea87a914cf15" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/3218e319-f647-4b30-8785-f6bf38256e6e" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/57cd41ac-3d52-43cf-9cac-da500b8caa3e" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/f44194ea-0f20-4805-8744-a85c1f80f844" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/14dd1b37-20f3-412b-aa8a-8521633e7488" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/d009636a-4713-48a2-b62a-81ec479cc320" /></td>
    <td><img width="200" src="https://github.com/user-attachments/assets/86b6c9a9-30af-4715-a62d-9a62e11e7d16" /></td>
  </tr>
</table>

</details>

---

## Why BodyPress?

Most health apps show dashboards of numbers. BodyPress takes a different approach: it presents your biometrics as a _narrative_. Story-framing surfaces correlations you'd otherwise miss — poor sleep preceding an elevated resting heart rate, high AQI days correlating with fewer steps — and reading about yourself is more engaging than staring at charts.

Under the hood the app treats the human body as an observable system: collect objective signals throughout the day, feed them to an LLM, and get back a warm, first-person journal entry that reads as though your body is writing to you.

---

## Features

| Feature                  | Description                                                                                                                                                                                                                                                                                                                                                                                           |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **AI Journal**           | Daily narrative generated from real sensor data — headline, mood, summary, full body text. Written in first-person ("your body speaking to you").                                                                                                                                                                                                                                                     |
| **Smart Refresh**        | Persisted entries return instantly. AI runs only when new unprocessed captures exist. No redundant sensor reads or API calls.                                                                                                                                                                                                                                                                         |
| **Background Captures**  | WorkManager-based periodic data collection with quiet-hour and battery-awareness support.                                                                                                                                                                                                                                                                                                             |
| **Manual Capture**       | On-demand snapshot with toggleable data sources (health, environment, location, calendar, BLE HR device).                                                                                                                                                                                                                                                                                             |
| **BLE Heart Rate**       | Real-time streaming from any Bluetooth Low Energy Heart Rate Profile (0x180D) device — Polar H10, Wahoo TICKR, Garmin straps, etc. Live ECG-style waveform in the Capture screen. **Continuous session recording** accumulates timestamped BPM samples and raw RR intervals for the full connection duration; RMSSD, SDNN, and mean-RR are computed at capture time and stored alongside the session. |
| **HRV & Autonomic Tone** | RMSSD / SDNN computed from BLE RR intervals at every capture. A plain-language stress hint and a BPM arc narrative are generated and passed to the AI so it can interpret cardiac state as a story, not just a number.                                                                                                                                                                                |
| **Cardiovascular Depth** | Resting heart rate and HRV (SDNN) also read from HealthKit / Health Connect alongside average HR. All three are included in daily snapshots and AI prompts.                                                                                                                                                                                                                                           |
| **Patterns & Trends**    | AI-derived insights aggregated from capture history — energy distribution, recurring themes, notable signals, recent moments timeline.                                                                                                                                                                                                                                                                |
| **Nutrition Scanner**    | Scan any food barcode from the Capture screen. Open Food Facts returns Nutri-Score, NOVA group, and full macros. AI prompt includes the food data and generates a nutrition Context analysis correlating nutrition to HRV/energy patterns.                                                                                                                                                            |
| **User Annotations**     | Free-text notes and mood emojis per day, persisted in SQLite alongside the AI-generated content.                                                                                                                                                                                                                                                                                                      |
| **Onboarding**           | Step-by-step permission flow with per-permission explanations and privacy notes. Every step is skippable.                                                                                                                                                                                                                                                                                             |
| **BCI Signal Analysis**  | Four visualisation modes on the Live Signal screen: time-domain waveforms, real-time FFT spectral analysis (spectrum / waterfall / EEG bands), neural-state decoding demo (5-state classifier with confidence ring), and signal quality monitoring demo (SNR, impedance, artifact detection). Switchable via a popup menu — works with real BLE hardware and demo mode.                               |
| **Dark & Light Themes**  | Material 3 theming with system-mode detection.                                                                                                                                                                                                                                                                                                                                                        |

---

## Data Sources

| Domain             | Sensor / API                                                 | What's read                                                                                                                                                       |
| ------------------ | ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Movement**       | Health Connect / HealthKit                                   | Steps, distance, calories, workouts                                                                                                                               |
| **Cardiovascular** | Optical HR sensor (OS health store)                          | Average HR, resting HR, HRV (SDNN)                                                                                                                                |
| **Cardiovascular** | BLE HR strap (direct, 0x180D)                                | Continuous BPM session + RR intervals → RMSSD / SDNN / mean-RR; full `BleHrSession` stored per capture                                                            |
| **Signal sources** | BLE plugin system (ADS1299, PiEEG-XR, IronBCI, Octopus16, …) | Multi-channel streaming from community hardware — 4 view modes (waveform, spectral, decoding, monitoring). See [CONTRIBUTING_SOURCES.md](CONTRIBUTING_SOURCES.md) |
| **Sleep**          | Device sleep tracking                                        | Duration, phases                                                                                                                                                  |
| **Environment**    | GPS → ambient-scan API                                       | Temperature, humidity, AQI, UV, pressure, wind, conditions                                                                                                        |
| **Schedule**       | Device calendar (CalDAV)                                     | Today's events                                                                                                                                                    |
| **Location**       | GPS (Geolocator)                                             | Coordinates — ephemeral, never stored                                                                                                                             |
| **Nutrition**      | Barcode → Open Food Facts API v2                             | Product name, Nutri-Score, NOVA group, macros per 100 g / per serving                                                                                             |

> **Privacy:** GPS is read once to fetch environmental data, then discarded. No location history is recorded or transmitted. Health data is read-only — the app never writes to HealthKit or Health Connect.

---

## Tech Stack

| Concern          | Library                               | Role                                                                    |
| ---------------- | ------------------------------------- | ----------------------------------------------------------------------- |
| State management | `flutter_riverpod` ^2.6.1             | DI + reactive state                                                     |
| Routing          | `go_router` ^14.6.2                   | Declarative navigation (3-tab shell + standalone routes)                |
| Health           | `health` ^11.1.0                      | Cross-platform HealthKit / Health Connect (HR, resting HR, HRV, steps…) |
| BLE              | `flutter_blue_plus` ^1.35.3           | BLE scan / connect / notify — Heart Rate Profile 0x180D                 |
| Location         | `geolocator` ^13.0.2                  | GPS coordinates                                                         |
| Calendar         | `device_calendar` ^4.3.2              | CalDAV read                                                             |
| HTTP             | `http` ^1.2.2                         | Ambient-scan & AI API calls                                             |
| Barcode scanner  | `mobile_scanner` ^7.0.1               | Camera-based barcode reading (EAN-13, UPC-A, etc.)                      |
| Nutrition API    | Open Food Facts API v2                | Product lookup by barcode — no API key needed                           |
| Persistence      | `sqflite` ^2.3.3 + `path`             | Local SQLite (entries, captures, settings) — schema v11                 |
| Background       | `workmanager` ^0.9.0                  | Periodic background captures                                            |
| Notifications    | `flutter_local_notifications` ^17.0.0 | Daily reminders                                                         |
| Sharing          | `share_plus` ^10.1.0                  | Share journal entries                                                   |
| Typography       | `google_fonts` ^6.2.1                 | Inter (body) / Playfair Display (headlines)                             |
| Formatting       | `intl` ^0.19.0                        | Date/number formatting                                                  |
| Config           | `flutter_dotenv` ^6.0.0               | `.env` file support                                                     |

---

## Getting Started

### Prerequisites

- Flutter SDK **≥ 3.9.2**
- **iOS:** Xcode 14+, deployment target iOS 14+
- **Android:** SDK 21+ (Android 5.0), Health Connect app for health data on Android 13+

### Install & run

```bash
flutter pub get
flutter run

# Or use the helper scripts
.\dev.ps1           # Windows (PowerShell)
./dev.sh            # macOS / Linux
```

### Environment

Copy `.env.example` to `.env` and fill in your API key:

```
AI_API_KEY=your_key_here
```

### Platform configuration

<details>
<summary><strong>iOS</strong></summary>

`Info.plist` keys are pre-configured:

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`
- `NSCalendarsUsageDescription`
- `NSMotionUsageDescription`
- `NSBluetoothAlwaysUsageDescription` ← BLE heart rate devices
- `NSBluetoothPeripheralUsageDescription`

Enable HealthKit capability in Xcode: **Runner** target → **Signing & Capabilities** → **+ HealthKit**.

</details>

<details>
<summary><strong>Android</strong></summary>

`AndroidManifest.xml` includes permissions for location, Health Connect (including `READ_HEART_RATE_VARIABILITY`), activity recognition, calendar, and BLE:

- `BLUETOOTH` / `BLUETOOTH_ADMIN` (API ≤ 30 legacy)
- `BLUETOOTH_SCAN` (`neverForLocation`) + `BLUETOOTH_CONNECT` (API 31+)
- `android.hardware.bluetooth_le` feature declaration (`required=false` — app installs on non-BLE devices)
- `CAMERA` permission + `android.hardware.camera` / `android.hardware.camera.autofocus` features (`required=false`) — barcode scanner

The Health Connect app is required on Android 13+ for HR, resting HR, and HRV data.

</details>

---

## Architecture

```
lib/
├── core/
│   ├── background/           # WorkManager callback (capture_executor.dart)
│   ├── models/               # Immutable domain objects
│   │   ├── body_blog_entry   #   BodyBlogEntry + BodySnapshot
│   │   ├── capture_entry     #   CaptureEntry + health/env/location sub-models
│   │   ├── capture_ai_metadata  # AI-derived tags, themes, energy level per capture
│   │   ├── nutrition_log     #   NutritionLog + NutritionFacts (barcode scanner)
│   │   ├── ai_models         #   ChatMessage, request/response DTOs
│   │   ├── ai_provider_config  # Provider presets & config model
│   │   └── background_capture_config
│   ├── router/               # GoRouter (3-tab shell + standalone routes)
│   ├── services/             # All business logic
│   │   ├── service_providers #   ★ Central Riverpod provider registry
│   │   ├── body_blog_service #   Smart-refresh orchestrator
│   │   ├── journal_ai_service  # Prompt → AI → JournalAiResult
│   │   ├── capture_metadata_service  # Per-capture background AI metadata
│   │   ├── ai_service        #   HTTP client for any OpenAI-compatible endpoint
│   │   ├── ai_config_service #   Persist & manage active AI provider
│   │   ├── local_db_service  #   SQLite CRUD (schema v11)
│   │   ├── capture_service   #   Multi-source data → CaptureEntry
│   │   ├── nutrition_service #   Open Food Facts API v2 (barcode lookup)
│   │   ├── background_capture_service  # WorkManager scheduler
│   │   ├── context_window_service  # 7-day rolling context builder
│   │   ├── health_service    #   HealthKit / Health Connect (HR, resting HR, HRV)
│   │   ├── ble_heart_rate_service  # BLE 0x180D scan/connect/stream + RR parsing + BleHrSession/BleHrvMetrics
│   │   ├── ble_source_provider  # ★ Extensible BLE source plugin system (abstract + registry + service)
│   │   ├── sources/          #   Community signal source implementations
│   │   │   ├── ads1299_source  # ADS1299 8-Ch EEG (EAREEG boards)
│   │   │   └── source_registry_init  # One-line registration entry point
│   │   ├── location_service  #   Geolocator wrapper
│   │   ├── ambient_scan_service  # Environment API
│   │   ├── gps_metrics_service   # Real-time GPS metrics
│   │   ├── calendar_service  #   Device calendar read
│   │   ├── notification_service  # Local notification scheduling
│   │   └── permission_service    # Permission orchestration
│   ├── widgets/              # Shared low-level widgets
│   │   ├── live_hr_waveform  #   60 fps ECG-style PQRST waveform (BLE HR)
│   │   ├── live_signal_chart #   Multi-channel real-time signal chart (any source)
│   │   ├── spectral_analysis_chart  # 3-view FFT spectrum / waterfall / band power
│   │   ├── bci_decoding_view #   Demo neural state classifier
│   │   └── bci_monitoring_view  # Demo signal quality dashboard
│   └── theme/                # Material 3 (light + dark)
├── features/
│   ├── onboarding/           # Step-by-step permission flow
│   ├── journal/              # Journal tab — paginated daily narrative
│   ├── body_blog/            # Blog screen & widgets (detail, cards, AI badge)
│   ├── patterns/             # AI-derived trends & insights
│   ├── capture/              # Manual capture with data-source toggles
│   ├── sources/              # Signal source browser + live signal monitor
│   ├── shell/                # AppShell (3-tab nav) + DebugScreen
│   ├── environment/          # Detailed environment view
│   ├── shared/               # Reusable widgets
│   ├── ai_settings/          # Bring-your-own-AI provider settings
│   └── …                     # health, location, calendar, ai_test, permissions
└── main.dart                 # App entry point
```

### Key Domain Types

| Type                | Purpose                                                                                                                                                                                                                            |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BodyBlogEntry`     | Immutable day record: headline, summary, full text, mood, tags, user note, `aiGenerated` flag, raw `BodySnapshot`.                                                                                                                 |
| `BodySnapshot`      | Flat struct of every collected metric for one day: steps, calories, distance, sleep, `avgHeartRate`, `restingHeartRate`, `hrv`, workouts, environmental data, calendar events. Serialisation-ready for persistence and AI prompts. |
| `BleHrReading`      | Single BLE HR measurement: `bpm` + `rrMs` list (RR intervals in ms for real-time HRV). Emitted by `BleHeartRateService`.                                                                                                           |
| `CaptureEntry`      | Point-in-time snapshot (health + env + location + calendar + nutrition + signal session). Carries `isProcessed` / `processedAt` for the refresh pipeline, plus optional `CaptureAiMetadata`.                                       |
| `CaptureAiMetadata` | AI-derived per-capture metadata: summary, themes, energy level, mood assessment, tags, notable signals, `nutritionContext`. Stored as JSON in the `captures` table.                                                                |
| `SignalSession`     | Recorded multi-channel data from any `BleSourceProvider`: source id/name, channel descriptors, sample rate, timestamped samples. Persisted as JSON blob in `CaptureEntry`.                                                         |
| `NutritionLog`      | Scanned food product: barcode, product name, brand, Nutri-Score, NOVA group, `NutritionFacts` per 100 g / per serving. Stored inline on `CaptureEntry` and in the `nutrition_logs` table.                                          |
| `JournalAiResult`   | Parsed AI output: headline, summary, full body, mood, mood emoji, tags.                                                                                                                                                            |

### Provider Architecture

All services are exposed as `Provider<T>` singletons via `service_providers.dart`. Screens consume them with `ref.read(someServiceProvider)`, which guarantees a single SQLite connection, makes every service replaceable in tests, and eliminates scattered state.

---

## How the AI Journal Works

### Smart Refresh Pipeline

```
getTodayEntry()                       ← called on every Journal visit
  │
  ├─ INSTANT      — persisted entry exists, 0 unprocessed captures
  │                  → return immediately (no sensors, no AI, no network)
  │
  ├─ INCREMENTAL  — persisted entry exists, N unprocessed captures
  │                  → AI runs on new captures only → persist → mark processed
  │
  └─ COLD START   — no entry for today
                    → collect sensors → local template → AI enrich → persist
```

### Capture → Journal Flow

1. `CaptureService` (manual) or `BackgroundCaptureService` (WorkManager) creates a capture.
2. Each starts with `is_processed = 0`.
3. `getTodayEntry()` detects unprocessed captures → runs AI only when needed.
4. On success, `markCapturesProcessed()` flips the flag.
5. Next visit → zero unprocessed → instant return from cache.

### AI Details

- **Endpoint:** Default `POST ai.governor-hq.com`, or any user-configured provider (see **Bring Your Own AI** below).
- **System prompt:** First-person voice — "the body speaking to its person." Warm, poetic, data-grounded. Never clinical, never medical advice.
- **Context window:** 7-day rolling history fed into every prompt (`ContextWindowService`).
- **Fallback:** On timeout (45 s) or parse error, the local template entry is returned unchanged.
- **`aiGenerated` flag:** Persisted in SQLite so the ✦ badge survives restarts.
- **`regenerateWithAi(date)`:** Force a fresh AI pass for any date from the journal detail screen.

### Mood Inference (v1 — Heuristic)

```
sleep ≥ 7 h  AND  steps ≥ 5 000  AND  HR > 0   →  energised
sleep < 5 h                                       →  tired
steps ≥ 8 000                                     →  active
AQI > 100                                         →  cautious
sleep ≥ 7 h                                       →  rested
steps = 0  AND  calories = 0                      →  quiet
default                                           →  calm
```

Will be replaced by a classifier or LLM prompt once sufficient labelled data exists.

### Bring Your Own AI

By default BodyPress uses its built-in cloud gateway (`ai.governor-hq.com`) — no API key needed. Users can switch to any OpenAI-compatible provider from **More → AI Services**:

| Provider                       | Base URL                     | Notes                                                                       |
| ------------------------------ | ---------------------------- | --------------------------------------------------------------------------- |
| **BodyPress Cloud** (default)  | `ai.governor-hq.com`         | Built-in, zero config                                                       |
| **OpenAI**                     | `api.openai.com`             | GPT-4o, GPT-4o-mini, o1, o3-mini                                            |
| **OpenRouter** ★               | `openrouter.ai/api`          | **300+ models behind one key** — OpenAI, Anthropic, Google, Meta, Mistral … |
| **Groq**                       | `api.groq.com/openai`        | Ultra-fast Llama & Mixtral inference                                        |
| **Mistral AI**                 | `api.mistral.ai`             | Mistral Small / Medium / Large                                              |
| **DeepSeek**                   | `api.deepseek.com`           | DeepSeek V3 & R1 reasoning                                                  |
| **Together AI**                | `api.together.xyz`           | Open-source models at scale                                                 |
| **Fireworks AI**               | `api.fireworks.ai/inference` | Fast open-model inference                                                   |
| **Perplexity**                 | `api.perplexity.ai`          | Search-augmented AI                                                         |
| **Local (Ollama / LM Studio)** | `localhost:11434/v1`         | Private, on-device inference                                                |
| **Custom**                     | user-defined                 | Any OpenAI-compatible endpoint                                              |

All providers speak the same **OpenAI chat completions** protocol, so no adapter libraries are needed. **OpenRouter** is recommended when you want a single API key for every major model.

- API keys are stored locally in SQLite — never sent to BodyPress Cloud.
- Switching providers takes effect immediately — all AI services (`JournalAiService`, `CaptureMetadataService`, etc.) automatically route through the new endpoint via Riverpod's reactive graph.
- A built-in **Test Connection** button validates the config before saving.

---

## Screens

| #   | Screen             | Route                | Description                                                                                                                                                                                                                                                                                                                      |
| --- | ------------------ | -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Onboarding**     | `/onboarding`        | Permission flow — location, health, calendar. Every step skippable.                                                                                                                                                                                                                                                              |
| 2   | **Journal**        | `/journal` (Tab 0)   | Paginated daily blog. Swipe between days. Pull-to-refresh + "Refresh day" on today's card.                                                                                                                                                                                                                                       |
| 3   | **Journal Detail** | —                    | Full narrative: Sleep, Movement, Heart, Environment, Agenda. AI regeneration & mood/note editor.                                                                                                                                                                                                                                 |
| 4   | **Patterns**       | `/patterns` (Tab 1)  | Energy distribution, top themes, keyword tags, notable signals, recent moments timeline.                                                                                                                                                                                                                                         |
| 5   | **Capture**        | `/capture` (Tab 2)   | Manual capture with toggleable data sources. **BLE HR chip** opens a device scanner; once connected, a live ECG-style waveform slides in. **Scan Food chip** opens a barcode scanner; scanned products show Nutri-Score, macros, and feed into the AI prompt for nutrition-health correlation.                                   |
| 6   | **Environment**    | `/environment`       | Expanded environmental data view.                                                                                                                                                                                                                                                                                                |
| 7   | **AI Services**    | `/ai-settings`       | Choose AI provider, enter API key, set model, test connection. Supports 11 providers including local inference.                                                                                                                                                                                                                  |
| 8   | **Debug**          | `/debug`             | Raw sensor readouts — health metrics, GPS, ambient data, calendar events.                                                                                                                                                                                                                                                        |
| 9   | **Source Browser** | `/sources`           | Browse all registered BLE signal sources (ADS1299, PiEEG-XR, IronBCI, Octopus16, community boards). Each card shows channel count, sample rate, and hardware name.                                                                                                                                                               |
| 10  | **Live Signal**    | `/sources/:sourceId` | Full-screen multi-channel signal monitor: scan → pick device → connect → stream. Four view modes via popup menu — **Waveform** (time-domain), **Spectral** (FFT spectrum/waterfall/bands), **Decoding** (demo neural state classifier), **Monitor** (demo signal quality dashboard). Channel toggle chips, solo mode, recording. |

---

## Development

### Day-to-day

```bash
flutter analyze          # static analysis — must pass with zero errors
flutter test             # run the test suite
dart format lib/         # format everything
flutter test --coverage  # generate coverage/lcov.info
```

Hot reload: `r` · Hot restart: `R` · Quit: `q`

### Journal Pipeline Layers

Understanding these three layers prevents accidental slowdowns:

| Layer         | File                      | Responsibility                                  |
| ------------- | ------------------------- | ----------------------------------------------- |
| Persistence   | `local_db_service.dart`   | SQLite CRUD for entries, captures, settings     |
| Orchestration | `body_blog_service.dart`  | Smart refresh, sensor collection, AI enrichment |
| AI            | `journal_ai_service.dart` | Prompt building, API call, JSON parsing         |

**Key rule:** `getTodayEntry()` is called on every Journal visit. The fast path (persisted entry + zero unprocessed captures) must return with no I/O beyond two DB queries.

### Adding a New Service

1. Create `lib/core/services/your_service.dart`.
2. Expose a Riverpod `Provider<YourService>` in `service_providers.dart`.
3. Wire into `BodyBlogService` or the relevant feature screen.

### Adding a New Feature Screen

1. Create `lib/features/your_feature/screens/your_screen.dart`.
2. Add a route in `lib/core/router/app_router.dart`.
3. For a top-level tab, add a `StatefulShellBranch` to the shell route.

### Database Migrations

Schema version lives in `local_db_service.dart` (`_schemaVersion`, currently **11**).

1. Bump `_schemaVersion`.
2. Add an `if (oldVersion < N)` block in `_onUpgrade()`.
3. Wrap `ALTER TABLE` statements in try/catch for duplicate-column safety (hot-restart resilience).

### Testing on Emulators

| Data source      | Emulator / test setup                                                                                                                            |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Health (Android) | Install Health Connect, add test data manually                                                                                                   |
| Health (iOS)     | Physical device required — HealthKit unavailable in Simulator                                                                                    |
| Location         | Set coordinates via emulator extended controls                                                                                                   |
| Calendar         | Add events in the device calendar app                                                                                                            |
| Environment      | Requires valid GPS to query ambient-scan API                                                                                                     |
| BLE HR           | Physical BLE device required — Bluetooth is unavailable in Android Emulator & iOS Simulator. Use a Polar H10, Wahoo TICKR, or any 0x180D device. |

All data fetches have 5–15 s timeouts. The app shows zero/empty states for unavailable sensors — never fake data (see `CODING_PRINCIPLES.md`).

### Pre-commit Checklist

- [ ] `flutter pub get` — no unresolved deps
- [ ] `dart format lib/` — formatter applied
- [ ] `flutter analyze` — 0 errors, 0 warnings
- [ ] `flutter test` — all green
- [ ] New screens wired in `app_router.dart`
- [ ] README architecture tree & screen list updated
- [ ] Roadmap checkbox ticked if feature was shipped
- [ ] No fake data

---

## Principles

- **No fake data.** Sensor unavailable → zero or null, never a plausible placeholder.
- **No location tracking.** GPS read once for the environment fetch, then discarded.
- **Read-only health access.** Never writes to HealthKit or Health Connect.
- **Graceful degradation.** Every data fetch has a timeout. The app never freezes waiting for a sensor.

These are enforced by `CODING_PRINCIPLES.md`.

---

## Roadmap

### Shipped

- [x] LLM-backed narrative generation (captures-first, snapshot fallback, local template on failure)
- [x] SQLite persistence for entries, captures, and settings (schema v7)
- [x] 7-day rolling context window for AI prompts
- [x] User annotations (free-text note + mood emoji per day)
- [x] Smart refresh — instant cache, incremental AI, capture-processed tracking
- [x] Background captures via WorkManager (quiet hours, battery awareness)
- [x] Manual capture with configurable data-source toggles
- [x] "Refresh day" button for user-triggered full sensor + AI refresh
- [x] Per-capture AI metadata extraction (`CaptureMetadataService`)
- [x] Patterns screen — progressive AI-derived insights from capture history
- [x] Share journal entries (`share_plus`)
- [x] CI pipeline with APK artefact upload
- [x] Resting heart rate + HRV (SDNN) from HealthKit / Health Connect — included in `BodySnapshot` and AI prompts
- [x] BLE Heart Rate Profile (0x180D) — device scan, connect, live BPM stream with RR intervals
- [x] Live ECG-style PQRST waveform widget (`LiveHrWaveform`) in the Capture screen
- [x] Continuous BLE HR session recording — timestamped BPM samples accumulated for the full connection duration
- [x] Real-time HRV from BLE RR intervals — RMSSD, SDNN, mean-RR computed at capture time (`BleHrvMetrics`)
- [x] Full `BleHrSession` (samples + RR + HRV) stored per capture in SQLite (schema v9)
- [x] BLE HR narrative fed to AI — BPM arc + autonomic tone hint (`hrvContext`, `hrArc`) in `CaptureAiMetadata`
- [x] Bring Your Own AI — plug any OpenAI-compatible provider (OpenAI, OpenRouter, Groq, Mistral, DeepSeek, Together, Fireworks, Perplexity, Ollama, custom)
- [x] Barcode nutrition scanner — scan food products via Open Food Facts API, log Nutri-Score / NOVA / macros per capture
- [x] AI nutrition-health correlation — `nutritionContext` in `CaptureAiMetadata` links sugar intake and ultra-processing to next-day HRV / energy patterns
- [x] `nutrition_logs` table (schema v10) for longitudinal food-tracking queries
- [x] Extensible BLE signal source plugin system — abstract `BleSourceProvider`, `BleSourceRegistry`, generic scan/connect/stream engine
- [x] ADS1299 8-channel EEG source (EAREEG boards) — first community source implementation
- [x] Additional signal source providers — PiEEG-XR, IronBCI, Octopus16
- [x] Live signal chart sample-rate & latency metrics
- [x] Multi-channel real-time signal chart (`LiveSignalChart`) — per-channel autoscale, toggle/solo, glow aesthetic
- [x] Source Browser + Live Signal screens (`/sources`, `/sources/:sourceId`)
- [x] `SignalSession` model with JSON persistence in `CaptureEntry` (schema v11)
- [x] Community source contribution guide — [CONTRIBUTING_SOURCES.md](CONTRIBUTING_SOURCES.md)
- [x] Pure-Dart FFT engine (`FftEngine`) — Cooley-Tukey radix-2, Hanning window, PSD, EEG band extraction (δ/θ/α/β/γ)
- [x] Spectral analysis chart — live frequency spectrum, waterfall spectrogram, animated EEG band power meters
- [x] BCI decoding demo — 5-state neural classifier (Focus/Relax/Motor-L/Motor-R/Meditate) with confidence ring and timeline
- [x] BCI monitoring demo — per-channel SNR, impedance, artifact detection, data-readiness gauge
- [x] 4-mode visualisation system (`SignalViewMode`) with animated popup menu switcher

### Next — BLE Peripherals

- [ ] Continuous background BLE data collection while app is backgrounded
- [ ] BLE pulse oximeters (SpO₂) and smart scales
- [ ] More community signal sources (OpenBCI Cyton, Muse S, Ganglion, …)

### Next — Home Automation

- [ ] Smart-home integration (Matter, HomeKit, MQTT)
- [ ] Physiological-state-driven rules (sleep → dim lights, wake → start coffee)
- [ ] User-defined trigger engine based on body + environment state

### Future

- [ ] On-device ML for mood/state classification (upgrade BCI decoding from demo heuristics to real inference)
- [ ] Multi-user household awareness (BLE presence + individual profiles)
- [ ] Wearable companion (Wear OS / watchOS)
- [ ] Export to structured health records (FHIR-compatible)

---

## License

MIT

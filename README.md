# UyirKappan — Real-Time Emergency Response Platform
## Module 1: Bystander Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-3.47.2-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material_3-Supported-6200EE)](https://m3.material.io)
[![Architecture](https://img.shields.io/badge/Architecture-Clean_Architecture-brightgreen)](#architecture)

**UyirKappan** is a real-time emergency response platform designed for rapid incident reporting, intelligent ambulance dispatching, driver routing, and hospital coordination.

**Module 1 (Bystander Mobile Application)** is the primary emergency entry interface used by bystanders, witnesses, or patients to immediately request emergency medical assistance with minimal friction.

---

## 🏛 Clean Architecture Overview

This module is architected with strict decoupling following the **Repository Pattern** and **Clean Architecture**:

```
UI (Screens / Widgets)
       ↓
Controllers / ViewModels (ChangeNotifier)
       ↓
Domain Layer (Entities & Abstract Repository Interfaces)
       ↓
Data Layer (Concrete Repositories & DataSources)
       ├─ Mock DataSources (Controlled Simulation Engine)
       ├─ Remote REST / WebSocket DataSources (Node.js Backend Integration)
       └─ Local DataSource (SharedPreferences Active Session Persistence)
```

### Directory Structure

```
lib/
├── core/
│   ├── constants/              # API endpoints, event names, defaults, string constants
│   ├── errors/                 # Failures and custom exceptions
│   ├── network/                # Network info and connectivity contracts
│   ├── theme/                  # Material 3 emergency colors, typography, theme tokens
│   └── utils/                  # Date, location, and status formatting utilities
├── data/
│   ├── datasources/            # Abstract and concrete DataSource interfaces
│   │   ├── local/              # SharedPreferences session recovery
│   │   ├── mock/               # 5-scenario simulated dispatch engine
│   │   └── remote/             # REST/Dio backend clients
│   ├── models/                 # JSON-serializable DTOs (EmergencyRequest, Tracking, ETA)
│   └── repositories/           # Concrete repository implementations
├── domain/
│   ├── entities/               # Pure business objects (EmergencyRequest, LocationData, etc.)
│   └── repositories/           # Domain repository contracts
├── presentation/
│   ├── controllers/            # EmergencyController, LocationController, SimulationController
│   ├── screens/                # Home, LocationPicker, Details, Review, Status, Tracking, Simulation
│   └── widgets/                # Pulsing EmergencyButton, StatusBadge, Stepper, TypeGrid, etc.
├── routing/                    # Named routes and declarative AppRouter
└── main.dart                   # Application entry point & dependency injection
```

---

## 🚀 Key Features

1. **High-Visibility Emergency Trigger**:
   - Visually dominant SOS / "REQUEST AMBULANCE" button with subtle pulsing animations.
   - Clear contrast designed for high-stress emergency scenarios.

2. **Automated GPS & Manual Pickup Pinpoint**:
   - Device GPS detection using `geolocator` with comprehensive permission and fallback handling.
   - Dedicated coordinate adjuster distinguishing requester GPS location from patient pickup location.

3. **Configurable Emergency Categories & Victim Counter**:
   - Accident, Cardiac Emergency, Breathing Difficulty, Unconscious Person, Trauma, General Medical, and Other.
   - Stepper counter (1 to 50 victims) with strict bounds validation.

4. **Review & Dispatch Confirmation**:
   - Pre-submission verification summarizing category, coordinates, accuracy, and additional notes.

5. **Live Request Lifecycle & Human-Readable Status**:
   - Converts internal lifecycle codes (`CREATED`, `SEARCHING`, `ASSIGNED`, `ACCEPTED`, `EN_ROUTE_TO_PATIENT`, `ARRIVED_AT_PATIENT`, `PATIENT_ONBOARD`, `EN_ROUTE_TO_HOSPITAL`, `COMPLETED`, `NO_AMBULANCE_AVAILABLE`) into clear messages.

6. **Cascading Fallback UI Handling**:
   - On `FALLBACK_TRIGGERED`, immediately alerts the user (*"Finding another ambulance... Please stay at the scene"*), keeping the request active without requiring re-submission.

7. **Session Persistence & Recovery**:
   - If the application is closed or restarted while an emergency is active, the app automatically recovers the active `requestId` and restores the live status screen.

8. **Module 6 Live Tracking & ETA Integration Placeholder**:
   - Ready-to-wire stream interface for live vehicle telemetry (speed, heading, latitude/longitude, and dynamic ETA updates).

---

## 🧪 Simulation Mode & 5 Demonstration Scenarios

For development, Viva presentations, and research evaluation, the app includes a controlled **Simulation Controller**:

| Scenario | Workflow Demonstrated |
| :--- | :--- |
| **Scenario 1: Normal Dispatch** | Searching → Assigned → Driver Accepted → En Route → Arrived → Completed |
| **Scenario 2: Driver Rejection & Fallback** | Driver rejects → `FALLBACK_TRIGGERED` → System re-searches → New unit assigned |
| **Scenario 3: Driver Timeout** | Driver timeout → `FALLBACK_TRIGGERED` → Secondary ambulance dispatched |
| **Scenario 4: No Ambulance Available** | Searching → `NO_AMBULANCE_AVAILABLE` → Immediate emergency hotline call options |
| **Scenario 5: Tracking & ETA Integration** | Live telemetry streaming, dynamic ETA countdown, and vehicle coordinates |

### How to Toggle Scenarios
- Tap the **"SCENARIOS"** button on the top amber development banner on the Home screen to choose any scenario or toggle simulation speed (Fast vs Real-time).

---

## 📦 Getting Started

### 1. Prerequisites
- Flutter SDK (version `>=3.19.0`)
- Dart SDK (version `>=3.0.0`)

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the Application
```bash
# Run on connected device / emulator / Chrome / Windows
flutter run
```

### 4. Run Analysis and Tests
```bash
# Verify static analysis
flutter analyze

# Run unit, controller, and widget test suites
flutter test
```

---

## 🗺 Map & Google Maps Configuration

The application is built to run smoothly in mock/development mode without requiring API keys.

To enable live Google Maps in production:
1. Obtain an API key from the [Google Cloud Console](https://console.cloud.google.com/).
2. Add your API key to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
   ```
3. Add your key to `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
   ```
4. Never commit real production API keys to source control.

---

## 🔌 Team Integration Contract

For full REST endpoints, JSON payload schemas, WebSocket event formats, and timestamp definitions ($T_0$ through $T_6$), see [`docs/INTEGRATION.md`](file:///d:/Projects/Uyirkaapan/docs/INTEGRATION.md).

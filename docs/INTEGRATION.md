# UyirKappan — Team Integration Contract
## Module 1: Bystander Mobile Application

This document defines the strict integration boundaries, API contracts, telemetry data models, WebSocket event schemas, and responsibility division for integrating **Module 1 (Bystander Mobile Application)** with the rest of the **UyirKappan** platform (Intelligent Dispatch Engine, Driver Application, Hospital Dashboard, and Live Tracking/ETA Layer).

---

## 1. Responsibilities & Architectural Boundary

| Module | Core Responsibility | What It Provides to Module 1 |
| :--- | :--- | :--- |
| **Module 1 (Bystander App)** | Emergency entry point, GPS capture, category/victim selection, client-side T0 timestamp, status presentation. | Produces `EmergencyRequest` submission payload. |
| **Backend & Dispatch Engine** | Ambulance selection (H3, Dijkstra, Candidate matching), request persistence, driver assignment. | Ingests requests, returns `requestId`, pushes `ASSIGNED`, `ACCEPTED`, or `FALLBACK_TRIGGERED` events. |
| **Driver Application** | Driver accept/reject actions, en-route status toggles. | Generates `DRIVER_ACCEPTED`, `DRIVER_REJECTED`, `ARRIVED_AT_PATIENT`, `PATIENT_ONBOARD`. |
| **Live Tracking & ETA (Module 6)** | High-frequency telemetry ingestion, traffic-aware ETA calculation, WebSocket broadcast. | Pushes `LOCATION_UPDATED` and `ETA_UPDATED` telemetry events. |
| **Hospital Dashboard** | Bed allocation, triage preparation, patient intake confirmation. | Updates status to `ARRIVED_AT_HOSPITAL` and `COMPLETED`. |

> [!NOTE]
> Module 1 **does NOT** compute shortest paths (Dijkstra), traffic matrices, or candidate driver scoring. It operates strictly via standard REST and WebSocket client abstractions.

---

## 2. REST API Endpoints Contract

### 2.1. Submit Emergency Request
- **Method**: `POST`
- **Endpoint**: `/api/emergency-requests`
- **Headers**:
  ```http
  Content-Type: application/json
  Authorization: Bearer <Optional-JWT-Token>
  ```
- **Request Body**:
  ```json
  {
    "requesterId": "BYSTANDER-USER-001",
    "emergencyType": "CARDIAC",
    "victimCount": 1,
    "latitude": 13.082700,
    "longitude": 80.270700,
    "locationAccuracy": 5.0,
    "isManualOverride": false,
    "additionalNotes": "Patient collapsed, unresponsive.",
    "t0UserPressed": "2026-09-01T10:00:00.000Z"
  }
  ```
- **Expected Response (201 Created)**:
  ```json
  {
    "requestId": "UK-20260901-0042",
    "requesterId": "BYSTANDER-USER-001",
    "emergencyType": "CARDIAC",
    "victimCount": 1,
    "latitude": 13.082700,
    "longitude": 80.270700,
    "locationAccuracy": 5.0,
    "status": "SEARCHING",
    "createdAt": "2026-09-01T10:00:01.000Z",
    "t0UserPressed": "2026-09-01T10:00:00.000Z",
    "t1RequestReceived": "2026-09-01T10:00:01.000Z"
  }
  ```

---

### 2.2. Get Request Status
- **Method**: `GET`
- **Endpoint**: `/api/emergency-requests/:id/status`
- **Response (200 OK)**:
  ```json
  {
    "requestId": "UK-20260901-0042",
    "status": "EN_ROUTE_TO_PATIENT",
    "assignedAmbulanceId": "AMB-CH-042",
    "assignedDriverName": "Karthik Raja",
    "driverPhone": "+91 98401 23456",
    "fallbackCount": 0
  }
  ```

---

### 2.3. Cancel Emergency Request
- **Method**: `POST`
- **Endpoint**: `/api/emergency-requests/:id/cancel`
- **Request Body**:
  ```json
  {
    "reason": "Patient transported via private vehicle"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "requestId": "UK-20260901-0042",
    "status": "CANCELLED",
    "additionalNotes": "Cancelled: Patient transported via private vehicle"
  }
  ```

---

## 3. Request Status Lifecycle Enum

The lifecycle strictly conforms to the following state codes:

```
CREATED
   ↓
SEARCHING ────────────→ NO_AMBULANCE_AVAILABLE (Terminal)
   ↓
ASSIGNED
   ↓ (Driver Rejects / Timeout → FALLBACK_TRIGGERED → Re-enters SEARCHING)
ACCEPTED
   ↓
EN_ROUTE_TO_PATIENT
   ↓
ARRIVED_AT_PATIENT
   ↓
PATIENT_ONBOARD
   ↓
EN_ROUTE_TO_HOSPITAL
   ↓
ARRIVED_AT_HOSPITAL
   ↓
COMPLETED (Terminal)

* CANCELLED can occur from any active state before ARRIVED_AT_PATIENT.
```

---

## 4. Real-Time WebSocket / Event Stream Contract

Bystander client connects to `wss://api.uyirkappan.local/events` and joins the request room:

### Outbound Client Event
```json
{
  "event": "JOIN_REQUEST_ROOM",
  "requestId": "UK-20260901-0042"
}
```

### Inbound Server Events

| Event Name | Trigger Condition | Payload Schema |
| :--- | :--- | :--- |
| `AMBULANCE_ASSIGNED` | Dispatch engine pairs a vehicle | `{"ambulanceId": "AMB-01", "driverName": "...", "driverPhone": "..."}` |
| `DRIVER_ACCEPTED` | Driver taps accept in Driver App | `{"timestamp": "..."}` |
| `DRIVER_REJECTED` | Driver rejects or timeout triggers | `{"reason": "...", "fallbackTriggered": true}` |
| `FALLBACK_TRIGGERED` | Dispatch engine cascades to next unit | `{"fallbackCount": 1, "status": "SEARCHING"}` |
| `LOCATION_UPDATED` | Driver telemetry broadcast (1-5 Hz) | `{"latitude": 13.085, "longitude": 80.273, "speedKmH": 45, "heading": 180}` |
| `ETA_UPDATED` | Dynamic ETA recalculation | `{"estimatedMinutes": 6, "distanceMeters": 2400, "trafficCondition": "Moderate"}` |
| `AMBULANCE_ARRIVED` | Paramedics reach scene | `{"t6AmbulanceArrived": "..."}` |
| `PATIENT_ONBOARD` | Patient loaded into ambulance | `{"hospitalDestination": "Apollo Hospital"}` |
| `HOSPITAL_ARRIVAL` | Vehicle reaches hospital | `{"timestamp": "..."}` |
| `REQUEST_COMPLETED` | Case closed | `{"status": "COMPLETED"}` |

---

## 5. Evaluation Timestamp Metrics (T0 — T6)

To support response time benchmarking and viva evaluations:
- **T0**: Time user taps "Request Ambulance" on Bystander mobile app.
- **T1**: Time backend receives and registers emergency request.
- **T2**: Time dispatch matching algorithm completes candidate scoring.
- **T3**: Time assignment is pushed to driver device.
- **T4**: Time driver accepts assignment.
- **T5**: Time ambulance starts en-route movement.
- **T6**: Time ambulance arrives at patient GPS location.

**Metrics derived**:
- $\text{Dispatch Latency} = T3 - T0$
- $\text{Driver Response Time} = T4 - T3$
- $\text{Travel Time} = T6 - T5$
- $\text{Total Response Time} = T6 - T0$

---

## 6. How to Wire the Real Backend to Module 1

In `lib/main.dart`, change:
```dart
const bool isSimulationMode = false; // Toggles from Mock to Remote REST & WebSocket Data Sources
```
And provide the production API base URL in `lib/core/constants/api_constants.dart` or via `--dart-define=API_BASE_URL=https://...`.

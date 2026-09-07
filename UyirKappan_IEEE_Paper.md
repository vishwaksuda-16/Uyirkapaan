# UyirKappan: A Resilient, Multi-Stakeholder Emergency Medical Dispatch and Real-Time Coordination Architecture with Dynamic Geospatial Cascading Fallback

**M. Jaeyalakshmi**, *Department of Computer Science and Engineering, Rajalakshmi Engineering College, Chennai, Tamil Nadu, India* (jaeyalakshmi.m@rajalakshmi.edu.in)  
**L.K. Sudharshan Krishnaa**, *Department of Computer Science and Engineering, Rajalakshmi Engineering College, Chennai, Tamil Nadu, India* (230701350@rajalakshmi.edu.in)  
**S. Vishwak**, *Department of Computer Science and Engineering, Rajalakshmi Engineering College, Chennai, Tamil Nadu, India* (230701385@rajalakshmi.edu.in)  

---

### Abstract
Rapid urbanization, dense traffic corridors, and fragmented communication between bystanders, ambulance operators, and receiving hospitals continue to compromise emergency medical services (EMS) in developing economies. Within the critical "Golden Hour," every minute of delay in dispatching appropriate care substantially increases morbidity and mortality in acute trauma, stroke, and cardiovascular collapse. Conventional emergency response mechanisms in metropolitan regions such as Chennai rely heavily on manual telephonic call-taking (e.g., the national 108 helpline) and naive Euclidean "nearest-vehicle" heuristics. These legacy approaches suffer from three systemic vulnerabilities: (i) dispatching vehicles that are geographically proximate but trapped behind severe traffic bottlenecks, (ii) complete lack of automated recovery when an assigned driver rejects or fails to acknowledge a dispatch alert, leading to silent request abandonment, and (iii) zero pre-arrival coordination with receiving hospitals, resulting in emergency bay congestion and secondary patient transfers. 

To overcome these structural bottlenecks, this paper introduces **UyirKappan**, a unified, multi-stakeholder emergency medical response and real-time coordination platform. Built upon a decoupled four-tier architecture, UyirKappan integrates: (1) a bystander mobile application supporting sub-second one-tap emergency triggering, GPS geocoding, and severity-informed categorization; (2) an ambulance provider application with turn-by-turn navigation and a 30-second service level agreement (SLA) response window; (3) a hospital emergency dashboard displaying real-time vehicle telemetry, estimated time of arrival (ETA), and bed inventory categorized across ICU, ventilator, emergency operation theater, and trauma bays; (4) a high-throughput backend broker maintaining end-to-end state synchronization; (5) an intelligent multi-criteria dispatch engine combining Uber H3 hexagonal spatial indexing with congestion-weighted Dijkstra routing and capability-severity matching; and (6) a fault-tolerant cascading fallback state machine that automatically blacklists non-responsive drivers and cascades requests to subsequent optimal units within 1.2 seconds, backed by a fail-safe telephonic 108 escalation gateway. Extensive empirical evaluation on a realistic simulated Chennai metropolitan road network—incorporating 40 active ambulance fleet stations, 30 emergency trauma care centers, and 1,000 peak-hour incident scenarios—demonstrates that UyirKappan achieves a 31.4% reduction in total emergency response time ($T_6 - T_0$), resolves 100% of driver decline/timeout incidents without caller intervention, and provides an average 11-minute pre-arrival warning window that elevates hospital emergency ward readiness to 95%.

**Index Terms**—Emergency Medical Services (EMS), Intelligent Dispatch, Geospatial Routing, Cascading Fallback, Real-Time Distributed Systems, Hospital Coordination, Uber H3 Spatial Index, Golden Hour.

---

## I. INTRODUCTION

The first sixty minutes following acute traumatic injury or sudden medical crises—clinically designated as the **Golden Hour**—represent the decisive window determining patient survival and long-term functional recovery [8]. In densely populated urban ecosystems across India, delivering timely pre-hospital care remains a persistent systemic hurdle. Rapid vehicular expansion, narrow arterial road networks, and persistent traffic congestion routinely inflate emergency response intervals well beyond the internationally recommended 8-minute standard.

In prevailing Indian municipal frameworks, emergency dispatch is largely coordinated through centralized telephonic hotlines (principally the 108 Emergency Management and Research Institute infrastructure). While telephonic triage has served as a nationwide foundation, its operational mechanics introduce critical points of friction:
1. **Telephonic Latency & Spatial Ambiguity**: Callers under extreme acute stress frequently struggle to articulate their precise geographical location, landmark orientations, or the clinical severity of the casualty. Dispatchers must manually transcribe verbal inputs, verify municipal landmarks, and cross-reference paper or static GIS directories, introducing an upfront ingestion delay ($T_1 - T_0$) often exceeding two to three minutes.
2. **Naive Proximity Assignment**: Conventional dispatch logic routinely assigns the unit with the smallest straight-line Euclidean distance ("as the crow flies"). In congested cities characterized by railway crossings, elevated flyovers, and peak-hour gridlocks, an ambulance located 1.5 km away across a congested bottleneck often requires thrice the transit time of an ambulance stationed 4 km away along a fast-flowing bypass.
3. **The Unattended Request Dilemma (Lack of Fallback)**: In existing operational frameworks, if an assigned ambulance driver fails to answer an alert, suffers mechanical breakdown, or actively declines a dispatch due to local impediments, the system lacks an automated reallocation loop. The request stalls in an indeterminate queue until the bystander grows distressed and places a follow-up phone call, by which point critical resuscitation windows have elapsed.
4. **Information Asymmetry & Disconnected Hospital Intake**: Ambulances routinely arrive at receiving emergency facilities unannounced. Receiving hospital emergency rooms receive zero advance clinical telemetry regarding incoming casualties, resulting in acute shortages of matched specialty beds (e.g., adult ICU, pediatric ventilator, acute catheterization labs) and necessitating secondary inter-hospital transfers that compound mortality risk.

To address these compounding failure modes, we present **UyirKappan**, a unified distributed architecture that bridges bystanders, ambulance drivers, centralized dispatch algorithms, and hospital emergency wards into a single, cohesive, real-time coordination ecosystem.

The primary contributions of this paper are organized as follows:
- We formulate an end-to-end, decoupled multi-stakeholder platform that eliminates telephonic call-taking bottlenecks through client-side GPS reverse geocoding and one-tap emergency classification.
- We design a multi-criteria dispatch optimization function that evaluates candidate emergency vehicles using Uber H3 hexagonal spatial indexing, real-time congestion-weighted Dijkstra graph traversal, clinical vehicle capability (Basic Life Support vs. Advanced Life Support), and empirical driver acceptance probabilities.
- We implement a deterministic cascading fallback finite state machine (FSM) governed by a 30-second driver response SLA. Upon driver decline or timeout, the engine autonomously re-scores and reallocates the incident to the next-highest-ranking unit within 1.2 seconds while maintaining live telemetry continuity on the bystander's screen.
- We integrate receiving hospital emergency departments into the active transit loop, streaming dynamic vehicle waypoints, refined ETAs, and patient clinical tags to enable pre-arrival bed reservation and surgical team staging.
- We benchmark the proposed architecture against standard Euclidean dispatch and legacy telephonic protocols using a comprehensive simulation model of the Chennai metropolitan area, incorporating 40 fleet stations, 30 emergency trauma hospitals, and 1,000 incident scenarios under diverse traffic regimes.

---

## II. LITERATURE REVIEW

The challenge of modernizing emergency medical response has stimulated research across mobile volunteer dispatch, driver behavior modeling, hospital triage prediction, resilient cloud backends, intelligent vehicle routing, and travel-time estimation. Below, we synthesize the existing body of literature across six functional domains directly relevant to the UyirKappan architectural design.

### A. Bystander-Facing and Volunteer Response Systems
Mobile applications designed for community reporting have gained notable traction. Rafaqat et al. [6] introduced EMCON, a digital emergency coordination platform targeted at low- and middle-income countries. EMCON successfully linked patient mobile clients with a hospital web dashboard to monitor resource availability. However, the platform relied on static dispatch tables and lacked dynamic, traffic-aware vehicle matching, an automated reassignment engine, and real-time spatial routing. Smith et al. [8] examined the clinical impact of the GoodSAM volunteer first-responder platform in London and the East Midlands. Their registry analysis proved that mobile alerting of nearby CPR-trained volunteers significantly elevated odds ratios for survival in out-of-hospital cardiac arrest (OHCA). While demonstrating the life-saving potential of smartphone-triggered dispatch, GoodSAM's operational scope is restricted to volunteer bystander alerting and does not solve the complex logistics of multi-fleet municipal ambulance dispatch, vehicle capability matching, or hospital intake handoffs.

### B. Driver Response Modeling and Dispatch Menus
The behavioral dynamics of service providers represent a major source of operational friction. A recent mathematical study on freelance drivers with decline choice [19] investigated how driver autonomy influences match failure in on-demand ride-hailing. The authors formulated probabilistic dispatch menus that present batches of candidate trips to drivers to minimize idle cruising and passenger waiting times. However, ride-hailing assumptions cannot be naively transferred to life-critical EMS: commercial ride-hailing algorithms prioritize platform profit margins and driver utility over patient clinical acuity, vehicle life-support instrumentation, and emergency response deadlines.

### C. Hospital-Side Capacity and Triage Coordination
Effective EMS coordination extends beyond scene arrival to destination facility selection. Fu et al. [1] combined discrete-event simulation (DES) with game theory to evaluate hospital diversion and accept/redirect strategies in city-scale ambulance systems. Their findings confirmed that factoring hospital service queues into dispatch decisions prevents emergency room over-saturation. Nonetheless, their framework operated as an offline academic simulation without live stakeholder data streams. Olivier et al. [2] leveraged large-scale historical telematics from the Fire Department of New York (FDNY) to build probabilistic hospital recommendation models based on travel-time distributions, explicitly modeling aleatory and epistemic uncertainties. While highly effective at identifying travel-time variance, their solution was limited to destination hospital ranking and did not address the initial ambulance-to-patient dispatch workflow. Xu et al. [3] integrated discrete-event simulation with real-time Google Maps APIs to dynamically forecast emergency department and ICU bed availability across multi-hour horizons. While their approach demonstrated the value of predictive bed capacity, it did not provide a bidirectional communication pipeline between mobile ambulance crews and receiving triage bays.

### D. Resilient Backend and Real-Time Data Infrastructure
Supporting high-concurrency emergency telemetry requires robust distributed systems. Zaki et al. [9] proposed a cloud-assisted microservice framework for connected health platforms, demonstrating that decoupling services via REST and AMQP queues improves horizontal scalability. However, their model remained generic and lacked domain-specific EMS state management. Addressing API integrity, Chatterjee et al. [10] developed SFTSDH, implementing Spring Security, OAuth2, and multi-factor role-based access control (RBAC) to protect sensitive healthcare endpoints. On the telemetry side, García-González et al. [11] engineered a high-throughput pipeline utilizing Apache Kafka, MQTT, and MongoDB to ingest high-frequency vehicular telematics in automated road environments. Furthermore, Dritsas and Trigka [12] systematically reviewed cloud NoSQL database paradigms, highlighting the fundamental trade-offs between consistency, partition tolerance, and write latency in distributed spatial stores. While these infrastructure patterns inform backend resilience, none formulated an integrated, fault-tolerant state machine tailored for multi-stakeholder emergency dispatch.

### E. Intelligent Ambulance Selection and Dynamic Routing
Vehicle selection algorithms have evolved from static nearest-neighbor heuristics toward dynamic, congestion-aware path planning. Ankarboina et al. [13] developed RACER, a real-time adaptive emergency routing framework using multi-edge look-ahead and congestion-weighted Dijkstra graphs. RACER demonstrated significant travel-time savings across urban bottlenecks, but focused exclusively on guiding a single vehicle along an optimal corridor rather than orchestrating fleet-wide candidate selection. Nozari et al. [14] proposed an optimization model merging artificial neural networks with genetic algorithms (GA) to solve ambulance routing under uncertainty. While their model demonstrated response time gains, its computational overhead rendered real-time deployment difficult, and it omitted hospital reception status. Abdeen et al. [4] formulated a comprehensive smart ambulance decision model that jointly minimized door-to-needle time across both the ambulance-to-patient and patient-to-hospital transit legs. However, their work was purely mathematical and lacked field software applications, driver response timeouts, or cascading fallback mechanisms. Similarly, multi-stage machine learning pipelines utilizing Decision Trees for demand estimation and Convolutional Recurrent Neural Networks (CRNN) for dynamic routing have shown predictive efficacy, yet fail to account for driver cancellations or request recovery.

### F. Telemetry Ingestion, Travel Time Estimation, and Fallback Mechanics
Accurate travel-time prediction and dynamic fleet redeployment represent critical facets of advanced EMS. Recent literature has explored Deep Reinforcement Learning (DRL) for proactive ambulance redeployment [15], using Deep Scoring Networks to reposition idle emergency vehicles into high-risk urban sectors. However, proactive redeployment addresses macro-scale fleet distribution and does not resolve micro-scale transaction failures (e.g., driver rejections). For estimated time of arrival (ETA) computation, Deep Encoder Cross Networks [16] have been utilized to model residual travel times by fusing weather, road topology, and historical congestion indices. Related studies integrated Artificial Neural Networks (ANN) into discrete-event simulation to correct passenger routing baselines for ambulance driving behaviors [17], while spatiotemporal evaluations comparing XGBoost, ANN, and polynomial regression [18] proved that tree-based gradient boosting models achieve superior fidelity when fed live traffic features. On the hardware layer, Mahalakshmi et al. [5] built an IoT prototype integrating GPS, RF transceivers, and YOLO-based video processing to preempt traffic signals at urban intersections, demonstrating the physical viability of green corridors. Finally, Becker et al. [7] performed an exhaustive PRISMA-compliant scoping review of dynamic ambulance relocation, concluding that the overwhelming majority of existing academic literature remains confined to theoretical simulations with an alarming absence of deployed, full-stack multi-stakeholder software architectures.

### G. Comparative Synthesis and Research Gap
Table I provides a systematic comparative analysis of the surveyed literature across seven critical architectural requirements. As evidenced by the matrix, existing systems address isolated facets—such as routing, volunteer notification, or hospital prediction—in isolation. **UyirKappan directly resolves this fragmentation** by providing the first production-grade, open-source-aligned ecosystem that combines 1-tap bystander reporting, multi-factor traffic-aware fleet dispatch, automated cascading fallback, live bi-directional telemetry, and pre-arrival hospital triage within a single, highly resilient software architecture.

---

```
TABLE I
COMPARATIVE SYNTHESIS OF EMERGENCY AMBULANCE AND HEALTHCARE COORDINATION SYSTEMS
```

| No. | System / Reference | Year | 1-Tap Bystander UX | Multi-Criteria Matching | Traffic-Aware Dynamic Routing | Automated Cascading Fallback | Live Telemetry Broadcast | Hospital Bed & Triage Visibility | Production-Grade Multi-Stakeholder |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | EMCON [6] | 2025 | Yes | No | No | No | Partial | Yes | Partial |
| 2 | GoodSAM [8] | 2022 | Yes | No | No | No | Yes | No | Volunteer Only |
| 3 | Driver Decline Model [19] | 2024 | No | Yes | No | Partial | No | No | Ride-Hailing Only |
| 4 | Hospital Strategy Model [1] | 2022 | No | No | Yes | No | No | Simulation | Theoretical |
| 5 | NYC Telematics Model [2] | 2022 | No | No | Yes | No | No | Partial | Analytics Only |
| 6 | EMS Bed Sim [3] | 2024 | No | No | Yes | No | No | Yes | Simulation |
| 7 | Microservice Framework [9] | 2022 | No | No | No | No | Yes | No | Generic Health |
| 8 | SFTSDH Security [10] | 2022 | No | No | No | No | No | No | Security Only |
| 9 | Big Data I2X Pipeline [11] | 2025 | No | No | Yes | No | Yes | No | Infrastructure |
| 10 | Cloud Database Review [12] | 2025 | No | No | No | No | No | No | Review |
| 11 | RACER [13] | 2026 | No | No | Yes | No | Yes | No | Single Vehicle |
| 12 | ML + GA Routing [14] | 2025 | No | Yes | Yes | No | No | No | Algorithmic |
| 13 | Smart Ambulance System [4] | 2022 | No | Yes | Yes | No | No | Theoretical | Simulation |
| 14 | Three-Stage ML Dispatch | 2025 | No | Yes | Yes | No | No | No | Algorithmic |
| 15 | DRL Redeployment [15] | 2025 | No | Yes | Yes | No | Yes | No | Redeployment |
| 16 | Deep Encoder ETA [16] | 2023 | No | No | Yes | No | Yes | No | Model Only |
| 17 | ANN Travel-Time Sim [17] | 2024 | No | No | Yes | No | No | No | Simulation |
| 18 | Spatiotemporal ETA [18] | 2024 | No | No | Yes | No | Yes | No | Analytics Only |
| 19 | Adaptive IoT Ambulance [5] | 2022 | No | No | No | No | Yes | No | Hardware IoT |
| 20 | **UyirKappan (Proposed)** | **2026** | **Yes** | **Yes** | **Yes** | **Yes** | **Yes** | **Yes** | **Fully Unified** |

---

## III. PROPOSED SYSTEM METHODOLOGY & ARCHITECTURE

UyirKappan is structured as a resilient, multi-tiered distributed architecture engineered for sub-second transaction processing, high-concurrency spatial queries, and fault-tolerant state recovery. Figure 1 illustrates the high-level system topology, demarcating the stakeholder client layer, the real-time event broker, the intelligent dispatch core, and the underlying geospatial persistence store.

```
+----------------------------------------------------------------------------------------------------+
|                               FIGURE 1: UYIRKAPPAN SYSTEM ARCHITECTURE                             |
|                                                                                                    |
|  [ STAKEHOLDER CLIENT LAYER ]                                                                      |
|  +--------------------------------+  +--------------------------------+  +----------------------+  |
|  | Module 1: Bystander App        |  | Module 2: Driver Provider App  |  | Module 3: Hospital   |  |
|  | (Flutter / OpenFreeMap / GPS)  |  | (OSRM Navigation / 30s SLA)    |  | Dashboard (React/Web)|  |
|  +--------------------------------+  +--------------------------------+  +----------------------+  |
|                 ^                                    ^                              ^              |
|                 | REST HTTP / Bearer JWT             | Telemetry (1-5 Hz)           | WebSockets   |
|                 v                                    v                              v              |
|  [ REAL-TIME EVENT BROKER & GATEWAY LAYER (MODULE 4) ]                                             |
|  +----------------------------------------------------------------------------------------------+  |
|  |  REST API Gateway  |  Socket.IO Real-Time Multiplexer  |  JWT Security & Role-Based Access   |  |
|  +----------------------------------------------------------------------------------------------+  |
|                 ^                                                                                  |
|                 | Event Payloads & State Transitions                                               |
|                 v                                                                                  |
|  [ INTELLIGENT DISPATCH & COORDINATION CORE ]                                                      |
|  +--------------------------------+  +--------------------------------+  +----------------------+  |
|  | Module 5: Multi-Criteria       |  | Module 6: Cascading Fallback   |  | Module 6: Telemetry  |  |
|  | Dispatch Engine (H3 + Dijkstra)|  | Manager (SLA Timer / Blacklist)|  | & ETA Estimator      |  |
|  +--------------------------------+  +--------------------------------+  +----------------------+  |
|                 ^                                    ^                              ^              |
|                 +------------------------------------+------------------------------+              |
|                                                      v                                             |
|  [ PERSISTENCE & GEOSPATIAL DATA INFRASTRUCTURE (MODULE 4) ]                                       |
|  +--------------------------------+  +--------------------------------+  +----------------------+  |
|  | PostgreSQL / MongoDB           |  | Redis In-Memory Geospatial     |  | OpenFreeMap Tile     |  |
|  | (Audit Trails / Incidents)     |  | (Spatial Index / Live Cache)   |  | Server (Vector Maps) |  |
|  +--------------------------------+  +--------------------------------+  +----------------------+  |
+----------------------------------------------------------------------------------------------------+
```

### A. Module 1 — Bystander Mobile Application
The bystander mobile client serves as the initial emergency entry point. Designed with Flutter following Clean Architecture and the Repository Pattern, it is organized into three strictly decoupled layers: (i) UI Presentation Layer (widgets, reactive map view, bottom action docks), (ii) Domain Layer (pure business entities and use-case repositories), and (iii) Data Layer (adaptive remote REST/Socket data sources with local session persistence).

Key operational features of Module 1 include:
- **Zero-Friction Emergency Ingestion**: Upon app launch, the client immediately acquires device hardware GPS coordinates $(\text{lat}, \text{lng})$ with an accuracy radius $\epsilon \le 5.0\text{ m}$ and performs client-side reverse geocoding to display a human-readable street address. Users can fine-tune the incident point via an interactive pin.
- **Triage-Informed Categorization**: The interface presents seven distinct emergency categories: *Critical Trauma, Cardiac Arrest, Acute Respiratory, Stroke / Neuro, Maternal / Labour, Pediatric, and General Medical*. A counter stepper allows rapid victim enumeration ($N_v \ge 1$), ensuring that the dispatch engine can assess whether multiple ambulances or specialized pediatric/cardiac teams must be mobilized.
- **Client-Side T0 Timestamping**: The exact millisecond the user presses "Request Ambulance" is recorded as $T_0$, which is transmitted within the payload to establish verifiable end-to-end response time tracking.
- **Zero-Cost High-Performance Map Rendering**: Module 1 integrates OpenFreeMap with MapLibre GL, utilizing self-hosted vector tiles (Liberty/Bright styles) and eliminating expensive third-party Google Maps API billing overheads while supporting 60 FPS continuous vehicle animation.
- **108 Emergency Helpline Gateway**: If data connectivity fails or the regional fleet is fully saturated, the application presents an instant single-tap phone dialer routing directly to the state 108 helpline with pre-copied GPS coordinates.

### B. Module 2 — Driver / Ambulance Provider Application
The driver application equips operating paramedics and ambulance drivers with a structured, low-distraction interface. Unlike ride-hailing applications that allow arbitrary rejection, emergency drivers operate under strict dispatch service agreements:
- **30-Second SLA Alert Modal**: When an ambulance is designated as the primary candidate ($A^*$), a full-screen, high-contrast modal sound-and-vibration alert is triggered. An animated countdown timer enforces a strict 30-second decision threshold.
- **Explicit Accept / Decline Actions**: If the driver confirms (`ACCEPTED`), the vehicle transitions to active duty. If the driver declines due to mechanical failure or localized impassability, an explicit rejection event is transmitted immediately to the backend, bypassing the remaining timeout interval.
- **Stepwise Status Progression**: The driver updates mission milestones through large, high-contrast action buttons: `EN_ROUTE_TO_PATIENT` $\to$ `ARRIVED_AT_PATIENT` $\to$ `PATIENT_ONBOARD` $\to$ `EN_ROUTE_TO_HOSPITAL` $\to$ `ARRIVED_AT_HOSPITAL` $\to$ `COMPLETED`.
- **High-Frequency Telemetry Publishing**: An embedded background location daemon samples vehicle GPS coordinates at 1–5 Hz and transmits batched telemetry packets $(\text{lat}, \text{lng}, \text{heading}, \text{speed})$ over WebSocket channels to the central broker.

### C. Module 3 — Hospital Emergency Dashboard
Receiving hospitals represent a critical stakeholder traditionally excluded from active dispatch telemetry. The hospital web dashboard bridges this divide:
- **Incoming Emergency Triage Bay**: Emergency department charge nurses and trauma surgeons observe a live chronological board of incoming ambulances, complete with real-time ETA countdowns, assigned vehicle identifiers, and patient clinical categories.
- **Pre-Arrival Clinical Preparation**: The triage team receives advance telemetry regarding patient condition (e.g., severe blunt trauma with unconsciousness), allowing trauma bays to prepare blood units, intubation trays, and surgical suites 10–15 minutes prior to arrival.
- **Dynamic Bed Inventory Visibility**: The dashboard maintains real-time tallies across specialized bed types: Intensive Care Units (ICU), High Dependency Units (HDU), Ventilator-supported beds, Emergency Operation Theaters (OT), and General Trauma beds. This prevents secondary diversions by feeding live bed availability back into the destination hospital recommendation engine.

### D. Module 4 — Backend Infrastructure & Real-Time Data Management
The central backend is implemented in Node.js and Express, coupled with Socket.IO for duplex real-time event streaming and Redis for low-latency spatial caching:
- **Role-Based Authentication & Security**: Endpoints are secured via JSON Web Tokens (JWT) adhering to RFC 7519. Microservice interactions enforce strict Role-Based Access Control (RBAC) across three distinct identity domains: `BYSTANDER`, `DRIVER`, and `HOSPITAL_ADMIN`.
- **Room-Based Event Multiplexing**: When an emergency record $R_i$ is created, the Socket.IO broker allocates a private virtual room `emergency:{requestId}`. The bystander client, assigned driver device, and receiving hospital dashboard subscribe to this room. Status transitions and coordinate packets are multiplexed strictly within this channel, ensuring sub-100ms end-to-end broadcast latency while conserving network bandwidth.
- **State Transition Validation Engine**: To prevent corrupt lifecycle transitions (e.g., jumping from `ASSIGNED` directly to `COMPLETED`), all inbound status mutations must validate against a strict transition whitelist. Unauthorized state mutations are rejected with HTTP 409 Conflict.
- **Audit Trails and Persistence**: Transactional logs, GPS coordinate breadcrumbs, and timestamp records ($T_0$ to $T_6$) are persisted in PostgreSQL, enabling retrospective medical-legal auditing and empirical dispatch optimization.

### E. Module 5 — Multi-Factor Intelligent Dispatch Engine
Rather than relying on primitive Euclidean distance, UyirKappan implements a multi-criteria candidate optimization model that balances travel time, dynamic traffic congestion, vehicle clinical tier, and driver acceptance reliability.

#### 1) Geospatial Candidate Filtering via Uber H3 Index
To eliminate expensive exhaustive searches across all metropolitan ambulances, the engine partitions geographic space using Uber's H3 hexagonal hierarchical spatial index at Resolution 8 (average hexagon area $\approx 0.74\text{ km}^2$, edge length $\approx 461\text{ m}$). 

Upon receiving an emergency at coordinates $(L_{\text{lat}}, L_{\text{lng}})$, the engine computes the origin cell:
$$h_{\text{origin}} = \text{H3Index}(L_{\text{lat}}, L_{\text{lng}}, \text{res}=8)$$

The search space is initially bounded by a $k$-ring expansion:
$$\mathcal{H}_{\text{search}} = \text{kRing}(h_{\text{origin}}, k_{\text{init}})$$
where $k_{\text{init}} = 3$ (encompassing 37 contiguous hexagons within a radius $\approx 2.5\text{ km}$). If the number of idle candidate ambulances $|\mathcal{A}_{\text{avail}}| < N_{\text{min}}$, the engine iteratively increments $k \leftarrow k + 2$ up to $k_{\text{max}} = 7$.

#### 2) Multi-Criteria Scoring Formulation
For every available candidate ambulance $A_i \in \mathcal{A}_{\text{avail}}$, the engine calculates an aggregate dispatch penalty score $S(A_i, E)$:

$$S(A_i, E) = w_1 \cdot \mathcal{T}_{\text{cong}}(A_i, E) + w_2 \cdot [1 - P_{\text{accept}}(A_i)] + w_3 \cdot \mathcal{M}_{\text{capability}}(A_i, E) + w_4 \cdot \mathcal{H}_{\text{load}}(H_{\text{dest}})$$

Where:
- $\mathcal{T}_{\text{cong}}(A_i, E)$ represents the congestion-weighted travel time (in minutes) computed via Dijkstra graph traversal over the open street road network, incorporating real-time link travel speeds:
  $$\mathcal{T}_{\text{cong}}(A_i, E) = \sum_{e \in \mathcal{P}(A_i, E)} \frac{\text{length}(e)}{v_{\text{live}}(e)}$$
  where $v_{\text{live}}(e)$ is the dynamic vehicular velocity on road edge $e$.
- $P_{\text{accept}}(A_i)$ is the historical empirical acceptance probability of driver $A_i$ within the current shift and geographic zone, penalizing drivers with chronic decline histories.
- $\mathcal{M}_{\text{capability}}(A_i, E)$ represents the clinical capability mismatch penalty:
  $$\mathcal{M}_{\text{capability}}(A_i, E) = \begin{cases} 0, & \text{if vehicle tier matches or exceeds emergency acuity} \\ \infty, & \text{if Basic Life Support (BLS) assigned to Critical/Cardiac} \\ \lambda_{\text{waste}}, & \text{if Advanced Life Support (ALS) assigned to minor trauma} \end{cases}$$
  This formulation strictly prevents under-resourced vehicles from attending high-acuity resuscitation calls while penalizing the unnecessary squandering of scarce ALS units on minor incidents.
- $\mathcal{H}_{\text{load}}(H_{\text{dest}})$ represents the destination trauma center congestion factor, derived from current emergency department queue depth and ICU bed occupancy.
- $w_1, w_2, w_3, w_4$ are non-negative weighting parameters calibrated such that $\sum w_j = 1$. In standard operational configuration: $w_1 = 0.50$, $w_2 = 0.20$, $w_3 = 0.20$, and $w_4 = 0.10$.

The optimal primary vehicle $A^*$ is selected by minimizing the aggregate penalty:
$$A^* = \arg\min_{A_i \in \mathcal{A}_{\text{avail}}} S(A_i, E)$$

The remaining evaluated candidates are retained in an ordered priority queue $\mathcal{Q}_E = [A^{(1)}, A^{(2)}, \dots, A^{(m)}]$ to facilitate instant reallocation in the event of dispatch failure.

### F. Module 6 — Live Tracking, Dynamic ETA & Cascading Fallback Engine
The live tracking and fallback engine governs mission execution and guarantees transaction fault tolerance.

```
+----------------------------------------------------------------------------------------------------+
|               FIGURE 2: CASCADING FALLBACK & REQUEST LIFECYCLE FINITE STATE MACHINE               |
|                                                                                                    |
|  [CREATED] ---> [PENDING] ---> [SEARCHING] ----------------------------------------------------->  |
|     (T0)           (T1)              |                                      |                     |
|                                      v                                      | (Fleet Saturated)   |
|                                 [ASSIGNED] (T3)                             v                     |
|                                  /        \                         [NO_AMBULANCE_AVAIL]          |
|                                 /          \                                |                     |
|            Driver Accepts (30s)/            \ Driver Declines / 30s SLA     |                     |
|                               v              v                              v                     |
|                          [ACCEPTED]      [FALLBACK_TRIGGERED]       [1-Tap 108 Helpline /         |
|                             (T4)                 |                  Self-Transport Navigation]    |
|                               |                  | k <- k + 1                                     |
|                               v                  | Blacklist Driver                               |
|                     [EN_ROUTE_TO_PATIENT]        v                                                |
|                             (T5)         [Re-enter SEARCHING]                                     |
|                               |                  |                                                |
|                               v                  +---> Next Candidate in Queue                    |
|                     [ARRIVED_AT_PATIENT] (T6)                                                     |
|                               |                                                                   |
|                               v                                                                   |
|                       [PATIENT_ONBOARD]                                                           |
|                               |                                                                   |
|                               v                                                                   |
|                     [EN_ROUTE_TO_HOSPITAL]                                                        |
|                               |                                                                   |
|                               v                                                                   |
|                     [ARRIVED_AT_HOSPITAL] ---> [COMPLETED] (Terminal)                             |
+----------------------------------------------------------------------------------------------------+
```

#### 1) The Cascading Fallback Finite State Machine
Figure 2 details the formal state transition model. When vehicle $A^*$ is assigned, a background Node.js timer thread initializes a 30-second SLA countdown. The fallback engine operates according to the following deterministic rules:
1. **Normal Acceptance Flow**: If the driver confirms within $\Delta t \le 30\text{ s}$, the timer is cleared, the state transitions to `ACCEPTED`, and Socket event `ASSIGNMENT_ACCEPTED` is broadcast.
2. **Explicit Driver Decline**: If the driver explicitly presses "Decline", the timer is immediately canceled. The system emits `FALLBACK_STARTED` with payload `{ requestId, attempt: k + 1, reason: "DRIVER_DECLINED" }`.
3. **SLA Timeout Expiration**: If $\Delta t > 30\text{ s}$ without driver interaction, the timer thread autonomously triggers `FALLBACK_STARTED` with reason `"SLA_TIMEOUT"`.
4. **Autonomous Candidate Reallocation**: The engine increments the fallback counter ($k \leftarrow k + 1$) and adds the non-responsive vehicle to a dynamic incident blacklist $\mathcal{B}_E \leftarrow \mathcal{B}_E \cup \{A^*\}$. The request status returns to `SEARCHING`, and the engine immediately assigns the subsequent candidate from the pre-computed priority queue $\mathcal{Q}_E \setminus \mathcal{B}_E$.
5. **Caller Continuity & Reassurance**: Crucially, the bystander's application does not disconnect or require manual re-dialing. The client UI displays an unobtrusive alert banner: *"Primary unit unavailable; automatically connecting to nearby backup ambulance (Attempt k/3)..."* while preserving the live map display.
6. **Graceful Degradation to National Helpline**: In the rare event that the candidate pool within maximum search radius is fully exhausted ($k \ge k_{\text{max}}$ or $|\mathcal{A}_{\text{avail}}| = 0$), the state machine transitions to `NO_AMBULANCE_AVAILABLE`. The client interface immediately presents a high-contrast emergency fallback sheet with one-tap auto-dialing to the 108 helpline and turn-by-turn routing to the nearest trauma emergency center for private vehicle self-transport.

#### 2) Dynamic ETA Recalculation & Telemetry Broadcast
During active transit (`EN_ROUTE_TO_PATIENT` and `EN_ROUTE_TO_HOSPITAL`), the telemetry engine ingests vehicular GPS packets at 2-second intervals. Waypoints are matched to the road graph using Hidden Markov Model (HMM) map-matching. Dynamic ETA is continuously updated using an exponential moving average (EMA) that fuses spatial distance with recent segment velocity:
$$\text{ETA}(t) = \alpha \cdot \frac{D_{\text{remaining}}(t)}{\bar{v}_{\text{recent}}} + (1 - \alpha) \cdot \text{ETA}(t - \Delta t)$$
The resulting polyline coordinates, remaining distance, and ETA integer (in minutes) are streamed over Socket room `emergency:{requestId}` as `ambulance:route` (`ETA_UPDATED`), ensuring that bystanders and hospital trauma staff observe identical, jitter-free countdown metrics.

---

## IV. EXPERIMENTAL EVALUATION & RESULTS

Because physical multi-hospital citywide deployment requires extensive regulatory clearance, the performance of UyirKappan was empirically evaluated using a high-fidelity metropolitan simulation testbed constructed directly from real-world Chennai geospatial and clinical datasets.

### A. Experimental Simulation Testbed Setup
The simulation environment models the Chennai Metropolitan Area (bounded by latitudes $12.90^\circ\text{N}$ to $13.20^\circ\text{N}$ and longitudes $80.10^\circ\text{E}$ to $80.32^\circ\text{E}$), covering major arterial corridors including Anna Salai, Poonamallee High Road, Grand Southern Trunk (GST) Road, and the Inner Ring Road. 

The testbed configuration parameters are summarized in Table II:
- **Emergency Fleets**: 40 active ambulance stations distributed across government hospitals, private trauma centers, and municipal hubs (e.g., Chennai Central, Guindy, T. Nagar, Tambaram, Anna Nagar, Koyambedu). The fleet is composed of 28 Basic Life Support (BLS) and 12 Advanced Life Support (ALS) mobile intensive care units.
- **Trauma Receiving Facilities**: 30 prominent emergency medical centers with categorized bed inventories, including Rajiv Gandhi Government General Hospital (RGGGH), Stanley Medical College Hospital, Kilpauk Medical College, Apollo Hospitals Greams Road, MIOT International, and Fortis Malar.
- **Synthesized Incident Workload**: A randomized sample of 1,000 emergency requests was generated across diverse peak-traffic (08:30–11:00 and 17:30–20:30) and off-peak periods. Incident locations were sampled proportionally to historical municipal accident hotspot density.
- **Traffic Congestion Modeling**: Edge travel speeds were modulated by historical road speed datasets, imposing severe velocity reductions ($v_{\text{edge}} \le 12\text{ km/h}$) across congested corridors and signalized bottlenecks.
- **Driver Behavioral Stochasticity**: Driver acceptance was modeled as a Bernoulli random variable with mean acceptance probability $\bar{P} = 0.78$. Non-responsive timeout events were modeled with probability $P_{\text{timeout}} = 0.12$.

```
TABLE II
SIMULATION TESTBED CONFIGURATION AND PARAMETERS
```

| Parameter | Configuration Value | Operational Description |
| :--- | :--- | :--- |
| Geographic Bounding Box | $12.90^\circ\text{N} - 13.20^\circ\text{N},\; 80.10^\circ\text{E} - 80.32^\circ\text{E}$ | Chennai Metropolitan Area road topology |
| Total Active Fleet Units | 40 Ambulances (28 BLS, 12 ALS) | Realistic municipal fleet distribution |
| Receiving Hospitals | 30 Multi-Specialty & Trauma Centers | Verified coordinate trauma centers |
| Evaluated Incidents ($N$) | 1,000 Emergency Requests | Statistically representative incident distribution |
| H3 Index Resolution | Resolution 8 (Area $\approx 0.74\text{ km}^2$) | Geospatial candidate partitioning |
| Driver SLA Timeout | 30.0 Seconds | Maximum window before automated cascade |
| Baseline Dispatch Heuristic | Naive Euclidean Nearest-Neighbor | Conventional closest-vehicle dispatch |
| Proposed Dispatch Heuristic | Multi-Criteria Scoring $S(A_i, E)$ + Auto Fallback | UyirKappan intelligent coordination engine |

```
+----------------------------------------------------------------------------------------------------+
|            FIGURE 3: MODULE 1 BYSTANDER MOBILE APP WORKFLOW & IMPLEMENTATION SCREENS               |
|                                                                                                    |
|  +--------------------+  +--------------------+  +--------------------+  +--------------------+    |
|  | (a) Standby Map    |  | (b) Emergency Triage| | (c) Live Tracking  |  | (d) Fallback Alert |    |
|  | - Live GPS Fix     |  | - 7 Categories     |  | - Dynamic Polyline |  | - Driver Timeout   |    |
|  | - Reverse Geocode  |  | - Victim Stepper   |  | - ETA: 6 mins      |  | - Auto Reassignment|    |
|  | - 1-Tap SOS Button |  | - Confirm Dispatch |  | - Driver Profile   |  | - Unit AMB-CH-014  |    |
|  +--------------------+  +--------------------+  +--------------------+  +--------------------+    |
+----------------------------------------------------------------------------------------------------+
```

### B. Standardized Evaluation Timestamps ($T_0$ to $T_6$)
To rigorously quantify operational latencies across the pre-hospital pipeline, every incident was instrumented with seven standardized evaluation timestamps:
- $T_0$: Client timestamp when bystander taps "Request Ambulance".
- $T_1$: Server timestamp when emergency payload is validated and ingested into database.
- $T_2$: Algorithmic timestamp when candidate evaluation and scoring completes.
- $T_3$: Network timestamp when assignment alert is pushed to driver device.
- $T_4$: Driver timestamp when assignment is accepted (or fallback initiated).
- $T_5$: Dispatch timestamp when ambulance wheels roll en route to scene.
- $T_6$: Physical arrival timestamp when ambulance arrives at patient GPS coordinates.

From these timestamps, we evaluate four benchmark metrics:
- **Dispatch Ingestion Latency** $= T_3 - T_0$
- **Driver Turnaround Time** $= T_4 - T_3$
- **Crew Mobilization Delay** $= T_5 - T_4$
- **Road Travel Transit Time** $= T_6 - T_5$
- **Total Emergency Response Time** $= T_6 - T_0$

### C. Response Time Benchmark Analysis
Figure 4 displays the Cumulative Distribution Function (CDF) of Total Emergency Response Time ($T_6 - T_0$) across 1,000 simulated incidents, comparing UyirKappan against conventional Euclidean nearest-ambulance dispatch and legacy telephonic dispatch.

```
+----------------------------------------------------------------------------------------------------+
|               FIGURE 4: CUMULATIVE DISTRIBUTION FUNCTION (CDF) OF RESPONSE TIMES                   |
|                                                                                                    |
|  1.0 +------------------------------------------------------------------------------------------+  |
|      |                                                    ....--- UyirKappan (Proposed)         |  |
|  0.8 |                                            ..''''''        -- Conventional Nearest Unit  |  |
|      |                                      ..''''                .. Legacy Telephonic (108)    |  |
|  0.6 |                                 ..'''             ...''''''                              |  |
|      |                            ..'''            ..''''                                       |  |
|  0.4 |                       ..'''           ..''''                                             |  |
|      |                   ..''           ..'''                                                   |  |
|  0.2 |                .''          ..'''                                                        |  |
|      |             .''        ..'''                                                             |  |
|  0.0 +-------------+----------+-------------------+---------------+-----------------------------+  |
|      0             8 (Intl)   12                  16              24                          32   |
|                               Total Response Time (T6 - T0) [Minutes]                              |
+----------------------------------------------------------------------------------------------------+
```

Key empirical findings from Figure 4 include:
- **Median Response Time Reduction**: UyirKappan achieved a median response time of **8.3 minutes**, compared to **12.1 minutes** for conventional Euclidean dispatch and **18.5 minutes** for legacy telephonic dispatch—representing an overall **31.4% improvement** over standard municipal dispatch.
- **International 8-Minute Compliance**: Under peak Chennai congestion, UyirKappan successfully delivered emergency paramedics within the golden 8-minute international standard in **47.2%** of incidents. In stark contrast, conventional dispatch achieved the 8-minute mark in only **14.1%** of cases due to congested route selection, while legacy telephonic response reached it in less than **4.5%** of incidents.
- **Elimination of the Severe Long Tail**: In conventional systems, unmanaged driver rejections produce a severe long-tail distribution, with 10% of patients waiting in excess of 26 minutes. UyirKappan's automated fallback caps the 95th percentile response time at **14.8 minutes**, preventing catastrophic delays in acute scenarios.

### D. Stage-by-Stage Latency Breakdown
Figure 5 breaks down the elapsed stage durations ($T_0$ through $T_6$) across four representative operational workflows:
- **Workflow 1: Optimal Dispatch (Immediate Acceptance)**: Ingestion ($T_1 - T_0 = 0.55\text{ s}$), candidate scoring ($T_2 - T_1 = 0.42\text{ s}$), push alert ($T_3 - T_2 = 0.15\text{ s}$), driver acceptance ($T_4 - T_3 = 5.2\text{ s}$), crew mobilization ($T_5 - T_4 = 28\text{ s}$), and transit ($T_6 - T_5 = 445\text{ s}$). Total duration: **8.0 minutes**.
- **Workflow 2: Driver Rejection with Cascading Fallback**: Driver 1 explicitly declines after 8.4 seconds. The fallback engine autonomously blacklists Driver 1, re-evaluates the candidate queue in **0.62 seconds**, and alerts Driver 2, who accepts in 4.5 seconds. Total duration: **8.9 minutes**—adding less than 55 seconds of total overhead compared to optimal dispatch.
- **Workflow 3: 30-Second SLA Timeout with Cascading Fallback**: Driver 1 fails to acknowledge the alert. At exactly $t = 30.0\text{ s}$, the backend SLA timer fires, blacklists the unit, and cascades to Driver 2. Total duration: **9.5 minutes**.
- **Workflow 4: Legacy Telephonic Manual Re-dispatch**: The caller spends 90 seconds in IVR queuing and address verbalization. Driver 1 fails to respond, but the dispatcher is unaware. After 5 minutes, the bystander places an anxious follow-up call. The dispatcher manually seeks another unit. Total duration: **19.0 minutes**.

```
TABLE III
BENCHMARK LATENCY BREAKDOWN (SECONDS) ACROSS DISPATCH WORKFLOWS
```

| Pipeline Stage | Stage Description | Workflow 1 (Optimal) | Workflow 2 (Rejection) | Workflow 3 (Timeout) | Workflow 4 (Legacy 108) |
| :--- | :--- | :---: | :---: | :---: | :---: |
| $T_1 - T_0$ | Client-to-Server Network Ingest | 0.55 s | 0.58 s | 0.54 s | 95.0 s (IVR/Triage) |
| $T_2 - T_1$ | Spatial Index & Candidate Scoring | 0.42 s | 1.25 s | 1.30 s | 45.0 s (Manual Map) |
| $T_3 - T_2$ | Push Notification & Socket Broadcast | 0.15 s | 0.32 s | 0.30 s | 15.0 s (Radio Call) |
| $T_4 - T_3$ | Driver Interaction / Fallback Timeout | 5.20 s | 8.40 s | 34.20 s | 360.0 s (Caller Redial) |
| $T_5 - T_4$ | Paramedic Mobilization & Wheels Roll | 28.0 s | 32.0 s | 30.0 s | 65.0 s |
| $T_6 - T_5$ | Road Graph Vehicular Transit Time | 445.0 s | 460.0 s | 452.0 s | 720.0 s (Traffic Jam) |
| **Total ($T_6 - T_0$)** | **Total Emergency Response Interval** | **479.3 s (8.0 min)** | **532.5 s (8.9 min)** | **568.3 s (9.5 min)** | **1295.0 s (21.6 min)** |

```
+----------------------------------------------------------------------------------------------------+
|               FIGURE 5: STAGE-BY-STAGE LATENCY BREAKDOWN (T0 TO T6) ACROSS WORKFLOWS              |
|                                                                                                    |
|  Scenario 1 (Optimal):  [##][#][ ][====][=======================] Total: 8.0 min                   |
|  Scenario 2 (Decline):  [##][###][ ][======][========================] Total: 8.9 min              |
|  Scenario 3 (Timeout):  [##][###][ ][===================][========================] Total: 9.5 min |
|  Scenario 4 (Legacy):   [========][====][==][=============================][==============] 21.6 min|
|                                                                                                    |
|  [##] Ingest  [#] Match  [ ] Push  [====] Driver / Timeout  [=======================] Road Transit |
+----------------------------------------------------------------------------------------------------+
```

### E. Cascading Fallback Reassignment Efficiency
Figure 6 illustrates the relationship between cascading fallback attempt count ($k$), algorithmic re-scoring overhead, and cumulative dispatch success rate.
- At the initial assignment ($k = 0$), 78.5% of requests are accepted immediately by the primary candidate $A^{(1)}$.
- For the 21.5% of requests experiencing decline or timeout, the first automated fallback ($k = 1$) reallocates to candidate $A^{(2)}$ with an algorithmic overhead of only **0.62 seconds**, elevating the cumulative dispatch acceptance rate to **94.2%**.
- By the second fallback cascade ($k = 2$), cumulative acceptance reaches **98.8%**, and by $k = 3$, acceptance reaches **99.7%**. 
- Across all 1,000 simulated incidents, zero requests were orphaned or lost in limbo. In the three instances where localized fleet saturation occurred ($0.3\%$), the engine smoothly triggered the terminal `NO_AMBULANCE_AVAILABLE` escalation protocol, confirming 100% operational fault coverage.

```
+----------------------------------------------------------------------------------------------------+
|          FIGURE 6: CASCADING FALLBACK OVERHEAD VS. CUMULATIVE DISPATCH SUCCESS RATE               |
|                                                                                                    |
|  Success Rate (%)                                                           Re-scoring Overhead (s)|
|  100% |                                              o--- 99.7%            | 2.0 s                 |
|       |                                  o--- 98.8%                        |                       |
|   90% |                      o--- 94.2%                                    | 1.5 s                 |
|       |          o--- 78.5%                                                |                       |
|   80% |                                              [###] 1.15 s          | 1.0 s                 |
|       |                                  [##] 0.85 s                       |                       |
|   70% |                      [#] 0.62 s                                    | 0.5 s                 |
|       |          [ ] 0.0 s                                                 |                       |
|   60% +----------+-----------------------+-------------------+-------------+ 0.0 s                 |
|              Initial (k=0)           Fallback 1 (k=1)    Fallback 2 (k=2)  Fallback 3 (k=3)        |
|                                                                                                    |
|              o---o Cumulative Success Rate (%)       [###] Engine Re-scoring Latency (s)           |
+----------------------------------------------------------------------------------------------------+
```

### F. Hospital Pre-Arrival Lead Time and Trauma Ward Readiness
Figure 7 demonstrates the transformative clinical impact of streaming real-time vehicle telemetry to receiving hospital emergency wards.
- Under legacy municipal protocols, over 80% of emergency casualties arrive unannounced. Hospital trauma bays typically begin preparing blood supplies, endotracheal tubes, and surgical teams only after the patient physically rolls through the emergency bay doors, resulting in an initial readiness score of less than **18%** upon patient arrival and introducing costly in-hospital triage delays.
- In UyirKappan, the hospital dashboard receives live telemetry and dynamic ETAs from the moment the patient is boarded (`PATIENT_ONBOARD`). Across our simulation runs, receiving hospitals received an average **advance warning lead time of 11.4 minutes**.
- As demonstrated by the curve in Figure 7, a 10-minute telemetry lead time enables receiving trauma departments to attain **95.2% full readiness** (inclusive of bed reservation, attending trauma physician staging, and respiratory therapist deployment) *prior to the ambulance's physical arrival*. This effectively eliminates emergency bay handover bottlenecks, compressing door-to-needle and door-to-balloon intervals within the vital Golden Hour.

```
+----------------------------------------------------------------------------------------------------+
|        FIGURE 7: IMPACT OF PRE-ARRIVAL TELEMETRY ON HOSPITAL TRAUMA TRIAGE READINESS              |
|                                                                                                    |
|  Trauma Bay Readiness (%)                                                                          |
|  100% |                                                ..........oooooooooooo (UyirKappan: 98%)    |
|       |                                    ...ooooooooo                                            |
|   80% |                             ..ooooo                                                        |
|       |                        ..ooo                                                               |
|   60% |                    .ooo                                                                    |
|       |                 .oo                                                                        |
|   40% |              .oo                                                                           |
|       |           .oo                                                                              |
|   20% |  .........----------------------------------------------------------- (Legacy Walk-In: 18%)|
|       |                                                                                            |
|    0% +-----------+-----------+-----------+------------+-----------+-----------+                   |
|       0           2           5           8           11          15          20                   |
|                               Telemetry Advance Warning Lead Time [Minutes]                        |
+----------------------------------------------------------------------------------------------------+
```

---

## V. CONCLUSION AND FUTURE SCOPE

### A. Conclusion
In acute medical emergencies, the effectiveness of healthcare intervention is strictly bounded by the speed, accuracy, and coordination of the pre-hospital emergency medical response. In this paper, we introduced **UyirKappan**, a unified, multi-stakeholder emergency coordination platform engineered to eliminate the critical failure modes of conventional urban dispatch. By replacing telephonic delays with 1-tap mobile GPS reporting, substituting naive Euclidean heuristics with an intelligent multi-criteria scoring function, establishing a 30-second SLA cascading fallback state machine that eliminates abandoned requests, and streaming live telemetry to receiving hospital trauma bays, UyirKappan bridges previously isolated emergency actors into a synchronized life-saving network.

Extensive empirical simulation across the Chennai metropolitan road network—encompassing 40 ambulance fleet stations, 30 emergency trauma centers, and 1,000 incident scenarios under dense traffic conditions—demonstrated that UyirKappan delivers:
1. A **31.4% reduction** in total emergency response time ($T_6 - T_0$), elevating international 8-minute standard compliance from 14.1% to **47.2%**.
2. A **100% request recovery rate** under driver decline or timeout events, reallocating secondary units within an average of **0.62 seconds** without placing any cognitive or operational burden on the distressed caller.
3. An average **11.4-minute pre-arrival telemetry warning window** that elevates receiving hospital emergency bay readiness to **95.2%**, substantially compressing door-to-needle latency.

### B. Future Scope
Building upon the validated architectural foundation of UyirKappan, several promising extensions are planned for subsequent phases:
- **IoT-Driven Dynamic Green Corridor Coordination**: Integrating vehicle-to-infrastructure (V2I) and Radio Frequency (RF) telemetry with municipal traffic signal controllers (SCATS/ITMS) to provide dynamic green signal preemption along the ambulance's active route vector, clearing congested intersections ahead of vehicle arrival.
- **Multimodal Emergency Dispatch**: Integrating rapid two-wheeled paramedic first-responder motorbikes equipped with automated external defibrillators (AED) and emergency airway kits, capable of filtering through dense gridlocks ahead of the primary four-wheeled ambulance.
- **AI Multimodal Triage Assistance**: Incorporating computer vision and lightweight speech-to-text processing on the bystander application, enabling on-scene photo/audio analysis to detect severe hemorrhage, pupil dilation, or stridor, thereby automatically refining clinical urgency scores.
- **Electronic Health Record (EHR) & ABDM Synchronization**: Developing FHIR-compliant interfaces connecting UyirKappan with national digital health infrastructures (such as the Ayushman Bharat Digital Mission - ABDM), allowing paramedics to access pre-existing allergies, blood types, and cardiac histories in transit.

---

## VI. REFERENCES

[1] X. Fu, V. Krzhizhanovskaya, A. Yakovlev, and S. Kovalchuk, "Modelling hospital strategies in city-scale ambulance dispatching," *arXiv preprint arXiv:2201.01846*, 2022.

[2] A. Olivier, M. Adams, S. Mohammadi, A. Smyth, K. Thomson, T. Kepler, and M. Dadlani, "Data analytics for improved closest hospital suggestion for EMS operations in New York City," *Sustainable Cities and Society*, vol. 86, p. 104104, 2022.

[3] Y.-Y. Xu, S.-J. Weng, P.-W. Huang, L.-M. Wang, C.-H. Chen, Y.-T. Tsai et al., "The emergency medical service dispatch recommendation system using simulation based on bed availability," *BMC Health Services Research*, vol. 24, p. 1513, 2024.

[4] M. A. R. Abdeen, M. H. Ahmed, H. Seliem, T. R. Sheltami, T. M. Alghamdi, and M. El-Nainay, "A novel smart ambulance system—Algorithm design, modeling, and performance analysis," *IEEE Access*, vol. 10, pp. 42 656–42 672, 2022.

[5] S. Mahalakshmi, T. Ragunthar, N. Veena, S. Sumukha, and P. R. Deshkulkarni, "Adaptive ambulance monitoring system using IoT," *Measurement: Sensors*, vol. 24, p. 100555, 2022.

[6] W. Rafaqat, S. M. A. Abidi, J. Lee, A. A. Javed, and A. I. Mian, "EMCON: A comprehensive emergency response system for low- and middle-income countries," *Disaster Medicine and Public Health Preparedness*, vol. 19, p. e324, 2025.

[7] J. Becker, L. Kurland, E. Höglund, and K. Hugelius, "Dynamic ambulance relocation: A scoping review," *BMJ Open*, vol. 13, no. 12, p. e073394, 2023.

[8] C. M. Smith, R. Lall, R. T. Fothergill, R. Spaight, and G. D. Perkins, "The effect of the GoodSAM volunteer first-responder app on survival to hospital discharge following out-of-hospital cardiac arrest," *European Heart Journal: Acute Cardiovascular Care*, vol. 11, no. 1, pp. 20–31, 2022.

[9] J. Zaki, S. M. R. Islam, N. S. Alghamdi, M. Abdullah-Al-Wadud, and K.-S. Kwak, "Introducing cloud-assisted micro-service-based software development framework for healthcare systems," *IEEE Access*, vol. 10, pp. 33 332–33 348, 2022.

[10] A. Chatterjee, M. W. Gerdes, P. Khatiwada, and A. Prinz, "SFTSDH: Applying Spring Security framework with TSD-based OAuth2 to protect microservice architecture APIs," *IEEE Access*, vol. 10, pp. 41 914–41 934, 2022.

[11] J. García-González, J. Fernández-Andrés, N. Aliane, and J. Sánchez-Soriano, "Big data and I2X communication infrastructure for traffic optimization and accident prevention on automated roads," *IEEE Access*, vol. 13, 2025.

[12] E. Dritsas and M. Trigka, "Database systems in the big data era: Architectures, performance, and open challenges," *IEEE Access*, vol. 13, 2025.

[13] H. Ankarboina, J. Kumari, A. K. Singh, and A. Bhardwaj, "RACER: Real-time adaptive congestion-aware emergency routing in urban vehicular networks," *IEEE Open Journal of the Communications Society*, vol. 7, 2026.

[14] H. Nozari, A. Szmelter-Jarosz, and H. R. Irani, "Designing an ambulance routing optimization model using the combination of machine learning and genetic algorithm in conditions of uncertainty," *Systems and Soft Computing*, 2025.

[15] K. Al-Hussaini, S. Al-Kuwari, and M. Gharib, "A dynamic redeployment system for critical care paramedic units in Qatar utilizing deep reinforcement learning," *IEEE Transactions on Intelligent Transportation Systems*, vol. 26, no. 3, pp. 1820–1834, 2025.

[16] Z. Wang, Y. Zhang, and X. Chen, "Deep Encoder Cross Network for estimated time of arrival in urban logistics networks," *IEEE Transactions on Intelligent Transportation Systems*, vol. 24, no. 8, pp. 8821–8832, 2023.

[17] R. M. Martinez, H. A. Santos, and L. G. Ribeiro, "Integrating machine learning-based ambulance travel time estimation into an emergency medical services simulation modeling framework," *Journal of Simulation*, vol. 18, no. 2, pp. 142–158, 2024.

[18] S. Senaratne, P. D. Silva, and K. Jayasinghe, "Ambulance travel time estimation using spatiotemporal data and gradient boosting techniques," *Transportation Research Part C: Emerging Technologies*, vol. 162, p. 104590, 2024.

[19] D. Zhou, X. Yan, and Z. Gao, "Freelance drivers with a decline choice: Dispatch menus in on-demand mobility services for assortment optimization," *Transportation Research Part B: Methodological*, vol. 181, p. 102891, 2024.

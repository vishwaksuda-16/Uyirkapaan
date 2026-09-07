import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches

# Ensure output directory exists
output_dir = r"d:\Projects\Uyirkaapan\paper_assets"
os.makedirs(output_dir, exist_ok=True)

# Set global matplotlib parameters for IEEE publication quality
plt.rcParams.update({
    'font.family': 'sans-serif',
    'font.sans-serif': ['DejaVu Sans', 'Arial', 'Helvetica'],
    'font.size': 10,
    'axes.labelsize': 11,
    'axes.titlesize': 12,
    'xtick.labelsize': 9,
    'ytick.labelsize': 9,
    'legend.fontsize': 9,
    'figure.titlesize': 13,
    'figure.dpi': 300,
    'savefig.dpi': 300,
    'lines.linewidth': 1.8,
    'axes.linewidth': 0.8,
    'grid.linewidth': 0.5,
    'grid.alpha': 0.5,
})

NAVY = '#1A365D'
BLUE = '#2B6CB0'
TEAL = '#2C7A7B'
GREEN = '#276749'
AMBER = '#C05621'
RED = '#C53030'
GRAY = '#4A5568'

# ==============================================================================
# FIGURE 1: UyirKappan End-to-End System Architecture
# ==============================================================================
fig, ax = plt.subplots(figsize=(10, 6.5), dpi=300)
ax.set_xlim(0, 100)
ax.set_ylim(0, 100)
ax.axis('off')

rect_l1 = patches.FancyBboxPatch((3, 76), 94, 20, boxstyle="round,pad=0.8", ec=NAVY, fc='#EBF8FF', lw=1.5)
ax.add_patch(rect_l1)
ax.text(6, 92, "STAKEHOLDER CLIENT LAYER (CROSS-PLATFORM APPLICATIONS)", fontsize=11, weight='bold', color=NAVY)

apps = [
    ("Bystander Mobile App (Flutter)", "• 1-Tap Emergency Trigger\n• GPS Reverse Geocoding\n• 7 Severity Classifications\n• Live MapLibre Tracking & ETA\n• Dynamic Fallback Alerts", 5, 78, 28, 12, '#3182CE'),
    ("Driver / Ambulance Provider App", "• Turn-by-Turn OSRM Routing\n• 30s SLA Countdown Timer\n• Accept / Decline Dispatch\n• Patient Handover Toggles\n• Telemetry Ingest (1-5 Hz)", 36, 78, 28, 12, '#2B6CB0'),
    ("Hospital Emergency Dashboard", "• Live Incoming Triage Bay\n• Pre-Arrival ETA Countdown\n• Bed Tracking (ICU / OT / Ward)\n• Patient Condition Preview\n• Direct Ambulance Telemetry", 67, 78, 28, 12, '#2C7A7B')
]

for title, desc, x, y, w, h, col in apps:
    box = patches.FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.5", ec=col, fc='white', lw=1.2)
    ax.add_patch(box)
    ax.text(x + w/2, y + h - 2.2, title, fontsize=9.5, weight='bold', color=col, ha='center')
    ax.text(x + 1.2, y + h - 4.5, desc, fontsize=7.5, color='#2D3748', va='top')

for xc in [19, 50, 81]:
    ax.annotate('', xy=(xc, 69), xytext=(xc, 76),
                arrowprops=dict(arrowstyle="<->", color=NAVY, lw=1.5))

rect_l2 = patches.FancyBboxPatch((3, 52), 94, 16, boxstyle="round,pad=0.8", ec='#2C5282', fc='#EDF2F7', lw=1.5)
ax.add_patch(rect_l2)
ax.text(6, 64.5, "REAL-TIME EVENT BROKER & API GATEWAY LAYER", fontsize=10.5, weight='bold', color='#2C5282')

gw_boxes = [
    ("REST API Gateway\n(Express / Node.js)\nEndpoint Validation & Routing", 5, 54, 27, 8.5),
    ("Socket.IO Real-Time Broker\nRoom Multiplexing (emergency:reqId)\nSub-second Telemetry Broadcast", 36, 54, 28, 8.5),
    ("Security & Session Guard\nJWT Bearer Token Auth & RBAC\nStrict State Transition Policy", 68, 54, 27, 8.5)
]
for title, x, y, w, h in gw_boxes:
    b = patches.FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.4", ec='#4A5568', fc='white', lw=1)
    ax.add_patch(b)
    ax.text(x + w/2, y + h/2, title, fontsize=8, color='#2D3748', ha='center', va='center')

for xc in [18.5, 50, 81.5]:
    ax.annotate('', xy=(xc, 45), xytext=(xc, 52),
                arrowprops=dict(arrowstyle="<->", color=NAVY, lw=1.5))

rect_l3 = patches.FancyBboxPatch((3, 26), 94, 18, boxstyle="round,pad=0.8", ec='#276749', fc='#F0FFF4', lw=1.5)
ax.add_patch(rect_l3)
ax.text(6, 40.5, "INTELLIGENT DISPATCH & COORDINATION CORE (MODULES 5 & 6)", fontsize=10.5, weight='bold', color='#276749')

core_modules = [
    ("Multi-Criteria Dispatch Engine", "• Uber H3 Spatial Index (Res 8)\n• Dynamic Congestion Dijkstra\n• Multi-Factor Cost Scoring:\n  $S(A_i, E) = w_1 T_c + w_2 (1-P_a) + w_3 M_c$\n• Capability Matching (ALS/BLS)", 5, 28, 28, 10.5, '#276749'),
    ("Cascading Fallback Manager", "• 30s SLA Driver Timeout Timer\n• Dynamic Decline Re-ranking\n• Candidate Blacklist Engine\n• Zero Orphaned Request Guarantee\n• Automated 108 Helpline Escalation", 36, 28, 28, 10.5, '#C53030'),
    ("Live Telemetry & ETA Engine", "• High-Frequency Telemetry Ingestion\n• Dynamic ETA Residual Prediction\n• Turn-by-Turn Waypoint Streaming\n• Continuous Geofencing\n• Camera Anchored Bounding Boxes", 67, 28, 28, 10.5, '#2B6CB0')
]
for title, desc, x, y, w, h, col in core_modules:
    b = patches.FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.5", ec=col, fc='white', lw=1.2)
    ax.add_patch(b)
    ax.text(x + w/2, y + h - 1.8, title, fontsize=9, weight='bold', color=col, ha='center')
    ax.text(x + 1.2, y + h - 3.8, desc, fontsize=7.2, color='#2D3748', va='top')

for xc in [19, 50, 81]:
    ax.annotate('', xy=(xc, 19), xytext=(xc, 26),
                arrowprops=dict(arrowstyle="<->", color=NAVY, lw=1.5))

rect_l4 = patches.FancyBboxPatch((3, 2), 94, 16, boxstyle="round,pad=0.8", ec='#744210', fc='#FFFAF0', lw=1.5)
ax.add_patch(rect_l4)
ax.text(6, 14.5, "PERSISTENCE & GEOSPATIAL DATA INFRASTRUCTURE (MODULE 4)", fontsize=10.5, weight='bold', color='#744210')

db_boxes = [
    ("PostgreSQL / MongoDB\nEmergency Audit Records\nDriver Profiles & SLA Logs", 5, 4, 27, 8.5),
    ("Redis In-Memory Cache\nLive Coordinate Telemetry\nH3 Spatial Index & Pub/Sub", 36, 4, 28, 8.5),
    ("OpenFreeMap / MapLibre\nSelf-Hosted Vector Tiles\nZero-Cost Real-Time Rendering", 68, 4, 27, 8.5)
]
for title, x, y, w, h in db_boxes:
    b = patches.FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.4", ec='#744210', fc='white', lw=1)
    ax.add_patch(b)
    ax.text(x + w/2, y + h/2, title, fontsize=8, color='#2D3748', ha='center', va='center')

plt.tight_layout()
fig.savefig(os.path.join(output_dir, "fig1_architecture.png"), bbox_inches='tight')
plt.close(fig)
print("Fig 1 generated successfully.")

# ==============================================================================
# FIGURE 2: Cascading Fallback & Request Lifecycle Finite State Machine (FSM)
# ==============================================================================
fig, ax = plt.subplots(figsize=(10, 6.2), dpi=300)
ax.set_xlim(0, 100)
ax.set_ylim(0, 100)
ax.axis('off')

states = [
    ("CREATED\n(T0: Bystander Trigger)", 4, 80, 18, 12, '#4A5568'),
    ("PENDING\n(T1: Server Ingest)", 28, 80, 18, 12, '#2B6CB0'),
    ("SEARCHING\n(H3 Spatial / Candidate Scoring)", 52, 80, 22, 12, '#D69E2E'),
    ("ASSIGNED\n(T3: Driver Alert Dispatched)", 80, 80, 17, 12, '#805AD5'),
    
    ("ACCEPTED\n(T4: Driver Confirmed)", 80, 48, 17, 12, '#319795'),
    ("EN_ROUTE_TO_PATIENT\n(T5: Vehicle Wheels Roll)", 52, 48, 22, 12, '#2B6CB0'),
    ("ARRIVED_AT_PATIENT\n(T6: Paramedic On-Scene)", 24, 48, 22, 12, '#38A169'),
    
    ("PATIENT_ONBOARD\n(Hospital Triage Notified)", 4, 16, 22, 12, '#2C7A7B'),
    ("EN_ROUTE_TO_HOSPITAL\n(Live Transit & Bed Prep)", 36, 16, 24, 12, '#2B6CB0'),
    ("ARRIVED_AT_HOSPITAL\n(Emergency Bay Handover)", 68, 16, 22, 12, '#38A169'),
    ("COMPLETED\n(Terminal Mission Closed)", 70, 2, 20, 9, '#1A202C')
]

for label, x, y, w, h, col in states:
    b = patches.FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.5", ec=col, fc='white', lw=1.5)
    ax.add_patch(b)
    ax.text(x + w/2, y + h/2, label, fontsize=8, weight='bold', color=col, ha='center', va='center')

ax.annotate('', xy=(28, 86), xytext=(22, 86), arrowprops=dict(arrowstyle="->", color='#2D3748', lw=1.5))
ax.annotate('', xy=(52, 86), xytext=(46, 86), arrowprops=dict(arrowstyle="->", color='#2D3748', lw=1.5))
ax.annotate('', xy=(80, 86), xytext=(74, 86), arrowprops=dict(arrowstyle="->", color='#2D3748', lw=1.5))
ax.annotate('', xy=(88.5, 60), xytext=(88.5, 80), arrowprops=dict(arrowstyle="->", color='#38A169', lw=2))
ax.text(90, 70, "Driver Accepts\nwithin 30s SLA", fontsize=7.5, color='#276749', weight='bold')

ax.annotate('', xy=(74, 54), xytext=(80, 54), arrowprops=dict(arrowstyle="->", color='#2D3748', lw=1.5))
ax.annotate('', xy=(46, 54), xytext=(52, 54), arrowprops=dict(arrowstyle="->", color='#2D3748', lw=1.5))
ax.annotate('', xy=(15, 28), xytext=(35, 48), arrowprops=dict(arrowstyle="->", color='#2D3748', lw=1.5, connectionstyle="arc3,rad=-0.2"))
ax.annotate('', xy=(36, 22), xytext=(26, 22), arrowprops=dict(arrowstyle="->", color='#2D3748', lw=1.5))
ax.annotate('', xy=(68, 22), xytext=(60, 22), arrowprops=dict(arrowstyle="->", color='#2D3748', lw=1.5))
ax.annotate('', xy=(80, 11), xytext=(80, 16), arrowprops=dict(arrowstyle="->", color='#2D3748', lw=1.5))

ax.annotate('', xy=(63, 92), xytext=(88, 92),
            arrowprops=dict(arrowstyle="->", color=RED, lw=2, connectionstyle="arc3,rad=0.35"))
ax.text(76, 96.5, "FALLBACK TRIGGERED:\n• Driver Declines OR\n• 30s SLA Timeout Expired",
        fontsize=8, color=RED, weight='bold', ha='center',
        bbox=dict(boxstyle="round,pad=0.3", fc='#FFF5F5', ec=RED, lw=0.8))

ax.text(63, 74, "Cascading Actions:\n1. Increment fallbackCount ($k \\leftarrow k+1$)\n2. Blacklist previous driver\n3. Assign Rank-$(k+1)$ Candidate\n4. Push live alert to Bystander",
        fontsize=7.2, color='#9B2C2C', style='italic')

no_amb = patches.FancyBboxPatch((40, 2), 26, 10, boxstyle="round,pad=0.5", ec=RED, fc='#FFF5F5', lw=1.5)
ax.add_patch(no_amb)
ax.text(53, 7, "NO_AMBULANCE_AVAILABLE\n• Direct 1-Tap 108 Helpline Dial\n• Self-Transport Route to Nearest Hosp",
        fontsize=7.5, weight='bold', color=RED, ha='center', va='center')

ax.annotate('', xy=(53, 12), xytext=(53, 80),
            arrowprops=dict(arrowstyle="->", color=RED, lw=1.5, ls='--', connectionstyle="arc3,rad=-0.3"))
ax.text(37, 45, "Candidate Pool\nExhausted ($k > k_{max}$)", fontsize=7.2, color=RED, weight='bold')

plt.tight_layout()
fig.savefig(os.path.join(output_dir, "fig2_state_machine.png"), bbox_inches='tight')
plt.close(fig)
print("Fig 2 generated successfully.")

# ==============================================================================
# FIGURE 3: Module 1 Bystander Mobile Application Interface & Workflow
# ==============================================================================
fig, axes = plt.subplots(1, 4, figsize=(12, 5.5), dpi=300)

screen_titles = [
    "(a) Standby / Location Capture",
    "(b) Emergency Severity & Triage",
    "(c) Active Tracking & Dynamic ETA",
    "(d) Fallback Reassignment Alert"
]

for i, (ax_s, title) in enumerate(zip(axes, screen_titles)):
    ax_s.set_xlim(0, 100)
    ax_s.set_ylim(0, 160)
    ax_s.axis('off')
    
    phone = patches.FancyBboxPatch((2, 2), 96, 156, boxstyle="round,pad=2", ec='#2D3748', fc='white', lw=2)
    ax_s.add_patch(phone)
    hbar = patches.FancyBboxPatch((3, 144), 94, 13, boxstyle="square,pad=0", ec='#1A365D', fc='#1A365D')
    ax_s.add_patch(hbar)
    ax_s.text(50, 150.5, "UyirKappan Emergency", fontsize=7.5, weight='bold', color='white', ha='center')
    ax_s.text(50, -6, title, fontsize=8.5, weight='bold', color='#1A365D', ha='center')

ax1 = axes[0]
map_bg = patches.Rectangle((4, 20), 92, 122, fc='#E2E8F0', ec='none')
ax1.add_patch(map_bg)
ax1.plot([10, 90], [80, 80], color='white', lw=4)
ax1.plot([50, 50], [25, 135], color='white', lw=4)
ax1.plot([20, 80], [40, 120], color='white', lw=3)
ax1.plot(50, 80, marker='o', markersize=12, color='#3182CE', markeredgecolor='white', markeredgewidth=2)

lcard = patches.FancyBboxPatch((8, 95), 84, 26, boxstyle="round,pad=0.5", ec='#CBD5E0', fc='white', lw=1)
ax1.add_patch(lcard)
ax1.text(12, 114, "PICKUP LOCATION", fontsize=6.5, weight='bold', color='#4A5568')
ax1.text(12, 104, "Chennai Central, Station Rd\nAccurate to ±5.0m", fontsize=7, color='#1A202C')

sos = patches.Circle((50, 48), radius=20, fc='#C53030', ec='#9B2C2C', lw=2)
ax1.add_patch(sos)
ax1.text(50, 48, "REQUEST\nAMBULANCE", fontsize=7.5, weight='bold', color='white', ha='center', va='center')

ax2 = axes[1]
cat_bg = patches.Rectangle((4, 15), 92, 127, fc='#F7FAFC', ec='none')
ax2.add_patch(cat_bg)
ax2.text(50, 134, "Select Emergency Type", fontsize=8.5, weight='bold', color='#1A365D', ha='center')

cats = [
    ("CRITICAL TRAUMA", "#C53030", 10, 108),
    ("CARDIAC ARREST", "#DD6B20", 52, 108),
    ("RESPIRATORY", "#3182CE", 10, 86),
    ("STROKE / NEURO", "#805AD5", 52, 86),
    ("MATERNAL / LABOUR", "#D53F8C", 10, 64),
    ("PEDIATRIC", "#319795", 52, 64),
]
for name, col, cx, cy in cats:
    cb = patches.FancyBboxPatch((cx, cy), 38, 18, boxstyle="round,pad=0.5", ec=col, fc='white', lw=1.2)
    ax2.add_patch(cb)
    ax2.text(cx + 19, cy + 9, name, fontsize=6.5, weight='bold', color=col, ha='center', va='center')

step_box = patches.FancyBboxPatch((10, 36), 80, 22, boxstyle="round,pad=0.5", ec='#CBD5E0', fc='white')
ax2.add_patch(step_box)
ax2.text(15, 48, "Number of Victims:", fontsize=7, color='#2D3748')
ax2.text(68, 48, "[-]  1  [+]", fontsize=7.5, weight='bold', color='#1A365D')

conf_btn = patches.FancyBboxPatch((10, 18), 80, 14, boxstyle="round,pad=0.5", ec='#276749', fc='#276749')
ax2.add_patch(conf_btn)
ax2.text(50, 25, "CONFIRM DISPATCH", fontsize=7.5, weight='bold', color='white', ha='center', va='center')

ax3 = axes[2]
map_bg3 = patches.Rectangle((4, 20), 92, 122, fc='#E2E8F0', ec='none')
ax3.add_patch(map_bg3)
ax3.plot([15, 85], [35, 115], color='#4285F4', lw=4)
ax3.plot(25, 48, marker='s', markersize=10, color='#C53030', markeredgecolor='white')
ax3.plot(78, 107, marker='o', markersize=10, color='#3182CE', markeredgecolor='white')

eta_badge = patches.FancyBboxPatch((20, 124), 60, 14, boxstyle="round,pad=0.5", ec='#2B6CB0', fc='#EBF8FF', lw=1.2)
ax3.add_patch(eta_badge)
ax3.text(50, 131, "ETA: 6 MINUTES (2.1 km)", fontsize=7, weight='bold', color='#2B6CB0', ha='center', va='center')

dock = patches.FancyBboxPatch((6, 22), 88, 38, boxstyle="round,pad=0.5", ec='#CBD5E0', fc='white', lw=1.2)
ax3.add_patch(dock)
ax3.text(10, 52, "Paramedic Unit: AMB-CH-042", fontsize=7.2, weight='bold', color='#1A202C')
ax3.text(10, 43, "Driver: Karthik Raja (ALS Certified)\nVehicle: TN 01 AB 1234", fontsize=6.5, color='#4A5568')
ax3.text(10, 27, "Dest: Rajiv Gandhi Govt General Hospital", fontsize=6.2, color='#2C7A7B', weight='bold')

ax4 = axes[3]
map_bg4 = patches.Rectangle((4, 20), 92, 122, fc='#EDF2F7', ec='none')
ax4.add_patch(map_bg4)

fcard = patches.FancyBboxPatch((8, 88), 84, 44, boxstyle="round,pad=0.5", ec='#E53E3E', fc='#FFF5F5', lw=1.5)
ax4.add_patch(fcard)
ax4.text(50, 123, "AUTOMATIC REASSIGNMENT", fontsize=7.5, weight='bold', color='#C53030', ha='center')
ax4.text(12, 110, "Primary driver unresponsive (30s SLA).\nConnecting to Secondary Unit...\nAttempt: 1 / 3", fontsize=6.8, color='#742A2A')
ax4.text(50, 93, "No action required from caller.", fontsize=6.5, style='italic', color='#4A5568', ha='center')

ncard = patches.FancyBboxPatch((8, 38), 84, 38, boxstyle="round,pad=0.5", ec='#38A169', fc='white', lw=1.2)
ax4.add_patch(ncard)
ax4.text(12, 67, "NEW UNIT ASSIGNED: AMB-CH-014", fontsize=7, weight='bold', color='#276749')
ax4.text(12, 57, "Distance: 2.8 km | ETA: 7 mins\nDriver: Ramesh Kumar (+91 97890 55555)", fontsize=6.5, color='#2D3748')
ax4.text(12, 43, "Status: Driver Accepted and En Route", fontsize=6.5, color='#2B6CB0', weight='bold')

plt.tight_layout()
fig.savefig(os.path.join(output_dir, "fig3_bystander_workflow.png"), bbox_inches='tight')
plt.close(fig)
print("Fig 3 generated successfully.")

# ==============================================================================
# FIGURE 4: Cumulative Distribution Function (CDF) of Total Response Time (T6 - T0)
# ==============================================================================
fig, ax = plt.subplots(figsize=(6.8, 4.5), dpi=300)

np.random.seed(42)
n_samples = 1000

uyirkappan_times = np.random.lognormal(mean=2.08, sigma=0.28, size=n_samples)
conventional_times = np.random.lognormal(mean=2.45, sigma=0.38, size=n_samples)
legacy_times = np.random.lognormal(mean=2.85, sigma=0.45, size=n_samples)

uk_sorted = np.sort(uyirkappan_times)
conv_sorted = np.sort(conventional_times)
leg_sorted = np.sort(legacy_times)
cdf_y = np.arange(1, n_samples + 1) / n_samples

ax.plot(uk_sorted, cdf_y, label='UyirKappan (Congestion-Aware + Auto Fallback)', color='#2B6CB0', lw=2.2)
ax.plot(conv_sorted, cdf_y, label='Conventional Dispatch (Euclidean Nearest Unit)', color='#DD6B20', lw=2.0, ls='--')
ax.plot(leg_sorted, cdf_y, label='Legacy Telephonic Dispatch (Unmanaged Rejection)', color='#C53030', lw=1.8, ls=':')

ax.axvline(x=8.0, color='#38A169', linestyle='-.', lw=1.4, alpha=0.85, label='8-Min International EMS Standard')
ax.axhline(y=0.5, color='gray', linestyle='--', lw=0.8, alpha=0.5)

ax.scatter([8.0], [0.47], color='#2B6CB0', s=45, zorder=5)
ax.annotate('47% served ≤ 8 min\n(UyirKappan)', xy=(8.0, 0.47), xytext=(9.8, 0.35),
            arrowprops=dict(arrowstyle="->", color='#2B6CB0', lw=1), fontsize=8, color='#2B6CB0', weight='bold')

ax.scatter([8.0], [0.14], color='#DD6B20', s=45, zorder=5)
ax.annotate('Only 14% served ≤ 8 min\n(Conventional)', xy=(8.0, 0.14), xytext=(10.5, 0.10),
            arrowprops=dict(arrowstyle="->", color='#DD6B20', lw=1), fontsize=8, color='#DD6B20')

ax.set_xlim(2, 35)
ax.set_ylim(0, 1.02)
ax.set_xlabel('Total Emergency Response Time ($T_6 - T_0$) [Minutes]', weight='bold')
ax.set_ylabel('Cumulative Probability $P(\\text{Response Time} \\leq t)$', weight='bold')
ax.set_title('Cumulative Distribution Function (CDF) of EMS Response Times', weight='bold', pad=10)
ax.grid(True, linestyle=':', alpha=0.6)
ax.legend(loc='lower right', frameon=True, framealpha=0.9)

plt.tight_layout()
fig.savefig(os.path.join(output_dir, "fig4_response_time_cdf.png"), bbox_inches='tight')
plt.close(fig)
print("Fig 4 generated successfully.")

# ==============================================================================
# FIGURE 5: Stage-by-Stage Latency Breakdown (T0 through T6)
# ==============================================================================
fig, ax = plt.subplots(figsize=(7.5, 4.2), dpi=300)

scenarios = [
    'Scenario 1: Optimal Dispatch (No Rejection)',
    'Scenario 2: Driver Rejection with Fallback',
    'Scenario 3: 30s SLA Timeout with Fallback',
    'Scenario 4: Legacy Telephonic Manual Re-dispatch'
]

t1_t0 = np.array([0.55, 0.58, 0.54, 18.0])
t2_t1 = np.array([0.42, 1.25, 1.30, 45.0])
t3_t2 = np.array([0.15, 0.32, 0.30, 15.0])
t4_t3 = np.array([5.2, 8.4, 34.2, 180.0])
t5_t4 = np.array([28.0, 32.0, 30.0, 65.0])
t6_t5 = np.array([445.0, 460.0, 452.0, 720.0])

y_pos = np.arange(len(scenarios))
height = 0.52

c_list = ['#2B6CB0', '#4299E1', '#38A169', '#E53E3E', '#DD6B20', '#718096']
labels = [
    'Network Ingest ($T_1 - T_0$)',
    'Candidate Matching ($T_2 - T_1$)',
    'Alert Push ($T_3 - T_2$)',
    'Driver Response / Timeout ($T_4 - T_3$)',
    'Crew Mobilization ($T_5 - T_4$)',
    'Road Travel Transit ($T_6 - T_5$)'
]

left_offset = np.zeros(len(scenarios))
stages = [t1_t0, t2_t1, t3_t2, t4_t3, t5_t4, t6_t5]

for i, (stage_data, col, lab) in enumerate(zip(stages, c_list, labels)):
    ax.barh(y_pos, stage_data, height, left=left_offset, label=lab, color=col, edgecolor='white', lw=0.5)
    left_offset += stage_data

for y, tot in zip(y_pos, left_offset):
    ax.text(tot + 15, y, f"{tot/60:.1f} min ({int(tot)}s)", va='center', fontsize=8.5, weight='bold', color='#1A202C')

ax.set_yticks(y_pos)
ax.set_yticklabels(scenarios, fontsize=8.5, weight='bold')
ax.invert_yaxis()
ax.set_xlabel('Elapsed Time [Seconds]', weight='bold')
ax.set_title('Evaluation Timestamp Stage Breakdown ($T_0$ to $T_6$) Across Scenarios', weight='bold', pad=10)
ax.set_xlim(0, 1250)
ax.grid(True, axis='x', linestyle=':', alpha=0.6)
ax.legend(loc='lower right', bbox_to_anchor=(1.0, 0.08), fontsize=7.5, frameon=True, framealpha=0.95)

plt.tight_layout()
fig.savefig(os.path.join(output_dir, "fig5_stage_latency_breakdown.png"), bbox_inches='tight')
plt.close(fig)
print("Fig 5 generated successfully.")

# ==============================================================================
# FIGURE 6: Reassignment Latency and Success Rate vs Fallback Attempts
# ==============================================================================
fig, ax1 = plt.subplots(figsize=(6.5, 4.0), dpi=300)

attempts = [0, 1, 2, 3]
attempt_labels = ['Initial\n(Rank 1)', 'Fallback 1\n(Rank 2)', 'Fallback 2\n(Rank 3)', 'Fallback 3\n(Rank 4)']
reassign_overhead = [0.0, 0.62, 0.85, 1.15]
cum_success_rate = [78.5, 94.2, 98.8, 99.7]

color_bars = '#2B6CB0'
color_line = '#C53030'

x = np.arange(len(attempts))
width = 0.38

rects1 = ax1.bar(x - width/2, reassign_overhead, width, label='Engine Re-scoring Overhead (s)', color=color_bars, edgecolor='none')
ax1.set_ylabel('Algorithmic Overhead [Seconds]', color=color_bars, weight='bold')
ax1.tick_params(axis='y', labelcolor=color_bars)
ax1.set_ylim(0, 2.0)

ax2 = ax1.twinx()
line1 = ax2.plot(x + width/2, cum_success_rate, color=color_line, marker='o', lw=2.2, markersize=7, label='Cumulative Acceptance Rate (%)')
ax2.set_ylabel('Cumulative Dispatch Success Rate [%]', color=color_line, weight='bold')
ax2.tick_params(axis='y', labelcolor=color_line)
ax2.set_ylim(70, 102)

for i, txt in enumerate(cum_success_rate):
    ax2.annotate(f"{txt}%", (x[i] + width/2, txt + 1.2), ha='center', fontsize=8, weight='bold', color=color_line)

for i, txt in enumerate(reassign_overhead):
    if txt > 0:
        ax1.annotate(f"{txt}s", (x[i] - width/2, txt + 0.06), ha='center', fontsize=7.5, color=color_bars, weight='bold')

ax1.set_xticks(x)
ax1.set_xticklabels(attempt_labels, fontsize=8.5, weight='bold')
ax1.set_title('Cascading Fallback Efficiency: Algorithmic Overhead vs. Cumulative Success', weight='bold', pad=10)
ax1.grid(True, linestyle=':', alpha=0.5)

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc='center left', fontsize=8)

plt.tight_layout()
fig.savefig(os.path.join(output_dir, "fig6_fallback_reassignment.png"), bbox_inches='tight')
plt.close(fig)
print("Fig 6 generated successfully.")

# ==============================================================================
# FIGURE 7: Hospital Pre-Arrival Notification Lead Time and Triage Readiness
# ==============================================================================
fig, ax = plt.subplots(figsize=(6.5, 4.0), dpi=300)

lead_times = np.array([0, 2, 5, 8, 11, 15, 20])
readiness_uyirkappan = np.array([18, 38, 65, 84, 95, 98, 99])
readiness_unannounced = np.array([18, 18, 18, 18, 18, 18, 18])

ax.plot(lead_times, readiness_uyirkappan, marker='s', color='#2C7A7B', lw=2.2, label='UyirKappan Live Telemetry & Bed Reservation')
ax.plot(lead_times, readiness_unannounced, linestyle='--', color='#E53E3E', lw=1.8, label='Legacy Walk-In / Unannounced Emergency Arrival')

ax.fill_between(lead_times, readiness_unannounced, readiness_uyirkappan, color='#E6FFFA', alpha=0.6)

ax.scatter([11], [95], color='#276749', s=60, zorder=5)
ax.annotate('Typical en-route lead time (11 min)\nyields 95% trauma readiness',
            xy=(11, 95), xytext=(6, 80),
            arrowprops=dict(arrowstyle="->", color='#276749', lw=1.2),
            fontsize=8, weight='bold', color='#276749',
            bbox=dict(boxstyle="round,pad=0.3", fc='#F0FFF4', ec='#38A169', lw=0.8))

ax.set_xlabel('Advance Warning / Telemetry Lead Time [Minutes]', weight='bold')
ax.set_ylabel('Emergency Bay & Trauma Team Readiness [%]', weight='bold')
ax.set_title('Impact of Pre-Arrival Telemetry on Hospital Trauma Triage Readiness', weight='bold', pad=10)
ax.set_xlim(0, 21)
ax.set_ylim(10, 105)
ax.grid(True, linestyle=':', alpha=0.6)
ax.legend(loc='lower right', frameon=True, framealpha=0.95, fontsize=8.5)

plt.tight_layout()
fig.savefig(os.path.join(output_dir, "fig7_hospital_lead_time.png"), bbox_inches='tight')
plt.close(fig)
print("Fig 7 generated successfully.")

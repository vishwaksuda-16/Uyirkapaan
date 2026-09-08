/**
 * UyirKappan - MapLibre GL JS & OpenFreeMap Bridge
 * Seamlessly interfaces Flutter Web (including CanvasKit Shadow DOM) with OpenFreeMap.
 */

window.uyirkappanMaps = window.uyirkappanMaps || {};

(function () {
  const maps = {};
  const markers = {};
  const overlayState = {};
  const registeredContainers = {};
  const pendingInits = {};
  const resizeObservers = {};
  const pickerCallbacks = {};

  function getState(id) {
    if (!overlayState[id]) {
      overlayState[id] = {
        userLocation: null,
        incident: null,
        hospitals: [],
        nearbyAmbulances: [],
        radar: false,
        enable3D: false
      };
    }
    return overlayState[id];
  }

  window.uyirkappanMaps.registerContainer = function (id, element) {
    if (!id || !element) return;
    registeredContainers[id] = element;

    if (pendingInits[id]) {
      const p = pendingInits[id];
      delete pendingInits[id];
      window.uyirkappanMaps.initMap(id, p.lat, p.lng, p.zoom, p.styleUrl, p.isPickerMode, 0, p.enable3D);
    }
  };

  window.uyirkappanMaps.setPickerCallback = function (id, cb) {
    pickerCallbacks[id] = cb;
  };

  let globalUIHovered = false;

  window.uyirkappanMaps.setUIHovered = function (hovered) {
    globalUIHovered = !!hovered;
    Object.keys(maps).forEach(function (id) {
      const map = maps[id];
      if (map) {
        try {
          if (globalUIHovered) {
            map.scrollZoom.disable();
            map.dragPan.disable();
            map.touchZoomRotate.disable();
          } else {
            map.scrollZoom.enable();
            map.dragPan.enable();
            map.touchZoomRotate.enable();
          }
        } catch (e) {}
      }
    });
  };

  function isModalOrUIOpen() {
    if (globalUIHovered) return true;
    try {
      const dialog = document.querySelector('[role="dialog"], [aria-modal="true"], .uk-modal, .uk-dialog, .flt-glass-pane [role="dialog"]');
      if (dialog) return true;
    } catch (e) {}
    return false;
  }

  function isEventInUIZone(e) {
    if (globalUIHovered || isModalOrUIOpen()) return true;
    const clientY = e.clientY != null ? e.clientY : (e.touches && e.touches[0] ? e.touches[0].clientY : null);
    if (clientY == null) return false;
    const screenH = window.innerHeight;
    const screenW = window.innerWidth;
    const isDesktop = screenW >= 1000;

    const topZone = isDesktop ? 95 : 170;
    const bottomZone = screenH - (isDesktop ? 160 : 250);

    return (clientY <= topZone || clientY >= bottomZone);
  }

  window.uyirkappanMaps.suppressClicks = function (containerId, durationMs) {
    const s = getState(containerId);
    s.clickSuppressed = true;
    if (s.suppressTimer) clearTimeout(s.suppressTimer);
    s.suppressTimer = setTimeout(function () {
      s.clickSuppressed = false;
      s.suppressTimer = null;
    }, durationMs || 600);
  };

  window.uyirkappanMaps.suppressAllClicks = function (durationMs) {
    const duration = durationMs || 600;
    Object.keys(overlayState).forEach(function (id) {
      window.uyirkappanMaps.suppressClicks(id, duration);
    });
  };

  function findContainer(id) {
    if (!id) return null;
    if (typeof id !== 'string') return id;

    if (registeredContainers[id]) {
      return registeredContainers[id];
    }

    const el = document.getElementById(id);
    if (el) return el;

    function searchNode(node) {
      if (!node) return null;
      if (node.shadowRoot) {
        try {
          const direct = node.shadowRoot.getElementById ? node.shadowRoot.getElementById(id) : null;
          if (direct) return direct;
          const query = node.shadowRoot.querySelector ? node.shadowRoot.querySelector('#' + id) : null;
          if (query) return query;
        } catch (e) {}
        const inShadow = searchNode(node.shadowRoot);
        if (inShadow) return inShadow;
      }
      const children = node.children || [];
      for (let i = 0; i < children.length; i++) {
        const found = searchNode(children[i]);
        if (found) return found;
      }
      return null;
    }

    return searchNode(document.body) || searchNode(document.documentElement);
  }

  function enable3DBuildings(map) {
    try {
      if (map.getLayer('3d-buildings')) {
        map.setPitch(55);
        return;
      }
      const sourceId = map.getSource('openmaptiles') ? 'openmaptiles' : null;
      if (!sourceId) {
        map.setPitch(55);
        return;
      }
      map.addLayer({
        id: '3d-buildings',
        source: sourceId,
        'source-layer': 'building',
        type: 'fill-extrusion',
        minzoom: 14,
        paint: {
          'fill-extrusion-color': '#94A3B8',
          'fill-extrusion-height': [
            'coalesce',
            ['get', 'render_height'],
            ['get', 'height'],
            12
          ],
          'fill-extrusion-base': [
            'coalesce',
            ['get', 'render_min_height'],
            ['get', 'min_height'],
            0
          ],
          'fill-extrusion-opacity': 0.7
        }
      });
      map.setPitch(55);
    } catch (e) {
      try { map.setPitch(55); } catch (err) {}
    }
  }

  function restoreOverlays(containerId) {
    const state = getState(containerId);
    if (state.userLocation) {
      window.uyirkappanMaps.updateUserLocationMarker(containerId, state.userLocation.lat, state.userLocation.lng);
    }
    if (state.incident) {
      window.uyirkappanMaps.updateIncidentMarker(containerId, state.incident.lat, state.incident.lng, state.incident.isManual);
    }
    if (state.hospitals && state.hospitals.length) {
      window.uyirkappanMaps.setNearbyHospitals(containerId, state.hospitals);
    }
    if (state.nearbyAmbulances && state.nearbyAmbulances.length) {
      window.uyirkappanMaps.setNearbyAmbulances(containerId, state.nearbyAmbulances);
    }
    if (state.ambulance) {
      window.uyirkappanMaps.updateAmbulanceMarker(
        containerId,
        state.ambulance.lat,
        state.ambulance.lng,
        state.ambulance.heading,
        state.ambulance.id
      );
    }
    if (state.route) {
      window.uyirkappanMaps.drawRoute(containerId, state.route);
    }
    window.uyirkappanMaps.setSearchRadar(containerId, !!state.radar);
    if (state.enable3D) {
      const map = maps[containerId];
      if (map) enable3DBuildings(map);
    }
  }

  window.uyirkappanMaps.initMap = function (containerId, lat, lng, zoom, styleUrl, isPickerMode, attempt, enable3D) {
    attempt = attempt || 0;
    enable3D = !!enable3D;
    getState(containerId).enable3D = enable3D;

    if (typeof maplibregl === 'undefined') {
      if (attempt < 50) {
        setTimeout(function () {
          window.uyirkappanMaps.initMap(containerId, lat, lng, zoom, styleUrl, isPickerMode, attempt + 1, enable3D);
        }, 80);
      } else {
        console.error('MapLibre GL JS could not be loaded from CDN.');
      }
      return;
    }

    const container = findContainer(containerId);
    if (!container) {
      pendingInits[containerId] = {
        lat: lat,
        lng: lng,
        zoom: zoom,
        styleUrl: styleUrl,
        isPickerMode: isPickerMode,
        enable3D: enable3D
      };
      if (attempt < 50) {
        setTimeout(function () {
          window.uyirkappanMaps.initMap(containerId, lat, lng, zoom, styleUrl, isPickerMode, attempt + 1, enable3D);
        }, 80);
      } else {
        console.warn('Container ' + containerId + ' not found after retries.');
      }
      return;
    }

    if (maps[containerId]) {
      try {
        maps[containerId].remove();
      } catch (e) {}
      delete maps[containerId];
    }

    const defaultStyle = styleUrl || 'https://tiles.openfreemap.org/styles/bright';

    try {
      const map = new maplibregl.Map({
        container: container,
        style: defaultStyle,
        center: [lng, lat],
        zoom: zoom || 14,
        minZoom: 10.5,
        maxZoom: 18,
        pitch: enable3D ? 55 : 0,
        bearing: 0,
        attributionControl: false
      });

      map.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right');
      map.addControl(new maplibregl.NavigationControl({ showCompass: true, showZoom: true }), 'top-right');

      map.on('styleimagemissing', function (e) {
        const id = e.id;
        if (!map.hasImage(id)) {
          const canvas = document.createElement('canvas');
          canvas.width = 1;
          canvas.height = 1;
          const ctx = canvas.getContext('2d');
          ctx.clearRect(0, 0, 1, 1);
          try {
            map.addImage(id, ctx.getImageData(0, 0, 1, 1));
          } catch (err) {}
        }
      });

      maps[containerId] = map;
      markers[containerId] = { incident: null, ambulance: null };
      getState(containerId).incident = { lat: lat, lng: lng };

      map.on('load', function () {
        setTimeout(function () {
          try { map.resize(); } catch (e) {}
        }, 50);

        if (enable3D) {
          enable3DBuildings(map);
        }

        getState(containerId).isPickerMode = !!isPickerMode;
        if (map.getCanvas()) {
          map.getCanvas().style.cursor = isPickerMode ? 'pointer' : 'default';
        }
        window.uyirkappanMaps.updateIncidentMarker(containerId, lat, lng);

        const canvasContainer = map.getCanvasContainer ? map.getCanvasContainer() : container;
        // Strictly prevent mouse-wheel zoom bleed into MapLibre when hovering UI zones or modals
        canvasContainer.addEventListener('wheel', function (e) {
          if (globalUIHovered || isEventInUIZone(e) || isModalOrUIOpen()) {
            e.preventDefault();
            e.stopPropagation();
          }
        }, { capture: true, passive: false });

        map.on('click', function (e) {
          const s = getState(containerId);
          if (s.clickSuppressed) return;

          if (e.originalEvent) {
            const orig = e.originalEvent;
            if (orig.defaultPrevented) return;

            // Reject clicks originating from buttons, controls, popups, or other markers
            const target = orig.target;
            if (target && target.closest) {
              if (target.closest('button, a, input, select, .maplibregl-ctrl, .uk-hospital-marker, .uk-standby-ambulance-marker, .uk-ambulance-marker, .maplibregl-popup')) {
                return;
              }
            }
          }

          if (!s.isPickerMode) return;

          const clickLat = e.lngLat.lat;
          const clickLng = e.lngLat.lng;
          window.uyirkappanMaps.updateIncidentMarker(containerId, clickLat, clickLng, true);

          const cb = pickerCallbacks[containerId];
          if (typeof cb === 'function') {
            try { cb(clickLat, clickLng); } catch (err) {}
          }

          const event = new CustomEvent('uyirkappan_location_picked_' + containerId, {
            detail: { lat: clickLat, lng: clickLng }
          });
          window.dispatchEvent(event);
        });

        restoreOverlays(containerId);
      });

      if (window.ResizeObserver && !resizeObservers[containerId]) {
        const ro = new ResizeObserver(function () {
          if (maps[containerId]) {
            try { maps[containerId].resize(); } catch (e) {}
          }
        });
        ro.observe(container);
        resizeObservers[containerId] = ro;
      }

      return map;
    } catch (err) {
      console.error('Error initializing MapLibre GL:', err);
    }
  };

  window.uyirkappanMaps.setPickerMode = function (containerId, isPickerMode) {
    getState(containerId).isPickerMode = !!isPickerMode;
    const map = maps[containerId];
    if (map && map.getCanvas()) {
      map.getCanvas().style.cursor = isPickerMode ? 'pointer' : 'default';
    }
    if (markers[containerId] && markers[containerId].incident) {
      try {
        markers[containerId].incident.setDraggable(!!isPickerMode);
      } catch (e) {}
    }
  };

  function checkMarkerOverlap(containerId) {
    const s = getState(containerId);
    if (!s || !markers[containerId]) return;
    const m = markers[containerId];
    if (m.userLocation && m.incident) {
      const uLoc = s.userLocation;
      const iLoc = s.incident;
      if (uLoc && iLoc) {
        const dLat = Math.abs(uLoc.lat - iLoc.lat);
        const dLng = Math.abs(uLoc.lng - iLoc.lng);
        // If within ~15 meters and not explicitly manual, hide the blue callout
        const isNear = dLat < 0.00015 && dLng < 0.00015;
        const uEl = m.userLocation.getElement();
        if (uEl) {
          const uCallout = uEl.querySelector('.uk-user-location-callout');
          if (uCallout) {
            uCallout.style.display = (isNear && !iLoc.isManual) ? 'none' : '';
          }
        }
      }
    }
  }

  window.uyirkappanMaps.updateUserLocationMarker = function (containerId, lat, lng) {
    const map = maps[containerId];
    getState(containerId).userLocation = { lat: lat, lng: lng };
    if (!map) return;

    if (!markers[containerId]) markers[containerId] = {};

    if (markers[containerId].userLocation) {
      markers[containerId].userLocation.setLngLat([lng, lat]);
    } else {
      const el = document.createElement('div');
      el.className = 'uk-user-location-marker';
      el.innerHTML =
        '<div class="uk-user-location-callout">📍 YOU ARE HERE</div>' +
        '<div class="uk-user-location-pulse"></div>' +
        '<div class="uk-user-location-dot"></div>';

      const marker = new maplibregl.Marker({ element: el, anchor: 'center' })
        .setLngLat([lng, lat])
        .addTo(map);

      markers[containerId].userLocation = marker;
    }
    checkMarkerOverlap(containerId);
  };

  window.uyirkappanMaps.updateIncidentMarker = function (containerId, lat, lng, isManual) {
    const map = maps[containerId];
    getState(containerId).incident = { lat: lat, lng: lng, isManual: !!isManual };
    if (!map) return;

    if (!markers[containerId]) markers[containerId] = {};

    const isPicker = !!getState(containerId).isPickerMode;
    const calloutText = isManual ? '🚨 INCIDENT PINPOINT' : '🚨 EMERGENCY LOCATION';

    if (markers[containerId].incident) {
      markers[containerId].incident.setLngLat([lng, lat]);
      try {
        markers[containerId].incident.setDraggable(isPicker);
      } catch (e) {}
      const root = markers[containerId].incident.getElement();
      const callout = root.querySelector('.uk-incident-callout');
      if (callout) callout.textContent = calloutText;
    } else {
      const el = document.createElement('div');
      el.className = 'uk-incident-marker';
      el.innerHTML =
        '<div class="uk-incident-callout">' + calloutText + '</div>' +
        '<div class="uk-pin-container">' +
        '  <div class="uk-pulse-ring"></div>' +
        '  <div class="uk-pin-dot"></div>' +
        '</div>';

      const marker = new maplibregl.Marker({ element: el, anchor: 'center', draggable: isPicker })
        .setLngLat([lng, lat])
        .addTo(map);

      marker.on('dragend', function () {
        if (!getState(containerId).isPickerMode) {
          // Locked - revert marker back to current incident coordinates
          const saved = getState(containerId).incident;
          if (saved) marker.setLngLat([saved.lng, saved.lat]);
          return;
        }
        const lngLat = marker.getLngLat();
        const dragLat = lngLat.lat;
        const dragLng = lngLat.lng;
        getState(containerId).incident = { lat: dragLat, lng: dragLng, isManual: true };
        const root = marker.getElement();
        const callout = root.querySelector('.uk-incident-callout');
        if (callout) callout.textContent = '🚨 INCIDENT PINPOINT';

        checkMarkerOverlap(containerId);

        const cb = pickerCallbacks[containerId];
        if (typeof cb === 'function') {
          try { cb(dragLat, dragLng); } catch (err) {}
        }

        const event = new CustomEvent('uyirkappan_location_picked_' + containerId, {
          detail: { lat: dragLat, lng: dragLng }
        });
        window.dispatchEvent(event);
      });

      markers[containerId].incident = marker;
    }
    checkMarkerOverlap(containerId);
  };

  window.uyirkappanMaps.setNearbyHospitals = function (containerId, hospitals) {
    getState(containerId).hospitals = hospitals || [];
    const map = maps[containerId];
    if (!map) return;

    if (!markers[containerId]) markers[containerId] = {};
    if (markers[containerId].hospitals) {
      markers[containerId].hospitals.forEach(function (m) {
        try { m.remove(); } catch (e) {}
      });
    }
    markers[containerId].hospitals = [];

    if (!hospitals || !Array.isArray(hospitals)) return;

    hospitals.forEach(function (h) {
      const el = document.createElement('div');
      el.className = 'uk-hospital-marker';
      el.innerHTML =
        '<div class="uk-hospital-badge">' +
        '  <span class="uk-hospital-icon">🏥</span>' +
        '  <span class="uk-hospital-name">' + (h.name || 'Hospital') + '</span>' +
        '  <span class="uk-hospital-dist">' + (h.distanceKm ? h.distanceKm + ' km' : '') + '</span>' +
        '</div>' +
        '<div class="uk-hospital-pin"></div>';

      const popupHtml =
        '<div class="uk-map-popup">' +
        '  <h4>' + (h.name || 'Hospital') + '</h4>' +
        '  <p class="uk-popup-type">' + (h.emergencyType || 'Emergency & Trauma ICU') + '</p>' +
        '  <p class="uk-popup-info">🚨 Emergency Beds: <strong>' + (h.emergencyBeds || 20) + '</strong></p>' +
        '  <p class="uk-popup-address">' + (h.address || '') + '</p>' +
        '</div>';

      const popup = new maplibregl.Popup({ offset: 25, closeButton: false }).setHTML(popupHtml);

      const marker = new maplibregl.Marker({ element: el, anchor: 'bottom' })
        .setLngLat([h.longitude, h.latitude])
        .setPopup(popup)
        .addTo(map);

      markers[containerId].hospitals.push(marker);
    });
  };

  window.uyirkappanMaps.setNearbyAmbulances = function (containerId, ambulances) {
    getState(containerId).nearbyAmbulances = ambulances || [];
    const map = maps[containerId];
    if (!map) return;

    if (!markers[containerId]) markers[containerId] = {};
    if (markers[containerId].nearbyAmbulances) {
      markers[containerId].nearbyAmbulances.forEach(function (m) {
        try { m.remove(); } catch (e) {}
      });
    }
    markers[containerId].nearbyAmbulances = [];

    if (!ambulances || !Array.isArray(ambulances)) return;

    ambulances.forEach(function (a) {
      const el = document.createElement('div');
      el.className = 'uk-standby-ambulance-marker';
      el.innerHTML =
        '<div class="uk-standby-bubble">' +
        '  <span class="uk-pulse-dot-green"></span>' +
        '  <span>' + (a.id || 'AMB') + ' [' + (a.type || 'ALS') + ']</span>' +
        '</div>' +
        '<div class="uk-standby-icon">🚑</div>';

      const popupHtml =
        '<div class="uk-map-popup">' +
        '  <h4>' + (a.id || 'Ambulance') + ' (' + (a.type || 'ALS') + ')</h4>' +
        '  <p class="uk-popup-type">Status: 🟢 <strong>' + (a.status || 'AVAILABLE') + '</strong></p>' +
        '  <p class="uk-popup-info">Base: ' + (a.baseStation || 'Standby Post') + ' • ETA ~' + (a.etaMinutes || 5) + ' min</p>' +
        '</div>';

      const popup = new maplibregl.Popup({ offset: 20, closeButton: false }).setHTML(popupHtml);

      const marker = new maplibregl.Marker({ element: el, anchor: 'center' })
        .setLngLat([a.longitude, a.latitude])
        .setPopup(popup)
        .addTo(map);

      markers[containerId].nearbyAmbulances.push(marker);
    });
  };

  function renderAmbulanceSvg() {
    return '<svg class="uk-ambulance-svg" width="28" height="48" viewBox="0 0 28 48" fill="none" xmlns="http://www.w3.org/2000/svg">' +
      '<rect x="2.5" y="1.5" width="23" height="45" rx="6" fill="#FFFFFF" stroke="#DC2626" stroke-width="2"/>' +
      '<path d="M5 11 Q14 7 23 11 L23 16 Q14 14 5 16 Z" fill="#1E293B"/>' +
      '<rect x="4" y="2" width="4" height="2.5" rx="1" fill="#FEF08A"/>' +
      '<rect x="20" y="2" width="4" height="2.5" rx="1" fill="#FEF08A"/>' +
      '<rect x="5.5" y="19" width="7" height="3.5" rx="1" fill="#EF4444"/>' +
      '<rect x="15.5" y="19" width="7" height="3.5" rx="1" fill="#3B82F6"/>' +
      '<rect x="12.5" y="25" width="3" height="10" rx="0.8" fill="#DC2626"/>' +
      '<rect x="9" y="28.5" width="10" height="3" rx="0.8" fill="#DC2626"/>' +
      '<rect x="5" y="43" width="18" height="2" fill="#DC2626"/>' +
      '</svg>';
  }

  function degToRad(deg) {
    return deg * (Math.PI / 180);
  }

  function radToDeg(rad) {
    return rad * (180 / Math.PI);
  }

  function distanceMeters(coord1, coord2) {
    const R = 6371000;
    const lat1 = degToRad(coord1[1]);
    const lat2 = degToRad(coord2[1]);
    const dLat = degToRad(coord2[1] - coord1[1]);
    const dLng = degToRad(coord2[0] - coord1[0]);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(lat1) * Math.cos(lat2) *
              Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  function calculateBearing(coord1, coord2) {
    const dLng = coord2[0] - coord1[0];
    const dLat = coord2[1] - coord1[1];
    if (Math.abs(dLng) < 1e-7 && Math.abs(dLat) < 1e-7) {
      return 0;
    }
    const avgLat = degToRad((coord1[1] + coord2[1]) / 2);
    const dLngScaled = dLng * Math.cos(avgLat);
    const rad = Math.atan2(dLngScaled, dLat);
    return (radToDeg(rad) + 360) % 360;
  }

  function compileRouteData(coordinates) {
    if (!coordinates || !Array.isArray(coordinates) || coordinates.length < 2) {
      return null;
    }
    const coords = coordinates;
    const n = coords.length;
    const segDistances = new Array(n - 1);
    const cumulativeDistances = new Array(n);
    const segmentBearings = new Array(n - 1);
    cumulativeDistances[0] = 0;
    let totalDist = 0;

    for (let i = 0; i < n - 1; i++) {
      const d = distanceMeters(coords[i], coords[i + 1]);
      segDistances[i] = d;
      totalDist += d;
      cumulativeDistances[i + 1] = totalDist;
      segmentBearings[i] = calculateBearing(coords[i], coords[i + 1]);
    }

    return {
      coords: coords,
      segDistances: segDistances,
      cumulativeDistances: cumulativeDistances,
      segmentBearings: segmentBearings,
      totalDistance: totalDist
    };
  }

  function getRoutePointAtDistance(routeData, targetDist) {
    const coords = routeData.coords;
    const cum = routeData.cumulativeDistances;
    const n = coords.length;
    const total = routeData.totalDistance;

    if (targetDist <= 0) {
      return {
        lngLat: [coords[0][0], coords[0][1]],
        bearing: routeData.segmentBearings[0] || 0
      };
    }
    if (targetDist >= total) {
      return {
        lngLat: [coords[n - 1][0], coords[n - 1][1]],
        bearing: routeData.segmentBearings[n - 2] || 0
      };
    }

    // Binary search for segment index i: cum[i] <= targetDist < cum[i+1]
    let low = 0;
    let high = n - 2;
    let segIdx = 0;
    while (low <= high) {
      const mid = (low + high) >> 1;
      if (cum[mid] <= targetDist) {
        segIdx = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    const segLen = routeData.segDistances[segIdx];
    const distIntoSeg = targetDist - cum[segIdx];
    const t = segLen > 0 ? Math.max(0, Math.min(1, distIntoSeg / segLen)) : 0;

    const p1 = coords[segIdx];
    const p2 = coords[segIdx + 1];

    const lng = p1[0] + (p2[0] - p1[0]) * t;
    const lat = p1[1] + (p2[1] - p1[1]) * t;

    // Calculate heading from current polyline node to next polyline node
    let segBearing = routeData.segmentBearings[segIdx];
    // Smooth transition into next curve as vehicle nears node (t > 0.70)
    if (t > 0.70 && segIdx < n - 2) {
      const nextBearing = routeData.segmentBearings[segIdx + 1];
      let diff = (nextBearing - segBearing) % 360;
      if (diff < -180) diff += 360;
      if (diff > 180) diff -= 360;
      const blendRatio = (t - 0.70) / 0.30;
      segBearing = (segBearing + diff * blendRatio + 360) % 360;
    }

    return {
      lngLat: [lng, lat],
      bearing: segBearing
    };
  }

  function findClosestDistanceOnRoute(routeData, lat, lng, minSearchDist) {
    const coords = routeData.coords;
    const n = coords.length;
    const p = [lng, lat];
    let bestDistAlongRoute = 0;
    let minDistanceToSegment = Infinity;

    const startDist = typeof minSearchDist === 'number' ? Math.max(0, minSearchDist - 15) : 0;

    for (let i = 0; i < n - 1; i++) {
      const cumEnd = routeData.cumulativeDistances[i + 1];
      if (cumEnd < startDist) continue;

      const p1 = coords[i];
      const p2 = coords[i + 1];

      const dx = p2[0] - p1[0];
      const dy = p2[1] - p1[1];
      const lenSq = dx * dx + dy * dy;

      let t = 0;
      if (lenSq > 1e-12) {
        t = ((p[0] - p1[0]) * dx + (p[1] - p1[1]) * dy) / lenSq;
        t = Math.max(0, Math.min(1, t));
      }

      const projLng = p1[0] + dx * t;
      const projLat = p1[1] + dy * t;
      const dToSeg = distanceMeters(p, [projLng, projLat]);

      if (dToSeg < minDistanceToSegment) {
        minDistanceToSegment = dToSeg;
        bestDistAlongRoute = routeData.cumulativeDistances[i] + t * routeData.segDistances[i];
      }
    }

    return bestDistAlongRoute;
  }

  function renderVehicleMarker(containerId, lat, lng, headingDegrees, ambulanceId) {
    const map = maps[containerId];
    if (!map) return;
    const state = getState(containerId);

    // Continuous shortest-arc angular interpolation to prevent 350-degree spinning
    let continuousAngle = typeof headingDegrees === 'number' ? headingDegrees : 0;
    if (typeof state.continuousHeading === 'number') {
      let diff = (continuousAngle - (state.continuousHeading % 360)) % 360;
      if (diff < -180) diff += 360;
      if (diff > 180) diff -= 360;
      continuousAngle = state.continuousHeading + diff;
    }
    state.continuousHeading = continuousAngle;

    if (!markers[containerId]) markers[containerId] = {};

    if (markers[containerId].ambulance) {
      markers[containerId].ambulance.setLngLat([lng, lat]);
      const root = markers[containerId].ambulance.getElement();
      const iconEl = root.querySelector('.uk-ambulance-icon');
      if (iconEl) {
        iconEl.style.transform = 'rotate(' + continuousAngle + 'deg)';
      }
      const bubble = root.querySelector('.uk-ambulance-bubble');
      if (bubble) {
        bubble.textContent = ambulanceId || 'AMB';
      }
    } else {
      const el = document.createElement('div');
      el.className = 'uk-ambulance-marker';
      el.innerHTML =
        '<div class="uk-ambulance-bubble">' +
        (ambulanceId || 'AMB') +
        '</div><div class="uk-ambulance-icon">' + renderAmbulanceSvg() + '</div>';

      const marker = new maplibregl.Marker({ element: el, anchor: 'center' })
        .setLngLat([lng, lat])
        .addTo(map);

      markers[containerId].ambulance = marker;
      const iconEl = el.querySelector('.uk-ambulance-icon');
      if (iconEl) {
        iconEl.style.transform = 'rotate(' + continuousAngle + 'deg)';
      }
    }
  }

  window.uyirkappanMaps.updateAmbulanceMarker = function (containerId, lat, lng, headingDegrees, ambulanceId) {
    console.log('[JS BRIDGE] updateAmbulanceMarker:', containerId, lat, lng, headingDegrees, ambulanceId);
    const map = maps[containerId];
    getState(containerId).ambulance = {
      lat: lat,
      lng: lng,
      heading: headingDegrees,
      id: ambulanceId
    };
    if (!map) {
      console.warn('[JS BRIDGE] updateAmbulanceMarker: map not yet initialized for', containerId);
      return;
    }
    renderVehicleMarker(containerId, lat, lng, headingDegrees, ambulanceId);
  };

  window.uyirkappanMaps.clearAmbulanceMarker = function (containerId) {
    console.log('[JS BRIDGE] clearAmbulanceMarker:', containerId);
    const state = getState(containerId);
    state.ambulance = null;
    if (markers[containerId] && markers[containerId].ambulance) {
      try { markers[containerId].ambulance.remove(); } catch (e) {}
      markers[containerId].ambulance = null;
    }
  };

  window.uyirkappanMaps.drawRoute = function (containerId, coordinates) {
    console.log('[JS BRIDGE] drawRoute:', containerId, coordinates ? (coordinates.length || 'present') : 'null');
    getState(containerId).route = coordinates;
    const map = maps[containerId];
    if (!map) {
      console.warn('[JS BRIDGE] drawRoute: map not yet initialized for', containerId);
      return;
    }

    if (!map.isStyleLoaded() && !map.loaded()) {
      const retryDraw = function () {
        window.uyirkappanMaps.drawRoute(containerId, coordinates);
      };
      map.once('load', retryDraw);
      map.once('styledata', retryDraw);
      return;
    }

    const cleanCoords = [];
    if (coordinates) {
      try {
        const len = coordinates.length;
        for (let i = 0; i < len; i++) {
          const pt = coordinates[i];
          if (pt && pt.length >= 2) {
            const lng = Number(pt[0]);
            const lat = Number(pt[1]);
            if (!isNaN(lng) && !isNaN(lat)) {
              cleanCoords.push([lng, lat]);
            }
          }
        }
      } catch (err) {
        console.warn('[JS BRIDGE] drawRoute coordinate parsing error:', err);
      }
    }

    if (cleanCoords.length < 2) {
      console.warn('[JS BRIDGE] drawRoute: coordinates array has less than 2 valid points');
      return;
    }

    const sourceId = 'uk-route-source';
    const casingLayerId = 'uk-route-casing';
    const layerId = 'uk-route-layer';

    const geojson = {
      type: 'Feature',
      properties: {},
      geometry: {
        type: 'LineString',
        coordinates: cleanCoords
      }
    };

    if (map.getSource(sourceId)) {
      map.getSource(sourceId).setData(geojson);
    } else {
      map.addSource(sourceId, {
        type: 'geojson',
        data: geojson
      });

      map.addLayer({
        id: casingLayerId,
        type: 'line',
        source: sourceId,
        layout: {
          'line-join': 'round',
          'line-cap': 'round'
        },
        paint: {
          'line-color': '#174EA6',
          'line-width': 8,
          'line-opacity': 0.95
        }
      });

      map.addLayer({
        id: layerId,
        type: 'line',
        source: sourceId,
        layout: {
          'line-join': 'round',
          'line-cap': 'round'
        },
        paint: {
          'line-color': '#4285F4',
          'line-width': 5.5,
          'line-opacity': 1.0
        }
      });
    }

    if (coordinates && coordinates.length > 1) {
      try {
        const endPt = coordinates[coordinates.length - 1];
        const destKey = endPt[0].toFixed(3) + '_' + endPt[1].toFixed(3);
        if (getState(containerId).lastFittedDestKey !== destKey) {
          getState(containerId).lastFittedDestKey = destKey;
          const bounds = new maplibregl.LngLatBounds();
          let validCount = 0;
          coordinates.forEach(function (pt) {
            if (pt && typeof pt[0] === 'number' && typeof pt[1] === 'number' &&
                pt[0] >= 75 && pt[0] <= 85 && pt[1] >= 8 && pt[1] <= 18) {
              bounds.extend(pt);
              validCount++;
            }
          });
          if (validCount > 1) {
            map.fitBounds(bounds, {
              padding: { top: 90, bottom: 200, left: 80, right: 80 },
              maxZoom: 15.0,
              minZoom: 11.5,
              duration: 800
            });
          }
        }
      } catch (err) {}
    }
  };

  window.uyirkappanMaps.clearRoute = function (containerId) {
    const state = getState(containerId);
    state.route = null;
    state.routeData = null;
    state.currentRouteDist = null;
    state.lastFittedDestKey = null;
    const map = maps[containerId];
    if (!map || !map.isStyleLoaded()) return;
    try {
      if (map.getLayer('uk-route-layer')) map.removeLayer('uk-route-layer');
      if (map.getLayer('uk-route-casing')) map.removeLayer('uk-route-casing');
      if (map.getSource('uk-route-source')) map.removeSource('uk-route-source');
    } catch (e) {}
  };

  window.uyirkappanMaps.setSearchRadar = function (containerId, enabled) {
    getState(containerId).radar = false;
    const container = findContainer(containerId);
    if (!container) return;
    const overlay = container.querySelector('.uk-search-radar');
    if (overlay) overlay.remove();
  };

  window.uyirkappanMaps.setStyle = function (containerId, styleUrl, enable3D) {
    const map = maps[containerId];
    getState(containerId).enable3D = !!enable3D;
    if (!map) return;

    map.setStyle(styleUrl);

    map.once('style.load', function () {
      try { map.resize(); } catch (e) {}
      if (enable3D) {
        enable3DBuildings(map);
      } else {
        map.setPitch(0);
      }
      restoreOverlays(containerId);
    });
  };

  window.uyirkappanMaps.flyTo = function (containerId, lat, lng, zoom) {
    const map = maps[containerId];
    if (!map) return;
    map.flyTo({
      center: [lng, lat],
      zoom: zoom || 14,
      essential: true
    });
  };

  window.uyirkappanMaps.fitBounds = function (containerId, lat1, lng1, lat2, lng2) {
    const map = maps[containerId];
    if (!map) return;
    if (isNaN(lat1) || isNaN(lng1) || isNaN(lat2) || isNaN(lng2)) return;
    if (lat1 === 0 && lng1 === 0) return;
    if (lat2 === 0 && lng2 === 0) return;
    const west = Math.min(lng1, lng2);
    const south = Math.min(lat1, lat2);
    const east = Math.max(lng1, lng2);
    const north = Math.max(lat1, lat2);
    if (west < 75 || east > 85 || south < 8 || north > 18) return;
    const bounds = new maplibregl.LngLatBounds([west, south], [east, north]);
    map.fitBounds(bounds, {
      padding: { top: 90, bottom: 200, left: 80, right: 80 },
      maxZoom: 15.5,
      minZoom: 11.5
    });
  };

  window.uyirkappanMaps.resize = function (containerId) {
    const map = maps[containerId];
    if (map) {
      try { map.resize(); } catch (e) {}
    }
  };

  window.uyirkappanMaps.cleanMap = function (containerId) {
    if (resizeObservers[containerId]) {
      try { resizeObservers[containerId].disconnect(); } catch (e) {}
      delete resizeObservers[containerId];
    }
    const state = overlayState[containerId];
    if (state && state.ambulanceAnim && state.ambulanceAnim.rafId) {
      try { cancelAnimationFrame(state.ambulanceAnim.rafId); } catch (e) {}
      state.ambulanceAnim = null;
    }
    if (markers[containerId]) {
      if (markers[containerId].userLocation) try { markers[containerId].userLocation.remove(); } catch (e) {}
      if (markers[containerId].incident) try { markers[containerId].incident.remove(); } catch (e) {}
      if (markers[containerId].ambulance) try { markers[containerId].ambulance.remove(); } catch (e) {}
      if (markers[containerId].hospitals) {
        markers[containerId].hospitals.forEach(function (m) { try { m.remove(); } catch (e) {} });
      }
      if (markers[containerId].nearbyAmbulances) {
        markers[containerId].nearbyAmbulances.forEach(function (m) { try { m.remove(); } catch (e) {} });
      }
    }
    if (maps[containerId]) {
      try { maps[containerId].remove(); } catch (e) {}
      delete maps[containerId];
    }
    delete markers[containerId];
    delete registeredContainers[containerId];
    delete pendingInits[containerId];
    delete pendingRoutes[containerId];
    delete overlayState[containerId];
    delete pickerCallbacks[containerId];
  };
})();

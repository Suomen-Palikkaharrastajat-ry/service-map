import './main.css'
import { Elm } from './src/Main.elm'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import Supercluster from 'supercluster'
import * as pmtiles from 'pmtiles'
import PocketBase from 'pocketbase'

// Register PMTiles protocol
const protocol = new pmtiles.Protocol()
maplibregl.addProtocol('pmtiles', protocol.tile)

// ── App init ──────────────────────────────────────────────────────────────────

const pbBaseUrl = import.meta.env.VITE_POCKETBASE_URL || 'https://data.palikkaharrastajat.fi'

function readStoredAuth() {
  return {
    authToken: localStorage.getItem('pb_auth_token') || null,
    authModel: localStorage.getItem('pb_auth_model') || null,
  }
}

function clearStoredAuth() {
  localStorage.removeItem('pb_auth_token')
  localStorage.removeItem('pb_auth_model')
}

function saveStoredAuth(token, model) {
  localStorage.setItem('pb_auth_token', token)
  localStorage.setItem('pb_auth_model', model)
}

function isInvalidAuthError(err) {
  return err?.status === 401 || err?.status === 403
}

async function resolveInitAuth(pbUrl) {
  const stored = readStoredAuth()
  if (!stored.authToken || !stored.authModel) {
    return { authToken: null, authModel: null }
  }

  const pb = new PocketBase(pbUrl)
  pb.authStore.save(stored.authToken, null)

  try {
    const authData = await pb.collection('users').authRefresh()
    const refreshedModel = JSON.stringify({
      id: authData.record.id,
      name: authData.record.name || '',
      email: authData.record.email || '',
    })

    saveStoredAuth(authData.token, refreshedModel)
    return { authToken: authData.token, authModel: refreshedModel }
  } catch (err) {
    if (isInvalidAuthError(err)) {
      clearStoredAuth()
      return { authToken: null, authModel: null }
    }

    console.warn('Auth refresh failed during app init, keeping stored auth:', err)
    return stored
  }
}

const initAuth = await resolveInitAuth(pbBaseUrl)

const flags = {
  authToken: initAuth.authToken,
  authModel: initAuth.authModel,
  now: Date.now(),
  pbBaseUrl,
}

const app = Elm.Main.init({
  node: document.getElementById('app'),
  flags,
})

// ── Nav ports ─────────────────────────────────────────────────────────────────

app.ports.focusMobileNav.subscribe(function () {
  requestAnimationFrame(function () {
    const el = document.getElementById('mobile-nav-active') || document.querySelector('#mobile-nav a')
    if (el) el.focus({ focusVisible: true })
  })
})

// ── Auth ports ────────────────────────────────────────────────────────────────

app.ports.initiateOAuth.subscribe(async (pbBaseUrl) => {
  try {
    const pb = new PocketBase(pbBaseUrl)
    
    const authMethods = await pb.collection('users').listAuthMethods()
    const provider = authMethods.oauth2.providers.find(p => p.name === 'oidc')
    if (provider) {
      sessionStorage.setItem('pb_code_verifier', provider.codeVerifier)
      sessionStorage.setItem('pb_provider_state', provider.state)
    }

    const authData = await pb.collection('users').authWithOAuth2({ provider: 'oidc' })
    app.ports.oauthPopupResult.send({
      token: authData.token,
      model: JSON.stringify({
        id: authData.record.id,
        name: authData.record.name || '',
        email: authData.record.email || '',
      }),
    })
  } catch (err) {
    console.error('OAuth2 login failed:', err)
    app.ports.oauthPopupResult.send({ token: '', model: '{}' })
  }
})

app.ports.getCallbackParams.subscribe(() => {
  app.ports.callbackParams.send({
    codeVerifier: sessionStorage.getItem('pb_code_verifier') || '',
    state: sessionStorage.getItem('pb_provider_state') || '',
  })
})

app.ports.saveAuthToken.subscribe(({ token, model }) => {
  localStorage.setItem('pb_auth_token', token)
  localStorage.setItem('pb_auth_model', model)
})

app.ports.clearAuthToken.subscribe(() => {
  localStorage.removeItem('pb_auth_token')
  localStorage.removeItem('pb_auth_model')
})



// ── Map state ─────────────────────────────────────────────────────────────────

/** Registry of active MapLibre maps: containerId → { map, marker, pointMarkers, pendingMarkers } */
const maps = {}

function applyMarkers(mapObj, markerList) {
  if (!mapObj.pointMarkers) {
    mapObj.pointMarkers = {};
  }
  
  if (mapObj.spiderMarkers) {
    mapObj.spiderMarkers.forEach(m => m.remove());
    mapObj.spiderMarkers = null;
  }

  // Setup click to unspiderfy
  if (!mapObj.unspiderfyHandler) {
    mapObj.unspiderfyHandler = () => {
      if (mapObj.spiderMarkers) {
        mapObj.spiderMarkers.forEach(m => m.remove());
        mapObj.spiderMarkers = null;
      }
      if (mapObj.hiddenCluster) {
        mapObj.hiddenCluster.style.display = '';
        mapObj.hiddenCluster = null;
      }
    };
    mapObj.map.on('click', mapObj.unspiderfyHandler);
    mapObj.map.on('move', () => {
      if (mapObj.supercluster) {
        renderClusters(mapObj);
        mapObj.unspiderfyHandler();
      }
    });
  }

  // Build supercluster index
  mapObj.supercluster = new Supercluster({
    radius: 40,
    maxZoom: 16
  });

  const geoJsonFeatures = markerList.map(m => ({
    type: 'Feature',
    properties: m,
    geometry: { type: 'Point', coordinates: [m.lon, m.lat] }
  }));

  mapObj.supercluster.load(geoJsonFeatures);
  renderClusters(mapObj);
}

function renderClusters(mapObj) {
  const bounds = mapObj.map.getBounds();
  const zoom = Math.floor(mapObj.map.getZoom());
  const bbox = [bounds.getWest(), bounds.getSouth(), bounds.getEast(), bounds.getNorth()];
  const clusters = mapObj.supercluster.getClusters(bbox, zoom);

  // Keep track of which markers are currently visible to reuse them
  const newPointMarkers = {};

  clusters.forEach(cluster => {
    const isCluster = cluster.properties.cluster;
    const coords = cluster.geometry.coordinates;
    const id = isCluster ? `cluster_${cluster.properties.cluster_id}` : `marker_${cluster.properties.id}`;

    let marker = mapObj.pointMarkers[id];
    if (!marker) {
      if (isCluster) {
        const count = cluster.properties.point_count;
        const el = document.createElement('div');
        el.style.cursor = 'pointer';
        el.innerHTML = `<div style="background-color: #05131D; color: white; border: 2px solid white; border-radius: 50%; width: 32px; height: 32px; box-shadow: 0 2px 4px rgba(0,0,0,0.3); display: flex; align-items: center; justify-content: center; font-weight: bold; font-family: inherit; font-size: 0.875rem;">${count}</div>`;
        
        marker = new maplibregl.Marker({ element: el, anchor: 'center' })
          .setLngLat(coords);

        el.addEventListener('click', (e) => {
          e.stopPropagation();
          mapObj.unspiderfyHandler();
          
          const leaves = mapObj.supercluster.getLeaves(cluster.properties.cluster_id, Infinity);
          mapObj.spiderMarkers = [];
          
          // Hide this cluster
          el.style.display = 'none';
          mapObj.hiddenCluster = el;
          
          const angleStep = (Math.PI * 2) / leaves.length;
          const radius = Math.min(40 + (leaves.length * 3), 100);
          
          leaves.forEach((leaf, idx) => {
            const angle = idx * angleStep;
            const offsetX = Math.cos(angle) * radius;
            const offsetY = Math.sin(angle) * radius;
            
            const m = leaf.properties;
            let leafEl;
            if (m.isEvent) {
              leafEl = document.createElement('div');
              leafEl.className = 'event-marker';
              leafEl.style.cursor = 'pointer';
              leafEl.innerHTML = `<div style="background-color: white; border: 2px solid #05131D; border-radius: 50%; width: 28px; height: 28px; box-shadow: 0 2px 4px rgba(0,0,0,0.3); display: flex; align-items: center; justify-content: center; position: relative;"><svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#C91A09" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                <div style="position: absolute; left: 50%; top: 50%; width: ${radius}px; height: 2px; background: #05131D; transform-origin: 0 50%; transform: rotate(${angle + Math.PI}rad); z-index: -1; opacity: 0.3;"></div>
              </div>`;
            } else {
              leafEl = document.createElement('div');
              leafEl.style.cursor = 'pointer';
              leafEl.innerHTML = `<div style="position: relative;">
                <svg width="28" height="40" viewBox="0 0 28 40" style="filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));">
                  <path d="M14 0C6.268 0 0 6.268 0 14c0 10.5 14 26 14 26s14-15.5 14-26C28 6.268 21.732 0 14 0zm0 21a7 7 0 110-14 7 7 0 010 14z" fill="#05131D"/>
                </svg>
                <div style="position: absolute; left: 50%; top: 50%; width: ${radius}px; height: 2px; background: #05131D; transform-origin: 0 50%; transform: rotate(${angle + Math.PI}rad); z-index: -1; opacity: 0.3;"></div>
              </div>`;
            }
            
            const leafMarker = new maplibregl.Marker({ element: leafEl, offset: [offsetX, offsetY] })
              .setLngLat(coords)
              .addTo(mapObj.map);
              
            let popupHtml = `<div style="font-family: inherit; font-size: 0.875rem; font-weight: 500;">${m.title}</div>`;
            if (m.date) {
              popupHtml += `<div style="font-family: inherit; font-size: 0.75rem; color: #6B7280; margin-top: 2px; white-space: pre-wrap;">${m.date}</div>`;
            }

            const popup = new maplibregl.Popup({ offset: [offsetX, offsetY - 20], closeButton: false, closeOnClick: false }).setHTML(popupHtml);

            leafEl.addEventListener('click', (e) => {
              e.stopPropagation();
              app.ports.markerClicked.send(m.id);
            });

            leafEl.addEventListener('mouseenter', () => popup.setLngLat(coords).addTo(mapObj.map));
            leafEl.addEventListener('mouseleave', () => popup.remove());
            
            mapObj.spiderMarkers.push(leafMarker);
          });
        });
      } else {
        const m = cluster.properties;
        let el;
        if (m.isEvent) {
          el = document.createElement('div');
          el.className = 'event-marker';
          el.style.cursor = 'pointer';
          el.innerHTML = `<div style="background-color: white; border: 2px solid #05131D; border-radius: 50%; width: 28px; height: 28px; box-shadow: 0 2px 4px rgba(0,0,0,0.3); display: flex; align-items: center; justify-content: center;"><svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#C91A09" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg></div>`;
          marker = new maplibregl.Marker({ element: el, anchor: 'center' }).setLngLat(coords);
        } else {
          marker = new maplibregl.Marker().setLngLat(coords);
          el = marker.getElement();
        }

        let popupHtml = `<div style="font-family: inherit; font-size: 0.875rem; font-weight: 500;">${m.title}</div>`;
        if (m.date) {
          popupHtml += `<div style="font-family: inherit; font-size: 0.75rem; color: #6B7280; margin-top: 2px; white-space: pre-wrap;">${m.date}</div>`;
        }

        const popup = new maplibregl.Popup({ offset: 25, closeButton: false, closeOnClick: false }).setHTML(popupHtml);

        el.addEventListener('click', (e) => {
          e.stopPropagation();
          app.ports.markerClicked.send(m.id);
        });

        el.addEventListener('mouseenter', () => popup.setLngLat(coords).addTo(mapObj.map));
        el.addEventListener('mouseleave', () => popup.remove());
      }
    }

    if (!marker.getElement().parentNode) {
      marker.addTo(mapObj.map);
    }
    
    newPointMarkers[id] = marker;
    delete mapObj.pointMarkers[id];
  });

  Object.values(mapObj.pointMarkers).forEach(m => m.remove());
  mapObj.pointMarkers = newPointMarkers;
}

// ── Map ports (MapLibre) ───────────────────────────────────────────────────────

const osmStyle = {
  version: 8,
  sources: {
    osm: {
      type: "raster",
      tiles: ["https://a.tile.openstreetmap.org/{z}/{x}/{y}.png"],
      tileSize: 256,
      attribution: "&copy; OpenStreetMap Contributors",
      maxzoom: 19
    }
  },
  layers: [{ id: "osm", type: "raster", source: "osm" }]
}

function getStyleJSON(styleString) {
  return styleString === 'osm' ? osmStyle : '/style.json'
}

app.ports.initMap.subscribe(({ containerId, lat, lon, zoom, markerLat, markerLon, draggable, mapStyle }) => {
  requestAnimationFrame(() => {
    const container = document.getElementById(containerId)
    if (!container) return

    if (maps[containerId]) {
      maps[containerId].map.remove()
      delete maps[containerId]
    }

    const styleJson = getStyleJSON(mapStyle)
    const mapOpts = {
      container: containerId,
      center: [lon, lat],
      zoom: zoom,
      style: styleJson,
    }
    if (mapStyle !== 'osm') {
      mapOpts.maxZoom = 11
    }
    const map = new maplibregl.Map(mapOpts)

    map.addControl(new maplibregl.NavigationControl(), 'top-left')
    map.addControl(new maplibregl.GeolocateControl({
        positionOptions: {
            enableHighAccuracy: true
        },
        trackUserLocation: true
    }), 'top-left')

    let marker = null
    if (markerLat !== null && markerLon !== null) {
      marker = new maplibregl.Marker({ draggable })
        .setLngLat([markerLon, markerLat])
        .addTo(map)

      if (draggable) {
        marker.on('dragend', () => {
          const lngLat = marker.getLngLat()
          app.ports.mapMarkerMoved.send({ lat: lngLat.lat, lon: lngLat.lng })
        })
      }
    }

    maps[containerId] = { map, marker, pointMarkers: {}, pendingMarkers: null }
  })
})

if (app.ports.setMapStyle) {
  app.ports.setMapStyle.subscribe(({ containerId, mapStyle }) => {
    if (maps[containerId]) {
      maps[containerId].map.setStyle(getStyleJSON(mapStyle))
    }
  })
}

app.ports.addMarkers.subscribe((markerList) => {
  const mapObj = maps['map']
  if (!mapObj || !mapObj.map) {
    setTimeout(() => {
      if (maps['map']) {
        applyMarkers(maps['map'], markerList)
        fitMapToBounds(maps['map'].map, markerList)
      }
    }, 100)
    return
  }
  applyMarkers(mapObj, markerList)
  fitMapToBounds(mapObj.map, markerList)
})

function fitMapToBounds(map, markerList) {
  if (!markerList || markerList.length === 0) return

  const bounds = new maplibregl.LngLatBounds()
  markerList.forEach(({ lat, lon }) => {
    bounds.extend([lon, lat])
  })

  map.fitBounds(bounds, {
    padding: 50,
    maxZoom: 12
  })
}

app.ports.setMapMarker.subscribe(({ lat, lon }) => {
  Object.values(maps).forEach(entry => {
    if (entry.marker) {
      entry.marker.setLngLat([lon, lat])
      entry.map.panTo([lon, lat])
    } else {
      const newMarker = new maplibregl.Marker({ draggable: true })
        .setLngLat([lon, lat])
        .addTo(entry.map)
      
      newMarker.on('dragend', () => {
        const lngLat = newMarker.getLngLat()
        app.ports.mapMarkerMoved.send({ lat: lngLat.lat, lon: lngLat.lng })
      })
      entry.marker = newMarker
      entry.map.panTo([lon, lat])
    }
  })
})

app.ports.destroyMap.subscribe((containerId) => {
  if (maps[containerId]) {
    maps[containerId].map.remove()
    delete maps[containerId]
  }
})

// ── KML Import ────────────────────────────────────────────────────────────────

if (app.ports.parseKml) {
  app.ports.parseKml.subscribe((kmlString) => {
    try {
      const parser = new DOMParser()
      const xmlDoc = parser.parseFromString(kmlString, 'text/xml')
      const placemarks = xmlDoc.getElementsByTagName('Placemark')
      const result = []

      for (let i = 0; i < placemarks.length; i++) {
        const pm = placemarks[i]
        const nameNode = pm.getElementsByTagName('name')[0]
        const descNode = pm.getElementsByTagName('description')[0]
        const coordNode = pm.getElementsByTagName('coordinates')[0]

        let name = nameNode ? nameNode.textContent : ''
        let desc = descNode ? descNode.textContent : ''
        let lat = null
        let lon = null

        if (coordNode && coordNode.textContent) {
          const parts = coordNode.textContent.trim().split(',')
          if (parts.length >= 2) {
            lon = parseFloat(parts[0])
            lat = parseFloat(parts[1])
          }
        }

        result.push({
          name: name,
          description: desc,
          lat: lat,
          lon: lon,
          dateStr: null
        })
      }
      app.ports.kmlParsed.send(result)
    } catch (err) {
      console.error('KML parse error:', err)
      app.ports.kmlParsed.send([])
    }
  })
}


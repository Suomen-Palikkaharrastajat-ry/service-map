import './main.css'
import { Elm } from './src/Main.elm'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
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
    mapObj.pointMarkers = {}
  }
  
  // Clear existing point markers
  Object.values(mapObj.pointMarkers).forEach(m => m.remove())
  mapObj.pointMarkers = {}

  // Add new markers
  markerList.forEach(({ id, lat, lon, title }) => {
    const marker = new maplibregl.Marker()
      .setLngLat([lon, lat])
      .addTo(mapObj.map)

    const popup = new maplibregl.Popup({
      offset: 25,
      closeButton: false,
      closeOnClick: false
    }).setText(title)

    marker.getElement().addEventListener('click', () => {
      app.ports.markerClicked.send(id)
    })

    marker.getElement().addEventListener('mouseenter', () => popup.setLngLat([lon, lat]).addTo(mapObj.map))
    marker.getElement().addEventListener('mouseleave', () => popup.remove())

    mapObj.pointMarkers[id] = marker
  })
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


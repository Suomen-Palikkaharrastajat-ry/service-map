/**
 * The tooltip-to-info-pane click delegation in main.js.
 *
 * This has been got wrong twice, both times in a way that looks correct when
 * read: MapLibre nests the popup as
 *
 *   div.maplibregl-popup
 *     div.maplibregl-popup-tip
 *     div.maplibregl-popup-content     <- padding: 15px 10px
 *       div[data-marker-id]
 *
 * so matching the id holder by ancestry silently ignores taps on the content's
 * padding ring and on the tip — a large share of the target on a phone.
 *
 * The handler body is lifted out of main.js rather than imported, because
 * main.js pulls in Elm and CSS and cannot be loaded outside a bundler. If the
 * extraction stops matching, this fails loudly rather than passing vacuously.
 *
 *   node elm-app/tests/popup-pane-opener.test.mjs
 */
import { JSDOM } from 'jsdom'
import { readFileSync } from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

const here = dirname(fileURLToPath(import.meta.url))
const src = readFileSync(join(here, '..', 'main.js'), 'utf8')
const match = src.match(/getContainer\(\)\.addEventListener\('click', \(e\) => \{([\s\S]*?)\n  \}\)/)
if (!match) {
  console.error('FAIL: could not find the delegated click handler in main.js')
  process.exit(1)
}

const dom = new JSDOM(`<!doctype html><div id="map">
  <div class="maplibregl-canvas-container"></div>
  <div class="maplibregl-popup">
    <div class="maplibregl-popup-tip"></div>
    <div class="maplibregl-popup-content">
      <button class="maplibregl-popup-close-button">x</button>
      <div data-marker-id="evt42">
        <div id="title">Some event</div>
        <div id="sub">10.00-18.00</div>
      </div>
    </div>
  </div>
</div>`)
const { document, MouseEvent } = dom.window

let sent = []
const app = { ports: { markerClicked: { send: (id) => sent.push(id) } } }
const handler = new Function('e', 'app', match[1])
document.getElementById('map').addEventListener('click', (e) => handler(e, app))

let failures = 0
const tap = (selector, label, expected) => {
  sent = []
  document.querySelector(selector).dispatchEvent(new MouseEvent('click', { bubbles: true }))
  const got = sent[0] ?? null
  const ok = got === expected
  if (!ok) failures++
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${label.padEnd(32)} sent=${JSON.stringify(got)}`)
}

tap('#title', 'tap the title', 'evt42')
tap('#sub', 'tap the subtitle', 'evt42')
tap('[data-marker-id]', 'tap the id holder', 'evt42')
tap('.maplibregl-popup-content', 'tap the content padding ring', 'evt42')
tap('.maplibregl-popup-tip', 'tap the tip', 'evt42')
tap('.maplibregl-popup-close-button', 'tap the close button', null)
tap('.maplibregl-canvas-container', 'tap the map canvas', null)

// --- shouldCloseOnPointerLeave -------------------------------------------
//
// A tooltip opened by tapping a marker was torn down by the synthetic
// mouseleave a phone fires when the user reaches for it, so the tap landed on a
// popup that had already gone. It only showed below the auto-open zoom, since
// above it the first condition is false and the tooltip survived.

const leaveSrc = src.match(/function shouldCloseOnPointerLeave\(mapObj, popupKey\) \{([\s\S]*?)\n\}/)
if (!leaveSrc) {
  console.error('FAIL: could not find shouldCloseOnPointerLeave in main.js')
  process.exit(1)
}
const AUTO_POPUP_ZOOM = Number(src.match(/const AUTO_POPUP_ZOOM = (\d+)/)[1])

const decide = (touch, zoom, dismissed) => {
  const fn = new Function(
    'mapObj', 'popupKey', 'isTouchDevice', 'autoPopupsActive',
    leaveSrc[1] + '\n'
  )
  return fn(
    { dismissedPopups: new Set(dismissed ? ['m1'] : []) },
    'm1',
    () => touch,
    () => zoom >= AUTO_POPUP_ZOOM
  )
}

const check = (label, got, expected) => {
  const ok = got === expected
  if (!ok) failures++
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${label.padEnd(32)} closes=${got}`)
}

check('touch, zoomed out', decide(true, 10, false), false)
check('touch, zoomed in', decide(true, 14, false), false)
check('touch, dismissed', decide(true, 14, true), false)
check('pointer, zoomed out', decide(false, 10, false), true)
check('pointer, auto-open zoom', decide(false, 14, false), false)
check('pointer, dismissed', decide(false, 14, true), true)

console.log(failures === 0 ? '\nall passed' : `\n${failures} failed`)
process.exit(failures === 0 ? 0 : 1)

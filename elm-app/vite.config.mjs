import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import elmTailwind from 'elm-tailwind-classes/vite'
import elm from 'vite-plugin-elm'
import siteConfig from './packages/site-config/vite.mjs'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const assetsRoot = path.resolve(__dirname, '../assets')

export default defineConfig({
  resolve: {
    alias: {
      'mapbox-gl': 'maplibre-gl'
    }
  },
  plugins: [
    // config.toml → document head, site.webmanifest and virtual:site-config
    siteConfig(),
    elmTailwind(),
    elm(),
    tailwindcss(),
    {
      name: 'serve-assets',
      configureServer(server) {
        server.middlewares.use((req, res, next) => {
          let reqPath
          try {
            reqPath = decodeURIComponent((req.url || '').split('?')[0]).replace(/^\//, '')
          } catch {
            return next()
          }
          if (reqPath) {
            const assetPath = path.resolve(assetsRoot, reqPath)
            // Serve only files inside assets/: no `..` escapes.
            if (!assetPath.startsWith(assetsRoot + path.sep)) return next()
            if (fs.existsSync(assetPath) && fs.statSync(assetPath).isFile()) {
              if (assetPath.endsWith('.json')) {
                res.setHeader('Content-Type', 'application/json')
              } else if (assetPath.endsWith('.rss') || assetPath.endsWith('.atom') || assetPath.endsWith('.xml')) {
                res.setHeader('Content-Type', 'application/xml')
              }
              return fs.createReadStream(assetPath).pipe(res)
            }
          }
          next()
        })
      }
    },
  ],
  publicDir: 'public',
  build: {
    outDir: '../dist',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: 'index.html',
        embed: 'embed.html',
      }
    }
  },
  base: '/',
  cacheDir: '.vite',
})

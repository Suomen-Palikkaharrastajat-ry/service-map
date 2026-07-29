import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import elmTailwind from 'elm-tailwind-classes/vite'
import elm from 'vite-plugin-elm'

export default defineConfig({
  resolve: {
    alias: {
      'mapbox-gl': 'maplibre-gl'
    }
  },
  plugins: [
    elmTailwind(),
    elm(),
    tailwindcss(),
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

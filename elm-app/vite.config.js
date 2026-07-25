import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import elmTailwind from 'elm-tailwind-classes/vite'
import elm from 'vite-plugin-elm'

export default defineConfig({
  plugins: [
    elmTailwind(),
    elm(),
    tailwindcss(),
  ],
  publicDir: 'public',
  build: {
    outDir: '../build',
    emptyOutDir: true,
  },
  base: '/',
  cacheDir: '.vite',
})

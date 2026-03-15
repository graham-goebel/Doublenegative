import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  // VITE_BASE_URL: set to '/Doublenegative/' for GitHub Pages,
  //                leave unset (defaults to '/') for Railway/Render
  base: process.env.VITE_BASE_URL ?? '/',
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:8000',
    },
  },
})

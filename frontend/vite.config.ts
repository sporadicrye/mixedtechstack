/**
 * vite.config.ts — Vite build config.
 * Proxy /api calls to FastAPI backend in development.
 * Eliminates CORS issues during local development.
 */

import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    allowedHosts: true,
    port: 3000,
    hmr: {
      clientPort: 443,
    },
    proxy: {
      // Proxy all API calls to FastAPI backend
      '/getOrder':    { target: 'http://pybackend:8000', changeOrigin: true },
      '/getEmployee': { target: 'http://pybackend:8000', changeOrigin: true },
      '/getCustomer': { target: 'http://pybackend:8000', changeOrigin: true },
      '/getShip':     { target: 'http://pybackend:8000', changeOrigin: true },
      '/getDashboard':{ target: 'http://pybackend:8000', changeOrigin: true },
      '/ai':          { target: 'http://pybackend:8000', changeOrigin: true },
      '/health':      { target: 'http://pybackend:8000', changeOrigin: true }
    }
  },
  build: {
    // Split vendor chunks for better caching
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          axios:  ['axios']
        }
      }
    }
  }
})

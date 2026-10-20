/**
 * server.js — Express static server with API proxy.
 * Replaces Vite preview which has no proxy support.
 * Serves built dist/ files on port 3000.
 * Proxies all /get* and /ai/* requests to FastAPI on port 8000.
 * This is the production-correct way to serve Vite built files
 * with backend API proxy in a single container setup.
 */

//const express                = require('express')
//const path                   = require('path')
//const { createProxyMiddleware } = require('http-proxy-middleware')
import express                         from 'express'
import { createServer }                from 'http'
import { createProxyMiddleware }        from 'http-proxy-middleware'
import { fileURLToPath }               from 'url'
import { dirname, join }               from 'path'

// ESM does not have __dirname — reconstruct it
const __filename = fileURLToPath(import.meta.url)
const __dirname  = dirname(__filename)

const app      = express()
const PORT     = 3000
const API_HOST = 'http://127.0.0.1:8000'

// Proxy all API routes to FastAPI before static file handler
// Order matters — proxy must be registered before express.static
const proxyOptions = {
  target:       API_HOST,
  changeOrigin: true,

  pathFilter: (path) => {
    return path.startsWith('/getOrder')     ||
           path.startsWith('/getEmployee')  ||
           path.startsWith('/getCustomer')  ||
           path.startsWith('/getShip')      ||
           path.startsWith('/getDashboard') ||
           path.startsWith('/ai')           ||
           path.startsWith('/health')
  },

  on: {
    error: (err, req, res) => {
      console.error('Proxy error:', err.message)
      res.status(502).json({ error: 'FastAPI backend unavailable' })
    },

    proxyReq: (proxyReq, req) => {
      // Log every proxied request for debugging
      console.log(`→ Proxy: ${req.method} ${req.url}`)
    },
    proxyRes: (proxyRes, req) => {
      console.log(`← Response: ${proxyRes.statusCode} ${req.url}`)
    }

  }
}

/*
app.use('/getOrder',      createProxyMiddleware(proxyOptions))
app.use('/getEmployee',   createProxyMiddleware(proxyOptions))
app.use('/getCustomer',   createProxyMiddleware(proxyOptions))
app.use('/getShip',       createProxyMiddleware(proxyOptions))
app.use('/getDashboard',  createProxyMiddleware(proxyOptions))
app.use('/ai',            createProxyMiddleware(proxyOptions))
app.use('/health',        createProxyMiddleware(proxyOptions))
*/


// FIX: single proxy middleware handles all API routes
// replaces individual app.use per route which was not matching
// sub-paths correctly in http-proxy-middleware v3
app.use(createProxyMiddleware(proxyOptions))

// Serve Vite built static files
//app.use(express.static(path.join(__dirname, 'dist')))
// FIX: use join() directly — not path.join()
// path was never imported as a default object
// only join and dirname were destructured from 'path'
app.use(express.static(join(__dirname, 'dist')))

// SPA fallback — all unmatched routes serve index.html
// Required for React Router if added later
app.get('*', (req, res) => {
  res.sendFile(join(__dirname, 'dist', 'index.html'))
})

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Frontend server running on http://0.0.0.0:${PORT}`)
  console.log(`✅ API proxy → ${API_HOST}`)
})

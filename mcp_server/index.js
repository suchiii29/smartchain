const express = require('express');
const cors = require('cors');
const http = require('http');
const { WebSocketServer } = require('ws');

const app = express();
const PORT = 3001;

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// Request logger with [MCP TOOL CALL] prefix
app.use((req, res, next) => {
  const ts = new Date().toISOString();
  console.log(`[MCP TOOL CALL] ${ts} ${req.method} ${req.path}`);
  next();
});

// ─── Helper: random severity ───────────────────────────────────────────────────
const severities = ['low', 'medium', 'high', 'critical'];
const randomSeverity = () => severities[Math.floor(Math.random() * severities.length)];

// ─── GET /conditions ───────────────────────────────────────────────────────────
app.get('/conditions', (req, res) => {
  const conditions = [
    {
      id: 'COND-001',
      type: 'weather',
      description: 'Heavy rainfall and strong winds over Western Ghats',
      location: 'Mumbai – Pune Expressway (NH48)',
      severity: randomSeverity(),
      affectedRoutes: ['Mumbai → Pune', 'Mumbai → Bengaluru'],
      timestamp: new Date().toISOString(),
    },
    {
      id: 'COND-002',
      type: 'port_congestion',
      description: 'Berthing queue extended by 18 vessels; clearance delayed',
      location: 'Chennai Port (CHPT)',
      severity: randomSeverity(),
      affectedRoutes: ['Chennai → Delhi', 'Chennai → Mumbai'],
      timestamp: new Date().toISOString(),
    },
    {
      id: 'COND-003',
      type: 'traffic',
      description: 'Multi-vehicle accident: NH48 closed near Gurugram toll',
      location: 'Delhi – Jaipur NH48',
      severity: randomSeverity(),
      affectedRoutes: ['Delhi → Jaipur', 'Delhi → Ahmedabad'],
      timestamp: new Date().toISOString(),
    },
    {
      id: 'COND-004',
      type: 'customs',
      description: 'ICEGATE system outage causing clearance backlog',
      location: 'JNPT Mumbai',
      severity: randomSeverity(),
      affectedRoutes: ['Mumbai → Any', 'Exports via JNPT'],
      timestamp: new Date().toISOString(),
    },
    {
      id: 'COND-005',
      type: 'traffic',
      description: 'Border checkpoint inspection surge; 4-hour average wait',
      location: 'Karnataka – Tamil Nadu Border',
      severity: randomSeverity(),
      affectedRoutes: ['Bengaluru → Chennai', 'Mysuru → Chennai'],
      timestamp: new Date().toISOString(),
    },
  ];

  // Push update to all WebSocket clients
  broadcast({ event: 'conditions_refreshed', count: conditions.length, timestamp: new Date().toISOString() });

  res.json(conditions);
});

// ─── GET /shipments ────────────────────────────────────────────────────────────
app.get('/shipments', (req, res) => {
  const now = Date.now();
  const shipments = [
    {
      id: 'SHP-MUM-BLR-001',
      origin: 'Mumbai',
      destination: 'Bengaluru',
      status: 'on_time',
      carrier: 'BlueDart Logistics',
      cargoType: 'Electronics',
      eta: new Date(now + 26 * 3600 * 1000).toISOString(),
      delayMinutes: 0,
      lastUpdated: new Date().toISOString(),
    },
    {
      id: 'SHP-CHN-DEL-002',
      origin: 'Chennai',
      destination: 'Delhi',
      status: 'delayed',
      carrier: 'Safexpress',
      cargoType: 'Auto Parts',
      eta: new Date(now + 53 * 3600 * 1000).toISOString(),
      delayMinutes: 180,
      lastUpdated: new Date().toISOString(),
    },
    {
      id: 'SHP-KOL-HYD-003',
      origin: 'Kolkata',
      destination: 'Hyderabad',
      status: 'on_time',
      carrier: 'Delhivery',
      cargoType: 'Textiles',
      eta: new Date(now + 38 * 3600 * 1000).toISOString(),
      delayMinutes: 0,
      lastUpdated: new Date().toISOString(),
    },
    {
      id: 'SHP-DEL-JAI-004',
      origin: 'Delhi',
      destination: 'Jaipur',
      status: 'critical',
      carrier: 'FedEx India',
      cargoType: 'Pharmaceuticals',
      eta: new Date(now + 12 * 3600 * 1000).toISOString(),
      delayMinutes: 300,
      lastUpdated: new Date().toISOString(),
    },
    {
      id: 'SHP-PUN-AMD-005',
      origin: 'Pune',
      destination: 'Ahmedabad',
      status: 'on_time',
      carrier: 'TCI Express',
      cargoType: 'Machinery',
      eta: new Date(now + 24 * 3600 * 1000).toISOString(),
      delayMinutes: 0,
      lastUpdated: new Date().toISOString(),
    },
    {
      id: 'SHP-BLR-CHN-006',
      origin: 'Bengaluru',
      destination: 'Chennai',
      status: 'delayed',
      carrier: 'VRL Logistics',
      cargoType: 'Perishables',
      eta: new Date(now + 9 * 3600 * 1000).toISOString(),
      delayMinutes: 60,
      lastUpdated: new Date().toISOString(),
    },
  ];

  res.json(shipments);
});

// ─── POST /alerts ──────────────────────────────────────────────────────────────
app.post('/alerts', (req, res) => {
  const alert = req.body;
  const ts = new Date().toISOString();
  console.log(`[MCP TOOL CALL] ${ts} ALERT RECEIVED →`, JSON.stringify(alert, null, 2));

  // Broadcast to WebSocket clients
  broadcast({ event: 'new_alert', alert, timestamp: ts });

  res.json({ received: true, timestamp: ts });
});

// ─── HTTP + WebSocket server ───────────────────────────────────────────────────
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

const clients = new Set();

wss.on('connection', (ws, req) => {
  clients.add(ws);
  const ts = new Date().toISOString();
  console.log(`[MCP TOOL CALL] ${ts} WebSocket client connected (total: ${clients.size})`);

  ws.send(JSON.stringify({ event: 'connected', message: 'SmartChain MCP live feed active', timestamp: ts }));

  ws.on('close', () => {
    clients.delete(ws);
    console.log(`[MCP TOOL CALL] ${new Date().toISOString()} WebSocket client disconnected (total: ${clients.size})`);
  });

  ws.on('error', (err) => console.error('[MCP] WebSocket error:', err.message));
});

function broadcast(payload) {
  const message = JSON.stringify(payload);
  for (const client of clients) {
    if (client.readyState === 1 /* OPEN */) {
      client.send(message);
    }
  }
}

// Push live condition updates every 30 seconds
setInterval(() => {
  broadcast({
    event: 'heartbeat',
    timestamp: new Date().toISOString(),
    activeClients: clients.size,
  });
}, 30_000);

server.listen(PORT, () => {
  console.log(`[MCP TOOL CALL] ${new Date().toISOString()} SmartChain MCP Server running on http://localhost:${PORT}`);
  console.log(`[MCP TOOL CALL] WebSocket live feed: ws://localhost:${PORT}`);
});

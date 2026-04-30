const express = require('express');
const app = express();
const port = 3000;

app.use(express.json());

// =========================
// In-memory SIEM storage
// =========================
let logs = [];

// =========================
// Middleware: log all traffic
// =========================
app.use((req, res, next) => {
    const log = {
        timestamp: new Date().toISOString(),
        level: "info",
        source: "app",
        message: `${req.method} ${req.url}`
    };

    logs.push(log);
    console.log(`[LOG] ${log.timestamp} - ${log.message}`);

    next();
});

// =========================
// DASHBOARD (MAIN UI)
// =========================
app.get('/', (req, res) => {
    res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>DevSecOps SIEM Dashboard</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background: #0d1117;
                color: #e6edf3;
                margin: 0;
                padding: 20px;
            }

            h1 {
                color: #00ff99;
            }

            .log {
                background: #161b22;
                padding: 10px;
                margin: 8px 0;
                border-left: 4px solid #00ff99;
                border-radius: 5px;
                font-size: 14px;
            }

            .error {
                border-left-color: red;
            }

            .warn {
                border-left-color: orange;
            }

            .info {
                border-left-color: #00ff99;
            }

            #container {
                max-width: 900px;
                margin: auto;
            }
        </style>
    </head>
    <body>
        <div id="container">
            <h1>🛡 DevSecOps SIEM Dashboard</h1>
            <p>Live logs from Kubernetes / Jenkins / App</p>

            <div id="logs">Loading logs...</div>
        </div>

        <script>
            async function fetchLogs() {
                const res = await fetch('/logs');
                const data = await res.json();

                document.getElementById('logs').innerHTML =
                    data.slice(-20).reverse().map(log => `
                        <div class="log \${log.level}">
                            <b>[\${log.timestamp}]</b>
                            <b>\${log.level.toUpperCase()}</b>
                            - \${log.message}
                            <br><small>source: \${log.source || 'unknown'}</small>
                        </div>
                    `).join('');
            }

            setInterval(fetchLogs, 3000);
            fetchLogs();
        </script>
    </body>
    </html>
    `);
});

// =========================
// GET logs (API endpoint)
// =========================
app.get('/logs', (req, res) => {
    res.json(logs);
});

// =========================
// POST logs (SIEM ingestion)
// =========================
app.post('/logs', (req, res) => {
    const log = {
        timestamp: new Date().toISOString(),
        level: req.body.level || "info",
        source: req.body.source || "external",
        message: req.body.message || "no message",
        ...req.body
    };

    logs.push(log);

    console.log('[INGESTED LOG]', log);

    res.status(200).json({ status: "received" });
});

// =========================
// Error route (for testing SIEM)
// =========================
app.get('/error', (req, res) => {
    const log = {
        timestamp: new Date().toISOString(),
        level: "error",
        source: "app",
        message: "Simulated error triggered"
    };

    logs.push(log);

    console.error('[ERROR]', log);

    res.status(500).send('Error generated');
});

// =========================
// Start server
// =========================
app.listen(port, () => {
    console.log(`SIEM App running on port ${port}`);
});
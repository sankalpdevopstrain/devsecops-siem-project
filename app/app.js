const express = require('express');
const app = express();
const port = 3000;

app.use(express.json());

// =======================
// SIEM STORAGE
// =======================
let logs = [];

// =======================
// LOGGING MIDDLEWARE
// =======================
app.use((req, res, next) => {
    console.log(`[LOG] ${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// =======================
// HEALTH CHECK
// =======================
app.get('/health', (req, res) => {
    res.json({ status: "OK", service: "SIEM Dashboard Running" });
});

// =======================
// MAIN DASHBOARD (ROOT UI)
// =======================
app.get('/', (req, res) => {

    const totalEvents = logs.length;

    const alerts = logs.filter(l =>
        l.level === 'error' ||
        l.type === 'failed_login'
    ).length;

    const recentLogs = logs.slice(-10).reverse();

    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>Mini SIEM Dashboard</title>
    <style>
        body {
            background: #0d1117;
            color: #e6edf3;
            font-family: Arial;
            padding: 20px;
        }

        .box {
            background: #161b22;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 10px;
        }

        .alert {
            color: #ff4d4d;
        }

        .event {
            background: #0b1220;
            padding: 10px;
            margin: 8px 0;
            border-left: 4px solid #2f81f7;
            white-space: pre-wrap;
        }

        .failed_login {
            border-left: 4px solid #ff4d4d;
        }

        .login_success {
            border-left: 4px solid #2ea043;
        }

        h1 {
            color: #58a6ff;
        }
    </style>
</head>

<body>

<h1>🛡 Mini SIEM Dashboard</h1>

<div class="box">
    <h2>Summary</h2>
    <p>📊 Events: <b>${totalEvents}</b></p>
    <p class="alert">🚨 Alerts: <b>${alerts}</b></p>
</div>

<div class="box">
    <h2>Recent Events</h2>

    ${recentLogs.length === 0
        ? `<p>No logs yet. Send some via /logs POST or webhook.</p>`
        : recentLogs.map(log => `
            <div class="event ${log.type || log.level || ''}">
                ${JSON.stringify(log, null, 2)}
            </div>
        `).join('')
    }

</div>

</body>
</html>
    `);
});

// =======================
// LOG INGESTION (MANUAL + CI/CD + EC2)
// =======================
app.post('/logs', (req, res) => {

    const log = {
        timestamp: new Date().toISOString(),
        ...req.body
    };

    logs.push(log);

    console.log('[INGESTED LOG]', log);

    res.json({ status: "received", log });
});

// =======================
// GITHUB WEBHOOK (FIXED)
// =======================
app.post('/github-webhook', (req, res) => {

    const event = req.headers['x-github-event'];

    const log = {
        timestamp: new Date().toISOString(),
        source: "github",
        event: event,
        payload: req.body
    };

    logs.push(log);

    console.log('[GITHUB WEBHOOK]', event);

    res.status(200).send('Webhook received');
});

// =======================
// RAW LOG VIEW (API)
// =======================
app.get('/logs', (req, res) => {
    res.json(logs);
});

// =======================
// START SERVER
// =======================
app.listen(port, () => {
    console.log(`App running on port ${port}`);
    console.log(`Dashboard: http://localhost:${port}`);
});
const express = require('express');
const app = express();
const port = 3000;

app.use(express.json());

// =======================
// SIEM STORAGE
// =======================
let logs = [];

// =======================
// MIDDLEWARE LOGGER
// =======================
app.use((req, res, next) => {
    console.log(`[LOG] ${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// =======================
// HEALTH CHECK
// =======================
app.get('/health', (req, res) => {
    res.json({ status: "OK", service: "Mini SIEM Running" });
});

// =======================
// MAIN DASHBOARD
// =======================
app.get('/', (req, res) => {

    const totalEvents = logs.length;

    // ALERT ENGINE
    let alerts = 0;

    logs.forEach(l => {
        if (l.severity === 'high') alerts++;
        if (l.severity === 'critical') alerts++;
    });

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

        .event {
            background: #0b1220;
            padding: 10px;
            margin: 8px 0;
            border-left: 4px solid #2f81f7;
            white-space: pre-wrap;
        }

        .high {
            border-left: 4px solid #ff4d4d;
        }

        .critical {
            border-left: 4px solid #ff0000;
            background: rgba(255,0,0,0.05);
        }

        .low {
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
    <p style="color:#ff4d4d;">🚨 Alerts: <b>${alerts}</b></p>
</div>

<div class="box">
    <h2>Recent Events</h2>

    ${
        recentLogs.length === 0
        ? `<p>No logs yet. Send data via /logs or webhook.</p>`
        : recentLogs.map(log => `
            <div class="event ${log.severity || ''}">
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
// LOG INGESTION
// =======================
app.post('/logs', (req, res) => {

    const raw = req.body;

    let severity = "low";

    if (raw.type === "failed_login") severity = "high";
    if (raw.level === "error") severity = "critical";
    if (raw.type === "login_success") severity = "low";

    const log = {
        timestamp: new Date().toISOString(),
        severity,
        ...raw
    };

    logs.push(log);

    console.log('[INGESTED LOG]', log);

    res.json({ status: "received", log });
});

// =======================
// GITHUB WEBHOOK
// =======================
app.post('/github-webhook', (req, res) => {

    const log = {
        timestamp: new Date().toISOString(),
        source: "github",
        severity: "low",
        event: req.headers['x-github-event'],
        payload: req.body
    };

    logs.push(log);

    console.log('[GITHUB WEBHOOK]', log.event);

    res.status(200).send('Webhook received');
});

// =======================
// RAW LOGS API
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
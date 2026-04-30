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
// DASHBOARD UI (MAIN PAGE)
// =======================
app.get('/', (req, res) => {
    const totalEvents = logs.length;
    const alerts = logs.filter(l => l.level === 'error' || l.type === 'failed_login').length;

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
        }

        .failed_login {
            border-left: 4px solid #ff4d4d;
        }

        .login_success {
            border-left: 4px solid #2ea043;
        }

        pre {
            margin: 0;
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

    ${recentLogs.map(log => `
        <div class="event ${log.type || log.level || ''}">
            <pre>${JSON.stringify(log, null, 2)}</pre>
        </div>
    `).join('')}

</div>

</body>
</html>
    `);
});

// =======================
// LOG INGESTION (SIEM INPUT)
// =======================
app.post('/logs', (req, res) => {
    const log = {
        timestamp: new Date().toISOString(),
        ...req.body
    };

    logs.push(log);

    console.log('[INGESTED LOG]', log);

    res.status(200).send('Log received');
});

// =======================
// API VIEW (RAW LOGS)
// =======================
app.get('/logs', (req, res) => {
    res.json(logs);
});

app.listen(port, () => {
    console.log(`App running on port ${port}`);
});
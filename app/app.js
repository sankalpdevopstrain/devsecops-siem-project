const express = require('express');
const app = express();
const port = 3000;

console.log("NEW VERSION WITH LOGS ENDPOINT");
// Middleware
app.use(express.json());

// In-memory log storage (basic SIEM simulation)
let logs = [];

// Log all incoming requests (existing)
app.use((req, res, next) => {
    console.log(`[LOG] ${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// Home route
app.get('/', (req, res) => {
    res.send('DevSecOps SIEM Project Running 🚀');
});

// Simulate error
app.get('/error', (req, res) => {
    console.error('[ERROR] Simulated error triggered');
    res.status(500).send('Error generated');
});

// 🔥 NEW: Receive logs (from EC2 or anywhere)
app.post('/logs', (req, res) => {
    const log = {
        timestamp: new Date().toISOString(),
        ...req.body
    };

    logs.push(log);

    console.log('[INGESTED LOG]', log);

    res.status(200).send('Log received');
});

// 🔥 NEW: View logs (dashboard endpoint)
app.get('/logs', (req, res) => {
    res.json(logs);
});

app.listen(port, () => {
    console.log(`App running on port ${port}`);
});

const express = require('express');
const app = express();
const port = 3000;

// Simple log middleware (IMPORTANT for SIEM later)
app.use((req, res, next) => {
    console.log(`[LOG] ${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

app.get('/', (req, res) => {
    res.send('DevSecOps SIEM Project Running 🚀');
});

app.get('/error', (req, res) => {
    console.error('[ERROR] Simulated error triggered');
    res.status(500).send('Error generated');
});

app.listen(port, () => {
    console.log(`App running on port ${port}`);
});

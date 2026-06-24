const express = require('express');
const mongoose = require('mongoose');
const app = express();
const port = 3000;

app.use(express.json());

// =======================
// MONGODB CONNECTION
// =======================
const MONGO_URL = process.env.MONGO_URL || 'mongodb://localhost:27017/siem';

mongoose.connect(MONGO_URL)
    .then(() => console.log('[MONGODB] Connected to MongoDB successfully'))
    .catch(err => console.error('[MONGODB] Connection error:', err));

// =======================
// LOG SCHEMA
// =======================
const logSchema = new mongoose.Schema({
    timestamp: { type: String, required: true },
    severity:  { type: String, default: 'low' },
    source:    { type: String },
    type:      { type: String },
    level:     { type: String },
    message:   { type: String },
    event:     { type: String },
    host:      { type: String },
    payload:   { type: mongoose.Schema.Types.Mixed }
}, { strict: false });

const Log = mongoose.model('Log', logSchema);

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
    const mongoStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
    res.json({ status: "OK", service: "DevSecOps SIEM Running", mongodb: mongoStatus });
});

// =======================
// MAIN DASHBOARD
// =======================
app.get('/', async (req, res) => {

    const totalEvents   = await Log.countDocuments();
    const criticalCount = await Log.countDocuments({ severity: 'critical' });
    const highCount     = await Log.countDocuments({ severity: 'high' });
    const lowCount      = await Log.countDocuments({ severity: 'low' });
    const alerts        = criticalCount + highCount;

    const criticalPct = totalEvents ? ((criticalCount / totalEvents) * 100).toFixed(1) : 0;
    const highPct     = totalEvents ? ((highCount     / totalEvents) * 100).toFixed(1) : 0;
    const lowPct      = totalEvents ? ((lowCount      / totalEvents) * 100).toFixed(1) : 0;

    // Active sources
    const activeSources = await Log.distinct('source');
    const activeHosts   = await Log.distinct('host');
    const sourceCount   = activeSources.filter(Boolean).length;

    // Latest host metrics from Sankalp machine
    const latestCPU = await Log.findOne({ type: 'system_metrics' }).sort({ timestamp: -1 });
    const latestNet = await Log.findOne({ type: 'network_connections' }).sort({ timestamp: -1 });
    const latestProc = await Log.findOne({ type: 'process_count' }).sort({ timestamp: -1 });
    const latestDisk = await Log.findOne({ type: 'disk_usage' }).sort({ timestamp: -1 });

    // Source breakdown for doughnut
    const sources = await Log.aggregate([
        { $group: { _id: { $ifNull: ["$source", "unknown"] }, count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 8 }
    ]);

    const sourceLabels = JSON.stringify(sources.map(s => s._id || 'unknown'));
    const sourceCounts = JSON.stringify(sources.map(s => s.count));

    // Severity over time (last 20 logs grouped by severity)
    const recentLogs = await Log.find().sort({ timestamp: -1 }).limit(100);

    res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DevSecOps SIEM Platform</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"><\/script>
    <meta http-equiv="refresh" content="15">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        :root {
            --bg:       #070b10;
            --surface:  #0d1421;
            --surface2: #111927;
            --border:   #1e2d42;
            --accent:   #00d4ff;
            --critical: #ff2d55;
            --high:     #ff6b35;
            --low:      #00c896;
            --text:     #c9d8e8;
            --muted:    #5a7a9a;
            --font:     'Courier New', monospace;
        }
        * { scrollbar-width: thin; scrollbar-color: var(--border) var(--surface); }
        body { background: var(--bg); color: var(--text); font-family: var(--font); min-height: 100vh; }

        /* HEADER */
        header { background: var(--surface); border-bottom: 1px solid var(--border); padding: 12px 24px; display: flex; align-items: center; justify-content: space-between; }
        .logo { display: flex; align-items: center; gap: 10px; font-size: 15px; font-weight: bold; color: var(--accent); letter-spacing: 1px; text-transform: uppercase; }
        .header-pills { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
        .pill { padding: 3px 10px; border-radius: 20px; font-size: 10px; letter-spacing: 1px; border: 1px solid; }
        .pill-green  { background: rgba(0,200,150,0.1);  border-color: var(--low);      color: var(--low); }
        .pill-red    { background: rgba(255,45,85,0.15); border-color: var(--critical);  color: var(--critical); animation: pulse 2s infinite; }
        .pill-blue   { background: rgba(0,212,255,0.1);  border-color: var(--accent);    color: var(--accent); }
        .pill-muted  { background: transparent;          border-color: var(--border);    color: var(--muted); }
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }

        main { padding: 16px 24px; }

        /* STAT CARDS */
        .stats { display: grid; grid-template-columns: repeat(6,1fr); gap: 10px; margin-bottom: 14px; }
        .stat-card { background: var(--surface); border: 1px solid var(--border); border-radius: 6px; padding: 14px 16px; position: relative; overflow: hidden; }
        .stat-card::before { content:''; position:absolute; top:0;left:0;right:0; height:2px; }
        .stat-total::before    { background: var(--accent); }
        .stat-critical::before { background: var(--critical); }
        .stat-high::before     { background: var(--high); }
        .stat-low::before      { background: var(--low); }
        .stat-alerts::before   { background: #a855f7; }
        .stat-sources::before  { background: #fbbf24; }
        .stat-label  { font-size: 9px; text-transform: uppercase; letter-spacing: 2px; color: var(--muted); margin-bottom: 6px; }
        .stat-number { font-size: 28px; font-weight: bold; line-height: 1; margin-bottom: 3px; }
        .stat-total .stat-number    { color: var(--accent); }
        .stat-critical .stat-number { color: var(--critical); }
        .stat-high .stat-number     { color: var(--high); }
        .stat-low .stat-number      { color: var(--low); }
        .stat-alerts .stat-number   { color: #a855f7; }
        .stat-sources .stat-number  { color: #fbbf24; }
        .stat-sub { font-size: 10px; color: var(--muted); }

        /* HOST METRICS PANEL */
        .host-panel { background: var(--surface); border: 1px solid var(--border); border-radius: 6px; padding: 12px 16px; margin-bottom: 14px; }
        .host-panel-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
        .host-panel-title { font-size: 9px; text-transform: uppercase; letter-spacing: 2px; color: var(--accent); }
        .host-metrics { display: grid; grid-template-columns: repeat(4,1fr); gap: 10px; }
        .host-metric { background: var(--surface2); border: 1px solid var(--border); border-radius: 4px; padding: 10px 14px; }
        .host-metric-label { font-size: 9px; text-transform: uppercase; letter-spacing: 1px; color: var(--muted); margin-bottom: 4px; }
        .host-metric-value { font-size: 20px; font-weight: bold; color: var(--text); }
        .host-metric-sub { font-size: 9px; color: var(--muted); margin-top: 2px; }
        .host-tag { display: inline-block; background: rgba(0,212,255,0.1); border: 1px solid var(--accent); color: var(--accent); padding: 2px 8px; border-radius: 3px; font-size: 9px; letter-spacing: 1px; }

        /* FILTER BAR */
        .filter-bar { background: var(--surface); border: 1px solid var(--border); border-radius: 6px; padding: 10px 14px; margin-bottom: 14px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .filter-label { font-size: 9px; text-transform: uppercase; letter-spacing: 1px; color: var(--muted); margin-right: 4px; white-space: nowrap; }
        .filter-btn { background: transparent; border: 1px solid var(--border); color: var(--muted); padding: 3px 10px; border-radius: 4px; font-family: var(--font); font-size: 9px; letter-spacing: 1px; text-transform: uppercase; cursor: pointer; transition: all 0.2s; white-space: nowrap; }
        .filter-btn:hover, .filter-btn.active { color: var(--text); border-color: var(--accent); background: rgba(0,212,255,0.08); }
        .filter-btn.active-critical { border-color:var(--critical); color:var(--critical); background:rgba(255,45,85,0.08); }
        .filter-btn.active-high     { border-color:var(--high);     color:var(--high);     background:rgba(255,107,53,0.08); }
        .filter-btn.active-low      { border-color:var(--low);      color:var(--low);      background:rgba(0,200,150,0.08); }
        .filter-btn.active-source   { border-color:#fbbf24;         color:#fbbf24;         background:rgba(251,191,36,0.08); }
        .divider { width:1px; height:18px; background:var(--border); margin:0 2px; flex-shrink:0; }

        /* MAIN GRID */
        .grid-main { display: grid; grid-template-columns: 1fr 320px; gap: 14px; }

        /* LOG TABLE */
        .panel { background: var(--surface); border: 1px solid var(--border); border-radius: 6px; overflow: hidden; }
        .panel-header { padding: 10px 14px; border-bottom: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; }
        .panel-title { font-size: 9px; text-transform: uppercase; letter-spacing: 2px; color: var(--accent); }
        .panel-meta  { font-size: 9px; color: var(--muted); }
        table { width: 100%; border-collapse: collapse; font-size: 11px; }
        thead th { padding: 7px 10px; text-align: left; font-size: 9px; text-transform: uppercase; letter-spacing: 1px; color: var(--muted); border-bottom: 1px solid var(--border); background: var(--surface2); white-space: nowrap; }
        tbody tr { border-bottom: 1px solid rgba(30,45,66,0.5); transition: background 0.15s; cursor: pointer; }
        tbody tr:hover { background: var(--surface2); }
        tbody td { padding: 7px 10px; color: var(--text); max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

        .badge { display: inline-block; padding: 1px 6px; border-radius: 3px; font-size: 9px; font-weight: bold; letter-spacing: 1px; text-transform: uppercase; }
        .badge-critical { background:rgba(255,45,85,0.2);  color:var(--critical); border:1px solid var(--critical); }
        .badge-high     { background:rgba(255,107,53,0.2); color:var(--high);     border:1px solid var(--high); }
        .badge-low      { background:rgba(0,200,150,0.2);  color:var(--low);      border:1px solid var(--low); }

        .source-badge { display: inline-block; padding: 1px 6px; border-radius: 3px; font-size: 9px; letter-spacing: 1px; text-transform: uppercase; border: 1px solid var(--border); color: var(--muted); }
        .source-windows-host    { border-color:#00d4ff; color:#00d4ff; background:rgba(0,212,255,0.08); }
        .source-windows-network { border-color:#a855f7; color:#a855f7; background:rgba(168,85,247,0.08); }
        .source-windows-process { border-color:#fbbf24; color:#fbbf24; background:rgba(251,191,36,0.08); }
        .source-github          { border-color:#e5e7eb; color:#e5e7eb; background:rgba(229,231,235,0.08); }
        .source-jenkins         { border-color:#f97316; color:#f97316; background:rgba(249,115,22,0.08); }
        .source-ec2             { border-color:#ff9900; color:#ff9900; background:rgba(255,153,0,0.08); }
        .source-kubernetes      { border-color:#326ce5; color:#326ce5; background:rgba(50,108,229,0.08); }

        /* RIGHT PANEL */
        .right-col { display: flex; flex-direction: column; gap: 14px; }
        .chart-panel { background: var(--surface); border: 1px solid var(--border); border-radius: 6px; overflow: hidden; }
        .chart-section { padding: 14px; border-bottom: 1px solid var(--border); }
        .chart-section:last-child { border-bottom: none; }
        .chart-title { font-size: 9px; text-transform: uppercase; letter-spacing: 2px; color: var(--muted); margin-bottom: 10px; }
        .chart-wrap { position: relative; height: 150px; display: flex; align-items: center; justify-content: center; }
        .legend-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 4px; margin-top: 8px; }
        .legend-item { display: flex; align-items: center; gap: 5px; font-size: 9px; color: var(--text); }
        .legend-dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; }
        .legend-pct { color: var(--muted); margin-left: auto; }

        /* ACTIVE SOURCES LIST */
        .sources-panel { background: var(--surface); border: 1px solid var(--border); border-radius: 6px; padding: 14px; }
        .source-list { display: flex; flex-direction: column; gap: 6px; margin-top: 10px; }
        .source-item { display: flex; align-items: center; justify-content: space-between; padding: 6px 10px; background: var(--surface2); border-radius: 4px; border: 1px solid var(--border); }
        .source-item-left { display: flex; align-items: center; gap: 8px; font-size: 10px; }
        .source-dot { width: 6px; height: 6px; border-radius: 50%; background: var(--low); animation: pulse 2s infinite; }
        .source-count { font-size: 9px; color: var(--muted); }

        /* FOOTER */
        .refresh-bar { text-align: center; font-size: 9px; color: var(--muted); letter-spacing: 1px; padding: 8px; border-top: 1px solid var(--border); background: var(--surface); margin-top: 14px; }
    </style>
</head>
<body>

<!-- HEADER -->
<header>
    <div class="logo">🛡 DevSecOps SIEM Platform</div>
    <div class="header-pills">
        <span class="pill pill-green">● MONGODB</span>
        ${alerts > 0 ? `<span class="pill pill-red">⚠ ${alerts} ALERTS</span>` : ''}
        <span class="pill pill-blue">⬡ ${sourceCount} SOURCES</span>
        <span class="pill pill-muted">↻ AUTO-REFRESH 15s</span>
    </div>
</header>

<main>

    <!-- STAT CARDS -->
    <div class="stats">
        <div class="stat-card stat-total">
            <div class="stat-label">Total Events</div>
            <div class="stat-number">${totalEvents.toLocaleString()}</div>
            <div class="stat-sub">All ingested logs</div>
        </div>
        <div class="stat-card stat-critical">
            <div class="stat-label">Critical</div>
            <div class="stat-number">${criticalCount.toLocaleString()}</div>
            <div class="stat-sub">${criticalPct}% of total</div>
        </div>
        <div class="stat-card stat-high">
            <div class="stat-label">High</div>
            <div class="stat-number">${highCount.toLocaleString()}</div>
            <div class="stat-sub">${highPct}% of total</div>
        </div>
        <div class="stat-card stat-low">
            <div class="stat-label">Low</div>
            <div class="stat-number">${lowCount.toLocaleString()}</div>
            <div class="stat-sub">${lowPct}% of total</div>
        </div>
        <div class="stat-card stat-alerts">
            <div class="stat-label">Active Alerts</div>
            <div class="stat-number">${alerts.toLocaleString()}</div>
            <div class="stat-sub">Critical + High</div>
        </div>
        <div class="stat-card stat-sources">
            <div class="stat-label">Active Sources</div>
            <div class="stat-number">${sourceCount}</div>
            <div class="stat-sub">${activeHosts.filter(Boolean).join(', ') || 'none'}</div>
        </div>
    </div>

    <!-- HOST METRICS PANEL -->
    <div class="host-panel">
        <div class="host-panel-header">
            <span class="host-panel-title">🖥 Live Host Metrics</span>
            <span class="host-tag">HOST: ${latestCPU ? latestCPU.host || 'Sankalp' : 'Sankalp'}</span>
        </div>
        <div class="host-metrics">
            <div class="host-metric">
                <div class="host-metric-label">CPU Usage</div>
                <div class="host-metric-value" style="color:${latestCPU && latestCPU.cpu_pct > 85 ? 'var(--critical)' : latestCPU && latestCPU.cpu_pct > 60 ? 'var(--high)' : 'var(--low)'}">
                    ${latestCPU ? latestCPU.cpu_pct + '%' : '—'}
                </div>
                <div class="host-metric-sub">Last: ${latestCPU ? new Date(latestCPU.timestamp).toLocaleTimeString('en-GB') : 'No data'}</div>
            </div>
            <div class="host-metric">
                <div class="host-metric-label">Memory Usage</div>
                <div class="host-metric-value" style="color:${latestCPU && latestCPU.memory_pct > 85 ? 'var(--critical)' : latestCPU && latestCPU.memory_pct > 70 ? 'var(--high)' : 'var(--low)'}">
                    ${latestCPU ? latestCPU.memory_pct + '%' : '—'}
                </div>
                <div class="host-metric-sub">${latestCPU ? latestCPU.memory_used_mb + 'MB / ' + latestCPU.memory_total_mb + 'MB' : 'No data'}</div>
            </div>
            <div class="host-metric">
                <div class="host-metric-label">TCP Connections</div>
                <div class="host-metric-value" style="color:${latestNet && latestNet.established_connections > 100 ? 'var(--high)' : 'var(--low)'}">
                    ${latestNet ? latestNet.established_connections : '—'}
                </div>
                <div class="host-metric-sub">Active established</div>
            </div>
            <div class="host-metric">
                <div class="host-metric-label">Running Processes</div>
                <div class="host-metric-value" style="color:${latestProc && latestProc.process_count > 300 ? 'var(--high)' : 'var(--low)'}">
                    ${latestProc ? latestProc.process_count : '—'}
                </div>
                <div class="host-metric-sub">System processes</div>
            </div>
        </div>
    </div>

    <!-- FILTER BAR -->
    <div class="filter-bar">
        <span class="filter-label">Severity:</span>
        <button class="filter-btn active" onclick="filterAll(this)">All</button>
        <button class="filter-btn" onclick="filterSeverity('critical',this)">Critical</button>
        <button class="filter-btn" onclick="filterSeverity('high',this)">High</button>
        <button class="filter-btn" onclick="filterSeverity('low',this)">Low</button>
        <div class="divider"></div>
        <span class="filter-label">Source:</span>
        <button class="filter-btn" onclick="filterSource('windows-host',this)">Windows Host</button>
        <button class="filter-btn" onclick="filterSource('windows-network',this)">Windows Network</button>
        <button class="filter-btn" onclick="filterSource('windows-process',this)">Windows Process</button>
        <button class="filter-btn" onclick="filterSource('ec2',this)">EC2</button>
        <button class="filter-btn" onclick="filterSource('github',this)">GitHub</button>
        <button class="filter-btn" onclick="filterSource('jenkins',this)">Jenkins</button>
        <div class="divider"></div>
        <span class="filter-label">Type:</span>
        <button class="filter-btn" onclick="filterType('failed_login',this)">Failed Login</button>
        <button class="filter-btn" onclick="filterType('login_success',this)">Login Success</button>
        <button class="filter-btn" onclick="filterType('health_check',this)">Health Check</button>
        <button class="filter-btn" onclick="filterType('k8s_deploy',this)">K8s Deploy</button>
        <button class="filter-btn" onclick="filterType('system_metrics',this)">System Metrics</button>
        <button class="filter-btn" onclick="filterType('process_count',this)">Processes</button>
        <button class="filter-btn" onclick="filterType('network_connections',this)">Network</button>
    </div>

    <!-- MAIN GRID -->
    <div class="grid-main">

        <!-- LOG TABLE -->
        <div class="panel">
            <div class="panel-header">
                <span class="panel-title">Event Log</span>
                <span class="panel-meta">Showing latest 100 events</span>
            </div>
            <div style="overflow-x:auto;max-height:500px;overflow-y:auto;">
                <table id="logTable">
                    <thead>
                        <tr>
                            <th>Timestamp</th>
                            <th>Severity</th>
                            <th>Source</th>
                            <th>Host</th>
                            <th>Type</th>
                            <th>Message</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${recentLogs.map(log => {
                            const ts = new Date(log.timestamp).toLocaleString('en-GB');
                            const src = log.source || '—';
                            const host = log.host || '—';
                            const type = log.type || log.event || '—';
                            const msg = log.message || log.status || log.event || '—';
                            const srcClass = src.replace(/[^a-z0-9]/gi, '-').toLowerCase();
                            return `<tr class="log-row" data-severity="${log.severity}" data-source="${src}" data-type="${type}">
                                <td style="color:var(--muted);font-size:10px;white-space:nowrap;">${ts}</td>
                                <td><span class="badge badge-${log.severity}">${log.severity}</span></td>
                                <td><span class="source-badge source-${srcClass}">${src}</span></td>
                                <td style="color:var(--accent);font-size:10px;">${host}</td>
                                <td style="color:var(--muted);font-size:10px;">${type}</td>
                                <td>${msg}</td>
                            </tr>`;
                        }).join('')}
                    </tbody>
                </table>
            </div>
        </div>

        <!-- RIGHT COLUMN -->
        <div class="right-col">

            <!-- CHARTS -->
            <div class="chart-panel">
                <div class="chart-section">
                    <div class="chart-title">Severity Distribution</div>
                    <div class="chart-wrap"><canvas id="severityChart"></canvas></div>
                    <div class="legend-grid">
                        <div class="legend-item"><div class="legend-dot" style="background:var(--critical)"></div>Critical<span class="legend-pct">${criticalPct}%</span></div>
                        <div class="legend-item"><div class="legend-dot" style="background:var(--high)"></div>High<span class="legend-pct">${highPct}%</span></div>
                        <div class="legend-item"><div class="legend-dot" style="background:var(--low)"></div>Low<span class="legend-pct">${lowPct}%</span></div>
                    </div>
                </div>
                <div class="chart-section">
                    <div class="chart-title">Log Source Breakdown</div>
                    <div class="chart-wrap"><canvas id="sourceChart"></canvas></div>
                </div>
            </div>

            <!-- ACTIVE SOURCES -->
            <div class="sources-panel">
                <div class="panel-title">Active Log Sources</div>
                <div class="source-list">
                    ${sources.map(s => `
                    <div class="source-item">
                        <div class="source-item-left">
                            <div class="source-dot"></div>
                            <span class="source-badge source-${(s._id||'unknown').replace(/[^a-z0-9]/gi,'-').toLowerCase()}">${s._id || 'unknown'}</span>
                        </div>
                        <span class="source-count">${s.count} events</span>
                    </div>`).join('')}
                </div>
            </div>

        </div>
    </div>

</main>

<div class="refresh-bar">AUTO-REFRESHING EVERY 15 SECONDS — MONGODB PERSISTENT STORAGE — ${sourceCount} ACTIVE SOURCES</div>

<script>
new Chart(document.getElementById('severityChart').getContext('2d'), {
    type: 'doughnut',
    data: {
        labels: ['Critical','High','Low'],
        datasets: [{ data: [${criticalCount},${highCount},${lowCount}], backgroundColor: ['#ff2d55','#ff6b35','#00c896'], borderColor: '#0d1421', borderWidth: 3 }]
    },
    options: { responsive:true, maintainAspectRatio:false, cutout:'65%', plugins:{ legend:{ display:false } } }
});

new Chart(document.getElementById('sourceChart').getContext('2d'), {
    type: 'doughnut',
    data: {
        labels: ${sourceLabels},
        datasets: [{ data: ${sourceCounts}, backgroundColor: ['#00d4ff','#a855f7','#fbbf24','#00c896','#ff2d55','#f97316','#326ce5','#e5e7eb'], borderColor: '#0d1421', borderWidth: 3 }]
    },
    options: { responsive:true, maintainAspectRatio:false, cutout:'65%', plugins:{ legend:{ display:true, position:'bottom', labels:{ color:'#5a7a9a', font:{ size:9, family:'Courier New' }, boxWidth:7, padding:6 } } } }
});

function clearFilters() {
    document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active','active-critical','active-high','active-low','active-source'));
}

function filterAll(btn) {
    clearFilters();
    btn.classList.add('active');
    document.querySelectorAll('.log-row').forEach(r => r.style.display = '');
}

function filterSeverity(severity, btn) {
    clearFilters();
    btn.classList.add('active', 'active-' + severity);
    document.querySelectorAll('.log-row').forEach(r => {
        r.style.display = r.dataset.severity === severity ? '' : 'none';
    });
}

function filterSource(source, btn) {
    clearFilters();
    btn.classList.add('active', 'active-source');
    document.querySelectorAll('.log-row').forEach(r => {
        r.style.display = r.dataset.source === source ? '' : 'none';
    });
}

function filterType(type, btn) {
    clearFilters();
    btn.classList.add('active', 'active-source');
    document.querySelectorAll('.log-row').forEach(r => {
        r.style.display = r.dataset.type === type ? '' : 'none';
    });
}
<\/script>
</body>
</html>
    `);
});

// =======================
// LOG INGESTION
// =======================
app.post('/logs', async (req, res) => {
    const raw = req.body;
    let severity = "low";
    if (raw.type === "failed_login") severity = "high";
    if (raw.level === "error")       severity = "critical";
    if (raw.type === "login_success") severity = "low";
    if (raw.type === "process_count" && raw.process_count > 300) severity = "high";
    if (raw.type === "system_metrics" && raw.cpu_pct > 85) severity = "critical";
    if (raw.type === "system_metrics" && raw.cpu_pct > 60) severity = "high";
    const log = new Log({ timestamp: new Date().toISOString(), severity, ...raw });
    await log.save();
    console.log('[INGESTED LOG]', log.source, log.type, log.severity);
    res.json({ status: "received", log });
});

// =======================
// GITHUB WEBHOOK
// =======================
app.post('/github-webhook', async (req, res) => {
    const log = new Log({
        timestamp: new Date().toISOString(),
        source:    "github",
        severity:  "low",
        event:     req.headers['x-github-event'],
        payload:   req.body
    });
    await log.save();
    console.log('[GITHUB WEBHOOK]', log.event);
    res.status(200).send('Webhook received');
});

// =======================
// RAW LOGS API
// =======================
app.get('/logs', async (req, res) => {
    const logs = await Log.find().sort({ timestamp: -1 });
    res.json(logs);
});

// =======================
// CLEAR LOGS API
// =======================
app.delete('/logs', async (req, res) => {
    await Log.deleteMany({});
    console.log('[LOGS CLEARED]');
    res.json({ status: "cleared" });
});

// =======================
// START SERVER
// =======================
app.listen(port, () => {
    console.log(`App running on port ${port}`);
    console.log(`Dashboard: http://localhost:${port}`);
    console.log(`MongoDB: ${MONGO_URL}`);
});

// Zero-dependency Node.js CORS Proxy for Active Health Centre API
// Proxies http://localhost:5050/api/v1/* -> https://api.activehealthcentre.in/api/v1/*
const http = require('http');
const https = require('https');
const url = require('url');

const PORT = 5050;
const TARGET_HOST = 'api.activehealthcentre.in';

const server = http.createServer((req, res) => {
  const origin = req.headers.origin || '*';

  // Universal CORS Headers
  res.setHeader('Access-Control-Allow-Origin', origin);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Device-Id, Accept, Origin, X-Requested-With');
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Max-Age', '86400');

  // Handle preflight OPTIONS request immediately
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Forward request to remote API
  const options = {
    hostname: TARGET_HOST,
    port: 443,
    path: req.url,
    method: req.method,
    headers: {
      ...req.headers,
      host: TARGET_HOST,
    },
  };

  delete options.headers['origin'];
  delete options.headers['referer'];

  const proxyReq = https.request(options, (proxyRes) => {
    // Forward status code
    res.writeHead(proxyRes.statusCode, {
      ...proxyRes.headers,
      'access-control-allow-origin': origin,
      'access-control-allow-credentials': 'true',
    });
    proxyRes.pipe(res, { end: true });
  });

  proxyReq.on('error', (err) => {
    console.error('Proxy Error:', err.message);
    res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Proxy Gateway Error: ' + err.message }));
  });

  req.pipe(proxyReq, { end: true });
});

server.listen(PORT, () => {
  console.log(`[CORS Proxy] Running at http://localhost:${PORT}`);
  console.log(`[CORS Proxy] Forwarding to https://${TARGET_HOST}`);
});

// ============================================
// IMPORTAÇÕES
// ============================================
const express = require('express');
const app = express();

// ============================================
// CONFIGURAÇÕES
// ============================================
const PORT = process.env.PORT || 3000;
let requestCount = 0;

// ============================================
// MIDDLEWARE - Contador de Requisições
// ============================================
app.use((req, res, next) => {
  requestCount++;
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} - Total: ${requestCount}`);
  next();
});

// ============================================
// ROTAS
// ============================================

// Rota principal
app.get('/', (req, res) => {
  res.json({
    message: 'Webapp Deployment Automation',
    status: 'running',
    version: '1.0.0',
    totalRequests: requestCount,
    timestamp: new Date().toISOString()
  });
});

// Health check (importante para Docker/K8s)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// Métricas simples
app.get('/metrics', (req, res) => {
  res.json({
    totalRequests: requestCount,
    uptimeSeconds: Math.floor(process.uptime()),
    memoryUsageMB: Math.round(process.memoryUsage().heapUsed / 1024 / 1024)
  });
});

// ============================================
// INICIAR SERVIDOR
// ============================================
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Metrics: http://localhost:${PORT}/metrics`);
  console.log(`💚 Health: http://localhost:${PORT}/health`);
});

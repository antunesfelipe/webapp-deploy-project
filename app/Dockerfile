# ============================================
# STAGE 1: BUILDER
# ============================================
# Imagem base para construir
FROM node:18-alpine AS builder

# Definir diretório de trabalho
WORKDIR /app

# Copiar APENAS package*.json primeiro
COPY package*.json ./

# Instalar dependências
RUN npm ci --only=production

# ============================================
# STAGE 2: PRODUCTION
# ============================================
# Nova imagem limpa para produção
FROM node:18-alpine

# Criar usuário não-root (segurança)
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Definir diretório de trabalho
WORKDIR /app

# Copiar node_modules do stage builder
COPY --from=builder /app/node_modules ./node_modules

# Copiar código da aplicação
COPY server.js ./

# Mudar ownership dos arquivos para nodejs
RUN chown -R nodejs:nodejs /app

# Trocar para usuário não-root
USER nodejs

# Expor porta
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Comando para iniciar aplicação
CMD ["node", "server.js"]

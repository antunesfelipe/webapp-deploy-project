#!/bin/bash
# ============================================
# DEPLOY SCRIPT
# ============================================
# Script para deploy automatizado da aplicação
# Uso: ./scripts/deploy.sh

# ============================================
# CONFIGURAÇÕES
# ============================================

# Para execução se qualquer comando falhar
set -e

# Para se usar variável não definida
set -u

# Mostrar comandos sendo executados (debug)
# set -x

# ============================================
# VARIÁVEIS
# ============================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
HEALTH_CHECK_URL="http://localhost:3000/health"
MAX_RETRIES=5
RETRY_INTERVAL=5

# ============================================
# FUNÇÕES
# ============================================

# Função para mostrar mensagens coloridas
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para aguardar serviço ficar healthy
wait_for_health() {
    local url=$1
    local retries=0
    
    log_info "Aguardando serviço ficar healthy..."
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            log_success "Serviço está healthy!"
            return 0
        fi
        
        retries=$((retries + 1))
        log_warning "Tentativa $retries/$MAX_RETRIES - aguardando ${RETRY_INTERVAL}s..."
        sleep $RETRY_INTERVAL
    done
    
    log_error "Serviço não ficou healthy após $MAX_RETRIES tentativas"
    return 1
}

# ============================================
# VALIDAÇÕES INICIAIS
# ============================================

log_info "Iniciando validações..."

# Verificar se Docker está instalado
if ! command_exists docker; then
    log_error "Docker não está instalado!"
    exit 1
fi

# Verificar se Docker Compose está instalado
if ! command_exists docker compose; then
    log_error "Docker Compose não está instalado!"
    exit 1
fi

# Verificar se Docker daemon está rodando
if ! docker info > /dev/null 2>&1; then
    log_error "Docker daemon não está rodando!"
    exit 1
fi

log_success "Validações concluídas"

# ============================================
# INÍCIO DO DEPLOY
# ============================================

echo ""
log_info "🚀 Iniciando deploy..."
echo ""

# ============================================
# PASSO 1: PARAR CONTAINERS ANTIGOS
# ============================================

log_info "Parando containers antigos..."
docker compose down || {
    log_warning "Nenhum container rodando (normal no primeiro deploy)"
}
log_success "Containers parados"

# ============================================
# PASSO 2: LIMPAR RECURSOS ORFÃOS
# ============================================

log_info "Limpando recursos órfãos..."
docker compose down --remove-orphans > /dev/null 2>&1 || true
log_success "Recursos limpos"

# ============================================
# PASSO 3: BUILDAR IMAGENS
# ============================================

log_info "Buildando imagens Docker..."
log_warning "Isso pode demorar alguns minutos..."

if docker compose build --no-cache; then
    log_success "Imagens buildadas com sucesso"
else
    log_error "Falha ao buildar imagens"
    exit 1
fi

# ============================================
# PASSO 4: SUBIR CONTAINERS
# ============================================

log_info "Subindo containers..."

if docker compose up -d; then
    log_success "Containers iniciados"
else
    log_error "Falha ao subir containers"
    docker compose logs
    exit 1
fi

# ============================================
# PASSO 5: AGUARDAR HEALTH CHECKS
# ============================================

log_info "Aguardando serviços ficarem prontos..."
sleep 10

# ============================================
# PASSO 6: VALIDAR DEPLOYMENT
# ============================================

log_info "Validando deployment..."

# Testar health check
if wait_for_health "$HEALTH_CHECK_URL"; then
    log_success "Health check passou!"
else
    log_error "Health check falhou!"
    log_error "Mostrando logs dos containers:"
    docker compose logs --tail=50
    exit 1
fi

# Testar endpoint principal
if curl -f -s http://localhost:3000/ > /dev/null 2>&1; then
    log_success "Endpoint principal respondendo!"
else
    log_warning "Endpoint principal não está respondendo (pode ser normal)"
fi

# ============================================
# PASSO 7: MOSTRAR STATUS
# ============================================

echo ""
log_info "📊 Status dos containers:"
echo ""

docker compose ps

echo ""
log_info "💾 Uso de recursos:"
echo ""

# Mostrar uso de CPU e memória
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker-compose ps -q)

# ============================================
# PASSO 8: MOSTRAR INFORMAÇÕES ÚTEIS
# ============================================

echo ""
log_success "🎉 Deploy concluído com sucesso!"
echo ""

log_info "📍 URLs disponíveis:"
echo "   • Aplicação: http://localhost:3000"
echo "   • Health: http://localhost:3000/health"
echo "   • Métricas: http://localhost:3000/metrics"
echo ""

log_info "📋 Comandos úteis:"
echo "   • Ver logs: docker-compose logs -f"
echo "   • Ver logs da app: docker-compose logs -f app"
echo "   • Parar: docker-compose down"
echo "   • Reiniciar: docker-compose restart"
echo ""

log_info "🔍 Para verificar saúde dos containers:"
echo "   docker-compose ps"
echo ""

# ============================================
# FIM
# ============================================

exit 0

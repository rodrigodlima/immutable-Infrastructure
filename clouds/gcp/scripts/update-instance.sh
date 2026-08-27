#!/bin/bash

# Script para atualizar instância com zero downtime
# Faz o deploy Blue-Green: cria nova instância, migra IP, destroi antiga

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "$SCRIPT_DIR/../terraform" && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info "Iniciando atualização Blue-Green..."

cd "$TERRAFORM_DIR"

# 1. Verificar se há uma instância antiga
print_info "Verificando instância atual..."
OLD_INSTANCE=$(terraform state list | grep google_compute_instance.nginx_server || echo "")

if [ -z "$OLD_INSTANCE" ]; then
    print_warning "Nenhuma instância existente encontrada. Fazendo deploy inicial..."
    terraform apply -auto-approve
    print_success "Deploy inicial concluído!"
    exit 0
fi

# 2. Criar nova instância (forçar substituição)
print_info "Criando nova instância com a imagem mais recente..."
terraform apply -auto-approve -replace=google_compute_instance.nginx_server

if [ $? -eq 0 ]; then
    print_success "Nova instância criada com sucesso!"
    print_success "IP estático migrado automaticamente"
    print_info "Aguardando 30 segundos para garantir que a nova instância está funcionando..."
    sleep 30
    
    # 3. Listar instâncias para verificação
    print_info "Instâncias nginx no projeto:"
    gcloud compute instances list --filter="name~^nginx-immutable-demo" --format="table(name,zone,status,networkInterfaces[0].accessConfigs[0].natIP)"
    
    print_warning "ATENÇÃO: Se houver múltiplas instâncias antigas, remova-as manualmente:"
    print_info "gcloud compute instances delete INSTANCE_NAME --zone=ZONE"
else
    print_error "Falha ao criar nova instância"
    exit 1
fi


print_success "Atualização concluída!"

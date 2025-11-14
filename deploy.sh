#!/bin/bash

# Script de Deploy Automatizado - Infraestrutura Imutável
# Automatiza o processo de build com Packer e deploy com Terraform

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
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

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Verificar dependências
check_dependencies() {
    print_header "Verificando Dependências"
    
    local missing_deps=0
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI não encontrado"
        missing_deps=1
    else
        print_success "gcloud CLI instalado"
    fi
    
    if ! command -v packer &> /dev/null; then
        print_error "Packer não encontrado"
        missing_deps=1
    else
        print_success "Packer instalado ($(packer version))"
    fi
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform não encontrado"
        missing_deps=1
    else
        print_success "Terraform instalado ($(terraform version | head -n 1))"
    fi
    
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible não encontrado"
        missing_deps=1
    else
        print_success "Ansible instalado ($(ansible --version | head -n 1))"
    fi
    
    if [ $missing_deps -eq 1 ]; then
        print_error "Dependências faltando. Instale as ferramentas necessárias."
        exit 1
    fi
}

# Verificar configuração
check_config() {
    print_header "Verificando Configuração"
    
    # Verificar arquivo de variáveis do Packer
    if [ ! -f "packer/variables.pkrvars.hcl" ]; then
        print_error "Arquivo packer/variables.pkrvars.hcl não encontrado"
        print_info "Copie o arquivo de exemplo: cp packer/variables.pkrvars.hcl.example packer/variables.pkrvars.hcl"
        exit 1
    fi
    print_success "Variáveis do Packer configuradas"
    
    # Verificar arquivo de variáveis do Terraform
    if [ ! -f "terraform/terraform.tfvars" ]; then
        print_error "Arquivo terraform/terraform.tfvars não encontrado"
        print_info "Copie o arquivo de exemplo: cp terraform/terraform.tfvars.example terraform/terraform.tfvars"
        exit 1
    fi
    print_success "Variáveis do Terraform configuradas"
    
    # Verificar autenticação GCP
    if ! gcloud auth application-default print-access-token &> /dev/null; then
        print_warning "Credenciais GCP não configuradas"
        print_info "Execute: gcloud auth application-default login"
        read -p "Deseja executar agora? (s/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            gcloud auth application-default login
        else
            exit 1
        fi
    fi
    print_success "Credenciais GCP configuradas"
}

# Validar configurações
validate_configs() {
    print_header "Validando Configurações"

    # Inicializar Packer (baixar plugins)
    print_info "Inicializando Packer e instalando plugins..."
    if packer init packer/gce-nginx.pkr.hcl; then
        print_success "Plugins do Packer instalados"
    else
        print_error "Falha ao instalar plugins do Packer"
        exit 1
    fi

    # Validar Packer
    print_info "Validando template Packer..."
    if packer validate -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl; then
        print_success "Template Packer válido"
    else
        print_error "Template Packer inválido"
        exit 1
    fi
    
    # Validar Ansible
    print_info "Validando playbook Ansible..."
    if ansible-playbook ansible/nginx.yml --syntax-check; then
        print_success "Playbook Ansible válido"
    else
        print_error "Playbook Ansible inválido"
        exit 1
    fi
}

# Construir imagem com Packer
build_image() {
    print_header "Construindo Imagem com Packer"
    
    print_info "Iniciando build da imagem... (isso pode levar 5-10 minutos)"
    
    if packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl; then
        print_success "Imagem criada com sucesso!"
        
        # Extrair nome da imagem do manifest
        if [ -f "packer-manifest.json" ]; then
            IMAGE_NAME=$(jq -r '.builds[0].artifact_id' packer-manifest.json | cut -d: -f2)
            print_info "Imagem criada: $IMAGE_NAME"
        fi
    else
        print_error "Falha ao criar imagem"
        exit 1
    fi
}

# Listar imagens criadas
list_images() {
    print_header "Imagens Disponíveis"
    
    print_info "Buscando imagens da família nginx-immutable-family..."
    gcloud compute images list --filter="family:nginx-immutable-family" --format="table(name,family,creationTimestamp,status)"
}

# Deploy com Terraform
deploy_infrastructure() {
    print_header "Deploy de Infraestrutura com Terraform"

    cd terraform

    # Inicializar Terraform se necessário
    if [ ! -d ".terraform" ]; then
        print_info "Inicializando Terraform..."
        terraform init
    fi

    # Validar configuração
    print_info "Validando configuração Terraform..."
    if terraform validate; then
        print_success "Configuração Terraform válida"
    else
        print_error "Configuração Terraform inválida"
        exit 1
    fi

    # Mostrar plano
    print_info "Gerando plano de execução..."
    terraform plan -out=tfplan

    # Confirmar deploy
    echo
    read -p "Deseja aplicar as mudanças? (s/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        print_info "Aplicando mudanças..."
        if terraform apply tfplan; then
            print_success "Infraestrutura criada com sucesso!"

            # Mostrar outputs
            print_header "Informações de Acesso"
            terraform output

            echo
            print_success "Deploy concluído!"
            print_info "Acesse o Nginx em: $(terraform output -raw nginx_url)"
            print_info "SSH: $(terraform output -raw ssh_command)"
        else
            print_error "Falha ao aplicar mudanças"
            exit 1
        fi
    else
        print_warning "Deploy cancelado pelo usuário"
    fi

    cd ..
}

# Atualizar instância (substituir pela nova imagem)
update_instance() {
    print_header "Atualizando Instância com Nova Imagem"

    cd terraform

    print_warning "Isso irá destruir a instância atual e criar uma nova"
    print_info "O IP estático será mantido e reatribuído à nova instância"

    echo
    read -p "Deseja continuar? (s/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        print_info "Substituindo instância..."
        if terraform apply -replace=google_compute_instance.nginx_server -auto-approve; then
            print_success "Instância atualizada com sucesso!"

            # Mostrar outputs
            print_header "Informações de Acesso"
            terraform output

            echo
            print_success "Atualização concluída!"
            print_info "Acesse o Nginx em: $(terraform output -raw nginx_url)"
        else
            print_error "Falha ao atualizar instância"
            exit 1
        fi
    else
        print_warning "Atualização cancelada"
    fi

    cd ..
}

# Destruir infraestrutura
destroy_infrastructure() {
    print_header "Destruindo Infraestrutura"
    
    cd terraform
    
    print_warning "ATENÇÃO: Isso vai destruir todos os recursos criados pelo Terraform!"
    read -p "Tem certeza? (s/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        print_info "Destruindo recursos..."
        if terraform destroy -auto-approve; then
            print_success "Recursos destruídos com sucesso!"
        else
            print_error "Falha ao destruir recursos"
            exit 1
        fi
    else
        print_warning "Destruição cancelada"
    fi
    
    cd ..
}

# Menu principal
show_menu() {
    echo
    echo "=========================================="
    echo "  Infraestrutura Imutável - GCP"
    echo "=========================================="
    echo
    echo "1) Build Completo (Packer + Terraform)"
    echo "2) Apenas Packer (Criar Imagem)"
    echo "3) Apenas Terraform (Deploy)"
    echo "4) Atualizar Instância (Nova Imagem)"
    echo "5) Listar Imagens"
    echo "6) Destruir Infraestrutura"
    echo "7) Validar Configurações"
    echo "0) Sair"
    echo
    read -p "Escolha uma opção: " choice

    case $choice in
        1)
            check_dependencies
            check_config
            validate_configs
            build_image
            list_images
            deploy_infrastructure
            ;;
        2)
            check_dependencies
            check_config
            validate_configs
            build_image
            list_images
            ;;
        3)
            check_dependencies
            check_config
            deploy_infrastructure
            ;;
        4)
            update_instance
            ;;
        5)
            list_images
            ;;
        6)
            destroy_infrastructure
            ;;
        7)
            check_dependencies
            check_config
            validate_configs
            print_success "Todas as validações passaram!"
            ;;
        0)
            print_info "Saindo..."
            exit 0
            ;;
        *)
            print_error "Opção inválida"
            show_menu
            ;;
    esac
}

# Executar menu
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Script de Deploy Automatizado - Infraestrutura Imutável"
    echo
    echo "Uso: ./deploy.sh [opção]"
    echo
    echo "Opções:"
    echo "  --full          Build completo (Packer + Terraform)"
    echo "  --packer        Apenas build do Packer"
    echo "  --terraform     Apenas deploy Terraform"
    echo "  --update        Atualizar instância com nova imagem"
    echo "  --destroy       Destruir infraestrutura"
    echo "  --list          Listar imagens"
    echo "  --validate      Validar configurações"
    echo "  --help, -h      Mostrar esta ajuda"
    echo
    echo "Sem argumentos, mostra o menu interativo"
    exit 0
elif [ "$1" = "--full" ]; then
    check_dependencies
    check_config
    validate_configs
    build_image
    list_images
    deploy_infrastructure
elif [ "$1" = "--packer" ]; then
    check_dependencies
    check_config
    validate_configs
    build_image
    list_images
elif [ "$1" = "--terraform" ]; then
    check_dependencies
    check_config
    deploy_infrastructure
elif [ "$1" = "--update" ]; then
    update_instance
elif [ "$1" = "--destroy" ]; then
    destroy_infrastructure
elif [ "$1" = "--list" ]; then
    list_images
elif [ "$1" = "--validate" ]; then
    check_dependencies
    check_config
    validate_configs
    print_success "Todas as validações passaram!"
else
    show_menu
fi

#!/bin/bash


set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

pause_demo() {
    echo -e "\n${PURPLE}Press ENTER to continue...${NC}"
    read
}

# Verificar se está no diretório correto
if [ ! -f "ansible/nginx.yml" ] || [ ! -f "packer/gce-nginx.pkr.hcl" ]; then
    print_error "Exec this script from root project!"
    exit 1
fi

if [ -z "$PROJECT_ID" ]; then
    print_error "Define PROJECT_ID: export PROJECT_ID='your-gcp-project'"
    exit 1
fi

print_step "🎬 DEMO DE INFRAESTRUTURA IMUTÁVEL - GCP"
echo "Este script vai demonstrar:"
echo "  1. Deploy da versão 1 (original)"
echo "  2. Criação e deploy da versão 2 (atualizada)"
echo "  3. Rollback para versão 1"
echo ""
echo "Projeto GCP: $PROJECT_ID"
pause_demo

# ==========================================
# PARTE 1: DEPLOY V1
# ==========================================

print_step "📦 PARTE 1: DEPLOY INICIAL (V1)"

print_info "Criando imagem V1 com Packer..."
if packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl; then
    print_success "Imagem V1 criada!"
else
    print_error "Falha ao criar imagem V1"
    exit 1
fi

# Capturar nome da imagem V1
export IMAGE_V1=$(gcloud compute images list \
    --filter="family:nginx-immutable-family" \
    --format="value(name)" \
    --sort-by=creationTimestamp \
    --limit=1)

print_success "Imagem V1: $IMAGE_V1"

echo ""
print_info "Fazendo deploy da infraestrutura V1..."
cd terraform
terraform init -input=false
terraform apply -auto-approve

# Obter IP
export NGINX_IP=$(terraform output -raw external_ip)
export NGINX_URL=$(terraform output -raw nginx_url)
cd ..

print_success "V1 deployed!"
echo "URL: $NGINX_URL"

# Aguardar Nginx iniciar
sleep 10

# Testar V1
print_info "Testando V1..."
if curl -s -o /dev/null -w "%{http_code}" $NGINX_IP | grep -q "200"; then
    print_success "V1 está respondendo!"
    echo ""
    echo "Abrindo V1 no navegador..."
    xdg-open $NGINX_URL 2>/dev/null || open $NGINX_URL 2>/dev/null || echo "Acesse: $NGINX_URL"
else
    print_error "V1 não está respondendo"
fi

pause_demo

# ==========================================
# PARTE 2: CRIAR E DEPLOY V2
# ==========================================

print_step "🆕 PARTE 2: CRIAR E DEPLOY V2"

print_info "Fazendo backup do playbook original..."
cp ansible/nginx.yml ansible/nginx.yml.v1

print_info "Criando versão 2 do conteúdo..."
cat > ansible/nginx.yml << 'EOFANSIBLE'
---
- name: Instalar e Configurar Nginx - VERSÃO 2
  hosts: all
  become: yes
  tasks:
    - name: Atualizar cache do apt
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Instalar Nginx
      apt:
        name: nginx
        state: present

    - name: Criar página HTML - VERSÃO 2 (ATUALIZADA)
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Infraestrutura Imutável - V2</title>
              <style>
                  body {
                      font-family: Arial, sans-serif;
                      max-width: 800px;
                      margin: 50px auto;
                      padding: 20px;
                      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  }
                  .container {
                      background-color: white;
                      padding: 30px;
                      border-radius: 15px;
                      box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                  }
                  h1 {
                      color: #667eea;
                      font-size: 2.5em;
                  }
                  .version-badge {
                      display: inline-block;
                      padding: 10px 20px;
                      margin: 10px 0;
                      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                      color: white;
                      border-radius: 25px;
                      font-size: 1.5em;
                      font-weight: bold;
                      animation: pulse 2s infinite;
                  }
                  @keyframes pulse {
                      0%, 100% { transform: scale(1); }
                      50% { transform: scale(1.05); }
                  }
                  .badge {
                      display: inline-block;
                      padding: 5px 10px;
                      margin: 5px;
                      background-color: #764ba2;
                      color: white;
                      border-radius: 5px;
                  }
                  .new-feature {
                      background-color: #fff3cd;
                      border-left: 4px solid #ffc107;
                      padding: 15px;
                      margin: 20px 0;
                  }
              </style>
          </head>
          <body>
              <div class="container">
                  <h1>🚀 Infraestrutura Imutável</h1>
                  <div class="version-badge">✨ VERSÃO 2.0 ✨</div>
                  
                  <p><strong>Esta instância foi provisionada usando:</strong></p>
                  <div>
                      <span class="badge">Packer</span>
                      <span class="badge">Ansible</span>
                      <span class="badge">Terraform</span>
                      <span class="badge">GCP</span>
                  </div>
                  
                  <div class="new-feature">
                      <h3>🎉 Novidades da Versão 2.0:</h3>
                      <ul>
                          <li>✅ Novo design visual com gradiente roxo</li>
                          <li>✅ Badge de versão animado</li>
                          <li>✅ Layout completamente redesenhado</li>
                          <li>✅ Demonstração de atualização imutável</li>
                          <li>✅ Rollback disponível a qualquer momento!</li>
                      </ul>
                  </div>
                  
                  <hr>
                  <p>✅ Nginx instalado via Ansible</p>
                  <p>✅ Imagem criada pelo Packer (V2)</p>
                  <p>✅ Instância provisionada pelo Terraform</p>
                  <p>✅ Infraestrutura 100% imutável</p>
                  <p>🔄 Rollback fácil para V1 a qualquer momento!</p>
                  
                  <hr>
                  <p><em>Hostname: {{ ansible_hostname }}</em></p>
                  <p><em>Build Time: {{ ansible_date_time.iso8601 }}</em></p>
                  <p><strong style="color: #f5576c;">⚡ VERSÃO DA IMAGEM: 2.0 ⚡</strong></p>
              </div>
          </body>
          </html>
        dest: /var/www/html/index.html
        mode: '0644'

    - name: Garantir que o Nginx está rodando
      systemd:
        name: nginx
        state: started
        enabled: yes

    - name: Configurar firewall
      ufw:
        rule: allow
        port: '80'
        proto: tcp
      ignore_errors: yes
EOFANSIBLE

print_success "Conteúdo V2 criado!"

print_info "Criando imagem V2 com Packer..."
if packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl; then
    print_success "Imagem V2 criada!"
else
    print_error "Falha ao criar imagem V2"
    exit 1
fi

# Capturar nome da imagem V2
export IMAGE_V2=$(gcloud compute images list \
    --filter="family:nginx-immutable-family" \
    --format="value(name)" \
    --sort-by=~creationTimestamp \
    --limit=1)

print_success "Imagem V2: $IMAGE_V2"

echo ""
print_info "Agora temos 2 imagens disponíveis:"
gcloud compute images list --filter="family:nginx-immutable-family" \
    --format="table(name,family,creationTimestamp)" \
    --sort-by=creationTimestamp

pause_demo

print_info "Fazendo deploy da V2..."
cd terraform
terraform apply -replace=google_compute_instance.nginx_server -auto-approve
cd ..

sleep 10

print_success "V2 deployed!"
echo "URL: $NGINX_URL"

print_info "Testando V2..."
if curl -s $NGINX_IP | grep -q "VERSÃO 2.0"; then
    print_success "V2 está respondendo com novo conteúdo!"
    echo ""
    echo "Abrindo V2 no navegador..."
    xdg-open $NGINX_URL 2>/dev/null || open $NGINX_URL 2>/dev/null || echo "Acesse: $NGINX_URL"
else
    print_error "V2 não está respondendo corretamente"
fi

pause_demo

# ==========================================
# PARTE 3: ROLLBACK PARA V1
# ==========================================

print_step "🔄 PARTE 3: ROLLBACK PARA V1"

print_info "Simulando problema na V2... Iniciando rollback!"

# Modificar terraform para usar imagem específica V1
print_info "Forçando uso da imagem V1..."

cd terraform

# Backup do main.tf
cp main.tf main.tf.backup

# Criar versão com imagem específica
sed "s|family  = var.image_family|name    = \"$IMAGE_V1\"|" main.tf.backup > main.tf

print_info "Executando rollback..."
terraform apply -replace=google_compute_instance.nginx_server -auto-approve

# Restaurar main.tf
mv main.tf.backup main.tf

cd ..

sleep 10

print_success "Rollback concluído!"

print_info "Testando V1 (rollback)..."
if curl -s $NGINX_IP | grep -q "Infraestrutura Imutável - Demo"; then
    print_success "Rollback bem-sucedido! Voltamos para V1!"
    echo ""
    echo "Abrindo V1 (restaurada) no navegador..."
    xdg-open $NGINX_URL 2>/dev/null || open $NGINX_URL 2>/dev/null || echo "Acesse: $NGINX_URL"
else
    print_error "Rollback não funcionou como esperado"
fi

# Restaurar ansible para V1
if [ -f "ansible/nginx.yml.v1" ]; then
    mv ansible/nginx.yml.v1 ansible/nginx.yml
    print_success "Playbook Ansible restaurado para V1"
fi

# ==========================================
# RESUMO
# ==========================================

print_step "📊 RESUMO DA DEMONSTRAÇÃO"

echo "✅ PARTE 1: Deploy inicial V1"
echo "   - Imagem: $IMAGE_V1"
echo "   - Design original"
echo ""
echo "✅ PARTE 2: Atualização para V2"
echo "   - Imagem: $IMAGE_V2"
echo "   - Design roxo com gradiente"
echo ""
echo "✅ PARTE 3: Rollback para V1"
echo "   - Voltou para: $IMAGE_V1"
echo "   - Design original restaurado"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎓 CONCEITOS DEMONSTRADOS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "♻️  IMUTABILIDADE:"
echo "   Servidores nunca modificados, sempre novas versões"
echo ""
echo "📦 VERSIONAMENTO:"
echo "   Múltiplas imagens coexistem para fácil rollback"
echo ""
echo "🔄 ROLLBACK RÁPIDO:"
echo "   Voltar para qualquer versão em minutos"
echo ""
echo "🎯 CONFIABILIDADE:"
echo "   Mesma imagem = mesmo resultado sempre"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
print_info "Imagens disponíveis no GCP:"
gcloud compute images list --filter="family:nginx-immutable-family" \
    --format="table(name,family,diskSizeGb,status)"

echo ""
print_success "🎉 DEMONSTRAÇÃO COMPLETA!"
echo ""
echo "URL da aplicação: $NGINX_URL"
echo ""
echo "Para limpar recursos:"
echo "  cd terraform && terraform destroy"

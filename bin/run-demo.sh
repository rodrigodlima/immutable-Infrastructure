#!/bin/bash


set -e

# This demo is GCP-specific. For other clouds, see clouds/<cloud>/README.md
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLOUD_DIR="$ROOT_DIR/clouds/gcp"
PACKER_TEMPLATE="$CLOUD_DIR/packer/gce-nginx.pkr.hcl"
PACKER_VARS="$CLOUD_DIR/packer/variables.pkrvars.hcl"
TERRAFORM_DIR="$CLOUD_DIR/terraform"
ANSIBLE_PLAYBOOK="$ROOT_DIR/shared/ansible/nginx.yml"

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

# Check that the project structure is intact
if [ ! -f "$ANSIBLE_PLAYBOOK" ] || [ ! -f "$PACKER_TEMPLATE" ]; then
    print_error "Project structure not found (shared/ansible + clouds/gcp/packer)"
    exit 1
fi

if [ -z "$PROJECT_ID" ]; then
    print_error "Define PROJECT_ID: export PROJECT_ID='your-gcp-project'"
    exit 1
fi

print_step "🎬 IMMUTABLE INFRASTRUCTURE DEMO - GCP"
echo "This script will demonstrate:"
echo "  1. Deploy of version 1 (original)"
echo "  2. Build and deploy of version 2 (updated)"
echo "  3. Rollback to version 1"
echo ""
echo "GCP project: $PROJECT_ID"
pause_demo

# ==========================================
# PART 1: DEPLOY V1
# ==========================================

print_step "📦 PART 1: INITIAL DEPLOY (V1)"

print_info "Building V1 image with Packer..."
if packer build -var-file="$PACKER_VARS" "$PACKER_TEMPLATE"; then
    print_success "V1 image created"
else
    print_error "Failed to create V1 image"
    exit 1
fi

# Capture the V1 image name
export IMAGE_V1=$(gcloud compute images list \
    --filter="family:nginx-immutable-family" \
    --format="value(name)" \
    --sort-by=creationTimestamp \
    --limit=1)

print_success "V1 image: $IMAGE_V1"

echo ""
print_info "Deploying the V1 infrastructure..."
cd "$TERRAFORM_DIR"
terraform init -input=false
terraform apply -auto-approve

# Get the IP
export NGINX_IP=$(terraform output -raw external_ip)
export NGINX_URL=$(terraform output -raw nginx_url)
cd "$ROOT_DIR"

print_success "V1 deployed!"
echo "URL: $NGINX_URL"

# Wait for Nginx to start
sleep 10

# Test V1
print_info "Testing V1..."
if curl -s -o /dev/null -w "%{http_code}" $NGINX_IP | grep -q "200"; then
    print_success "V1 is responding"
    echo ""
    echo "Opening V1 in the browser..."
    xdg-open $NGINX_URL 2>/dev/null || open $NGINX_URL 2>/dev/null || echo "Open: $NGINX_URL"
else
    print_error "V1 is not responding"
fi

pause_demo

# ==========================================
# PART 2: BUILD AND DEPLOY V2
# ==========================================

print_step "🆕 PART 2: BUILD AND DEPLOY V2"

print_info "Backing up the original playbook..."
cp "$ANSIBLE_PLAYBOOK" "$ANSIBLE_PLAYBOOK.v1"

print_info "Creating version 2 of the content..."
cat > "$ANSIBLE_PLAYBOOK" << 'EOFANSIBLE'
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

print_success "V2 content created"

print_info "Building V2 image with Packer..."
if packer build -var-file="$PACKER_VARS" "$PACKER_TEMPLATE"; then
    print_success "V2 image created"
else
    print_error "Failed to create V2 image"
    exit 1
fi

# Capture the V2 image name
export IMAGE_V2=$(gcloud compute images list \
    --filter="family:nginx-immutable-family" \
    --format="value(name)" \
    --sort-by=~creationTimestamp \
    --limit=1)

print_success "V2 image: $IMAGE_V2"

echo ""
print_info "There are now 2 images available:"
gcloud compute images list --filter="family:nginx-immutable-family" \
    --format="table(name,family,creationTimestamp)" \
    --sort-by=creationTimestamp

pause_demo

print_info "Deploying V2..."
cd "$TERRAFORM_DIR"
terraform apply -replace=google_compute_instance.nginx_server -auto-approve
cd "$ROOT_DIR"

sleep 10

print_success "V2 deployed!"
echo "URL: $NGINX_URL"

print_info "Testing V2..."
if curl -s $NGINX_IP | grep -q "VERSÃO 2.0"; then
    print_success "V2 is responding with the new content"
    echo ""
    echo "Opening V2 in the browser..."
    xdg-open $NGINX_URL 2>/dev/null || open $NGINX_URL 2>/dev/null || echo "Open: $NGINX_URL"
else
    print_error "V2 is not responding correctly"
fi

pause_demo

# ==========================================
# PART 3: ROLLBACK TO V1
# ==========================================

print_step "🔄 PART 3: ROLLBACK TO V1"

print_info "Simulating a problem in V2... starting rollback"

# Point Terraform at the specific V1 image
print_info "Forcing the use of the V1 image..."

cd "$TERRAFORM_DIR"

# Back up main.tf
cp main.tf main.tf.backup

# Create a version pinned to a specific image
sed "s|family  = var.image_family|name    = \"$IMAGE_V1\"|" main.tf.backup > main.tf

print_info "Running rollback..."
terraform apply -replace=google_compute_instance.nginx_server -auto-approve

# Restore main.tf
mv main.tf.backup main.tf

cd "$ROOT_DIR"

sleep 10

print_success "Rollback complete"

print_info "Testing V1 (rollback)..."
if curl -s $NGINX_IP | grep -q "Immutable Infrastructure - Demo"; then
    print_success "Rollback succeeded - back on V1"
    echo ""
    echo "Opening V1 (restored) in the browser..."
    xdg-open $NGINX_URL 2>/dev/null || open $NGINX_URL 2>/dev/null || echo "Open: $NGINX_URL"
else
    print_error "Rollback did not work as expected"
fi

# Restore the Ansible playbook back to V1
if [ -f "$ANSIBLE_PLAYBOOK.v1" ]; then
    mv "$ANSIBLE_PLAYBOOK.v1" "$ANSIBLE_PLAYBOOK"
    print_success "Ansible playbook restored to V1"
fi

# ==========================================
# SUMMARY
# ==========================================

print_step "📊 DEMO SUMMARY"

echo "✅ PART 1: Initial V1 deploy"
echo "   - Image: $IMAGE_V1"
echo "   - Original design"
echo ""
echo "✅ PART 2: Update to V2"
echo "   - Image: $IMAGE_V2"
echo "   - Purple gradient design"
echo ""
echo "✅ PART 3: Rollback to V1"
echo "   - Rolled back to: $IMAGE_V1"
echo "   - Original design restored"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎓 CONCEPTS DEMONSTRATED:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "♻️  IMMUTABILITY:"
echo "   Servers are never modified, always replaced by new versions"
echo ""
echo "📦 VERSIONING:"
echo "   Multiple images coexist, making rollback easy"
echo ""
echo "🔄 FAST ROLLBACK:"
echo "   Return to any version in minutes"
echo ""
echo "🎯 RELIABILITY:"
echo "   Same image = same result, every time"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
print_info "Images available on GCP:"
gcloud compute images list --filter="family:nginx-immutable-family" \
    --format="table(name,family,diskSizeGb,status)"

echo ""
print_success "🎉 DEMO COMPLETE"
echo ""
echo "Application URL: $NGINX_URL"
echo ""
echo "To clean up resources:"
echo "  ./bin/deploy.sh --cloud gcp --destroy"

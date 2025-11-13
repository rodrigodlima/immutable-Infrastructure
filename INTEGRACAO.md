# 🔗 Integração Completa: Packer + Ansible + Terraform

## 📋 Visão Geral da Integração

Este guia mostra como os três componentes trabalham juntos para criar infraestrutura imutável.

```
ANSIBLE ──> PACKER ──> TERRAFORM
  ↓           ↓           ↓
Config    Imagem      Infra
```

## 🎯 Fluxo Completo de Integração

### ETAPA 1: Preparar Ambiente (5 minutos)

```bash
# 1.1 - Configurar projeto GCP
export PROJECT_ID="seu-projeto-gcp"
export ZONE="us-central1-a"
export REGION="us-central1"

gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

# 1.2 - Habilitar APIs necessárias
gcloud services enable compute.googleapis.com \
  cloudresourcemanager.googleapis.com \
  servicemanagement.googleapis.com \
  storage.googleapis.com

# 1.3 - Criar credenciais
gcloud auth application-default login

# 1.4 - Verificar autenticação
gcloud auth application-default print-access-token
```

### ETAPA 2: Configurar Variáveis (3 minutos)

```bash
# 2.1 - Criar arquivo de variáveis do Packer
cat > packer/variables.pkrvars.hcl <<EOF
project_id   = "$PROJECT_ID"
zone         = "$ZONE"
image_name   = "nginx-immutable"
image_family = "nginx-immutable-family"
EOF

# 2.2 - Criar arquivo de variáveis do Terraform
cat > terraform/terraform.tfvars <<EOF
project_id    = "$PROJECT_ID"
region        = "$REGION"
zone          = "$ZONE"
instance_name = "nginx-immutable-demo"
machine_type  = "e2-micro"
image_family  = "nginx-immutable-family"
environment   = "demo"
EOF

# 2.3 - Verificar configurações
echo "=== Configuração Packer ==="
cat packer/variables.pkrvars.hcl

echo -e "\n=== Configuração Terraform ==="
cat terraform/terraform.tfvars
```

### ETAPA 3: Validar Configurações (2 minutos)

```bash
# 3.1 - Validar playbook Ansible
echo "Validando Ansible..."
ansible-playbook ansible/nginx.yml --syntax-check

# 3.2 - Validar template Packer
echo "Validando Packer..."
packer validate -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 3.3 - Validar configuração Terraform
echo "Validando Terraform..."
cd terraform
terraform init
terraform validate
cd ..

echo "✅ Todas as validações passaram!"
```

### ETAPA 4: Criar Imagem com Packer (8-10 minutos)

```bash
# 4.1 - Iniciar build do Packer
echo "=== Iniciando build da imagem ==="
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Saída esperada:
# ==> googlecompute: Creating temporary RSA SSH key...
# ==> googlecompute: Using image: ubuntu-2204-jammy-v20240319
# ==> googlecompute: Creating instance...
# ==> googlecompute: Waiting for the instance to become running...
# ==> googlecompute: Provisioning with Ansible...
# ==> googlecompute: Deleting instance...
# ==> googlecompute: Creating image nginx-immutable-20240512123456...
# Build 'googlecompute.nginx' finished after 8 minutes 32 seconds.

# 4.2 - Verificar imagem criada
echo -e "\n=== Verificando imagem criada ==="
gcloud compute images list --filter="family:nginx-immutable-family"

# 4.3 - Ver detalhes da imagem
IMAGE_NAME=$(gcloud compute images list \
  --filter="family:nginx-immutable-family" \
  --format="value(name)" \
  --limit=1)

echo -e "\n=== Detalhes da imagem: $IMAGE_NAME ==="
gcloud compute images describe $IMAGE_NAME --format=json | jq '{
  name: .name,
  family: .family,
  status: .status,
  diskSizeGb: .diskSizeGb,
  labels: .labels,
  creationTimestamp: .creationTimestamp
}'

# 4.4 - Ver manifest do Packer
if [ -f "packer-manifest.json" ]; then
  echo -e "\n=== Manifest do Packer ==="
  cat packer-manifest.json | jq
fi
```

### ETAPA 5: Provisionar Infraestrutura com Terraform (5 minutos)

```bash
# 5.1 - Inicializar Terraform (se ainda não fez)
cd terraform
terraform init

# 5.2 - Ver plano de execução
echo "=== Plano de Execução ==="
terraform plan -out=tfplan

# Saída esperada:
# Terraform will perform the following actions:
#   + google_compute_address.nginx_static_ip
#   + google_compute_firewall.allow_http
#   + google_compute_firewall.allow_ssh
#   + google_compute_instance.nginx_server
# Plan: 4 to add, 0 to change, 0 to destroy.

# 5.3 - Aplicar mudanças
echo -e "\n=== Aplicando mudanças ==="
terraform apply tfplan

# 5.4 - Ver outputs
echo -e "\n=== Informações da Infraestrutura ==="
terraform output

# Saída esperada:
# external_ip = "34.xxx.xxx.xxx"
# image_family = "nginx-immutable-family"
# image_used = "nginx-immutable-20240512123456"
# instance_id = "1234567890123456789"
# instance_name = "nginx-immutable-demo"
# instance_tags = tolist(["http-server", "immutable-infrastructure", "nginx-server"])
# instance_zone = "us-central1-a"
# nginx_url = "http://34.xxx.xxx.xxx"
# ssh_command = "gcloud compute ssh nginx-immutable-demo --zone=us-central1-a"

cd ..
```

### ETAPA 6: Validar Deployment (2 minutos)

```bash
# 6.1 - Obter informações
cd terraform
NGINX_IP=$(terraform output -raw external_ip)
NGINX_URL=$(terraform output -raw nginx_url)
SSH_CMD=$(terraform output -raw ssh_command)
cd ..

# 6.2 - Testar HTTP
echo "=== Testando HTTP ==="
echo "URL: $NGINX_URL"
curl -I $NGINX_IP

# 6.3 - Obter conteúdo HTML
echo -e "\n=== Conteúdo da Página ==="
curl $NGINX_IP

# 6.4 - Testar SSH (opcional)
echo -e "\n=== Comando SSH ==="
echo "$SSH_CMD"

# 6.5 - Abrir no navegador (Linux)
if command -v xdg-open &> /dev/null; then
  xdg-open $NGINX_URL
fi

# 6.6 - Abrir no navegador (macOS)
if command -v open &> /dev/null; then
  open $NGINX_URL
fi
```

### ETAPA 7: Monitorar Recursos (opcional)

```bash
# 7.1 - Status da instância
gcloud compute instances describe nginx-immutable-demo \
  --zone=us-central1-a \
  --format=json | jq '{
    name: .name,
    status: .status,
    machineType: .machineType,
    networkInterfaces: .networkInterfaces[0].networkIP,
    externalIp: .networkInterfaces[0].accessConfigs[0].natIP
  }'

# 7.2 - Logs de inicialização
gcloud compute instances get-serial-port-output \
  nginx-immutable-demo \
  --zone=us-central1-a

# 7.3 - Métricas de CPU/Memória
gcloud compute instances describe nginx-immutable-demo \
  --zone=us-central1-a \
  --format="table(
    status,
    cpuPlatform,
    scheduling.automaticRestart,
    scheduling.preemptible
  )"
```

## 🔄 Workflow de Atualização

### Cenário: Atualizar versão do Nginx ou configuração

```bash
# 1. Modificar playbook Ansible
nano ansible/nginx.yml

# 2. Validar mudanças
ansible-playbook ansible/nginx.yml --syntax-check

# 3. Criar nova imagem
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 4. Ver novas imagens disponíveis
gcloud compute images list --filter="family:nginx-immutable-family" \
  --format="table(name,family,creationTimestamp)"

# 5. Recriar instância com nova imagem
cd terraform
terraform apply -replace=google_compute_instance.nginx_server

# 6. Validar nova versão
NGINX_IP=$(terraform output -raw external_ip)
curl $NGINX_IP
```

## 🎯 Workflow de Blue-Green Deployment

```bash
# 1. Criar nova imagem (Green)
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 2. Criar nova instância Green (sem destruir Blue)
cd terraform
terraform apply -var="instance_name=nginx-green"

# 3. Testar Green
GREEN_IP=$(terraform output -raw external_ip)
curl http://$GREEN_IP

# 4. Trocar tráfego (atualizar Load Balancer ou DNS)
# ... (configuração de load balancer)

# 5. Monitorar por algum tempo

# 6. Destruir instância Blue
terraform destroy -target=google_compute_instance.nginx_blue
```

## 🧹 Limpeza Completa

```bash
# 1. Destruir infraestrutura Terraform
cd terraform
terraform destroy -auto-approve
cd ..

# 2. Deletar todas as imagens (opcional)
echo "Deletando imagens..."
gcloud compute images list \
  --filter="family:nginx-immutable-family" \
  --format="value(name)" | \
  xargs -I {} gcloud compute images delete {} --quiet

# 3. Verificar limpeza
echo -e "\n=== Verificando recursos restantes ==="
gcloud compute instances list
gcloud compute images list --filter="family:nginx-immutable-family"
gcloud compute addresses list

echo "✅ Limpeza completa!"
```

## 🐛 Debug e Troubleshooting

### Se o Packer Falhar

```bash
# 1. Executar em modo debug
PACKER_LOG=1 packer build \
  -var-file=packer/variables.pkrvars.hcl \
  packer/gce-nginx.pkr.hcl

# 2. Verificar logs
cat packer.log

# 3. Verificar conectividade SSH
gcloud compute firewall-rules list

# 4. Criar regra temporária se necessário
gcloud compute firewall-rules create allow-packer-ssh \
  --allow tcp:22 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=packer
```

### Se o Terraform Falhar

```bash
# 1. Ver logs detalhados
TF_LOG=DEBUG terraform apply

# 2. Verificar state
terraform show

# 3. Listar recursos
terraform state list

# 4. Refresh state
terraform refresh

# 5. Importar recurso existente (se necessário)
terraform import google_compute_instance.nginx_server \
  projects/$PROJECT_ID/zones/$ZONE/instances/nginx-immutable-demo
```

### Se o Nginx Não Responder

```bash
# 1. Verificar status da instância
gcloud compute instances describe nginx-immutable-demo \
  --zone=us-central1-a \
  --format="value(status)"

# 2. Ver logs de startup
gcloud compute instances get-serial-port-output \
  nginx-immutable-demo \
  --zone=us-central1-a | tail -50

# 3. SSH na instância
gcloud compute ssh nginx-immutable-demo --zone=us-central1-a

# 4. Dentro da instância, verificar Nginx
sudo systemctl status nginx
sudo journalctl -u nginx -n 50
sudo nginx -t
curl localhost
```

## 📊 Monitoramento de Custos

```bash
# Ver estimativa de custos
gcloud compute instances describe nginx-immutable-demo \
  --zone=us-central1-a \
  --format="table(
    name,
    machineType,
    status,
    networkInterfaces[0].accessConfigs[0].natIP
  )"

# Calcular custos aproximados
echo "Estimativa mensal (e2-micro):"
echo "Instância: ~$7.00"
echo "IP estático: ~$3.00"
echo "Imagens: ~$0.10"
echo "Total: ~$10.10/mês"
```

## 🎓 Próximas Integrações

### Adicionar CI/CD

```yaml
# .gitlab-ci.yml ou .github/workflows/deploy.yml
stages:
  - validate
  - build
  - deploy

validate:
  script:
    - ansible-playbook ansible/nginx.yml --syntax-check
    - packer validate packer/gce-nginx.pkr.hcl
    - terraform validate

build:
  script:
    - packer build packer/gce-nginx.pkr.hcl

deploy:
  script:
    - terraform apply -auto-approve
```

### Adicionar Secrets Management

```bash
# Usar Google Secret Manager
gcloud secrets create nginx-config --data-file=nginx.conf
gcloud secrets versions access latest --secret=nginx-config
```

### Adicionar Monitoring

```bash
# Habilitar Cloud Monitoring
gcloud services enable monitoring.googleapis.com

# Criar alerta
gcloud alpha monitoring policies create \
  --notification-channels=$CHANNEL_ID \
  --display-name="Nginx Down" \
  --condition-display-name="Nginx HTTP Check" \
  --condition-threshold-value=1 \
  --condition-threshold-duration=60s
```

---

## ✅ Checklist de Integração

- [ ] Ambiente GCP configurado
- [ ] Variáveis criadas (Packer + Terraform)
- [ ] Validações executadas (Ansible + Packer + Terraform)
- [ ] Imagem criada com Packer
- [ ] Infraestrutura provisionada com Terraform
- [ ] Nginx acessível via HTTP
- [ ] Documentação lida
- [ ] Testes de atualização realizados
- [ ] Processo de limpeza testado

**🎉 Parabéns! Você tem uma infraestrutura imutável completa funcionando!**

# 🔧 Comandos Úteis - Referência Rápida

## 📦 Packer

### Build e Validação
```bash
# Validar template
packer validate -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Build da imagem
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Build em modo debug (mantém VM em caso de erro)
packer build -debug -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Build com output verboso
PACKER_LOG=1 packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# Ver manifest gerado
cat packer-manifest.json | jq
```

### Gerenciar Imagens
```bash
# Listar imagens da família
gcloud compute images list --filter="family:nginx-immutable-family"

# Ver detalhes da imagem mais recente
gcloud compute images describe-from-family nginx-immutable-family

# Ver labels de uma imagem
gcloud compute images describe IMAGE_NAME --format="value(labels)"

# Deletar imagem específica
gcloud compute images delete IMAGE_NAME

# Deletar todas as imagens da família
gcloud compute images list --filter="family:nginx-immutable-family" --format="value(name)" | \
  xargs -I {} gcloud compute images delete {} --quiet
```

## 🏗️ Terraform

### Inicialização e Validação
```bash
cd terraform

# Inicializar (primeira vez)
terraform init

# Atualizar providers
terraform init -upgrade

# Validar configuração
terraform validate

# Formatar código
terraform fmt -recursive
```

### Plan e Apply
```bash
# Ver plano de execução
terraform plan

# Salvar plano em arquivo
terraform plan -out=tfplan

# Aplicar mudanças
terraform apply

# Aplicar plano salvo
terraform apply tfplan

# Aplicar sem confirmação (use com cuidado!)
terraform apply -auto-approve

# Aplicar apenas recurso específico
terraform apply -target=google_compute_instance.nginx_server
```

### Outputs e State
```bash
# Ver todos os outputs
terraform output

# Ver output específico (raw)
terraform output -raw nginx_url

# Ver estado atual
terraform show

# Listar recursos no state
terraform state list

# Ver detalhes de recurso específico
terraform state show google_compute_instance.nginx_server

# Refresh do state (sincronizar com realidade)
terraform refresh
```

### Destroy e Recreate
```bash
# Destruir tudo
terraform destroy

# Destruir sem confirmação
terraform destroy -auto-approve

# Destruir recurso específico
terraform destroy -target=google_compute_instance.nginx_server

# Recriar recurso (taint + apply)
terraform apply -replace=google_compute_instance.nginx_server

# Forçar recriação na próxima aplicação
terraform taint google_compute_instance.nginx_server
terraform apply
```

### Workspaces (Ambientes)
```bash
# Listar workspaces
terraform workspace list

# Criar workspace
terraform workspace new staging

# Trocar workspace
terraform workspace select production

# Deletar workspace
terraform workspace delete staging
```

## 🎭 Ansible

### Validação e Teste
```bash
# Verificar sintaxe do playbook
ansible-playbook ansible/nginx.yml --syntax-check

# Dry-run (não executa, apenas simula)
ansible-playbook ansible/nginx.yml --check

# Listar tasks do playbook
ansible-playbook ansible/nginx.yml --list-tasks

# Executar apenas tasks específicas
ansible-playbook ansible/nginx.yml --tags "install"

# Pular tasks específicas
ansible-playbook ansible/nginx.yml --skip-tags "config"
```

### Execução Local (Teste)
```bash
# Executar localmente
ansible-playbook ansible/nginx.yml -i localhost, --connection=local

# Com sudo
ansible-playbook ansible/nginx.yml -i localhost, --connection=local --become

# Modo verbose
ansible-playbook ansible/nginx.yml -v
ansible-playbook ansible/nginx.yml -vv
ansible-playbook ansible/nginx.yml -vvv
```

## ☁️ GCP / gcloud

### Configuração
```bash
# Listar projetos
gcloud projects list

# Configurar projeto padrão
gcloud config set project PROJECT_ID

# Ver configuração atual
gcloud config list

# Autenticar
gcloud auth login
gcloud auth application-default login

# Listar contas autenticadas
gcloud auth list
```

### Compute Engine
```bash
# Listar instâncias
gcloud compute instances list

# Ver detalhes da instância
gcloud compute instances describe nginx-immutable-demo --zone=us-central1-a

# SSH na instância
gcloud compute ssh nginx-immutable-demo --zone=us-central1-a

# Ligar/desligar instância
gcloud compute instances start nginx-immutable-demo --zone=us-central1-a
gcloud compute instances stop nginx-immutable-demo --zone=us-central1-a

# Deletar instância
gcloud compute instances delete nginx-immutable-demo --zone=us-central1-a

# Ver logs serial da instância
gcloud compute instances get-serial-port-output nginx-immutable-demo --zone=us-central1-a
```

### Firewall
```bash
# Listar regras de firewall
gcloud compute firewall-rules list

# Ver detalhes de regra
gcloud compute firewall-rules describe allow-http-nginx-demo

# Criar regra
gcloud compute firewall-rules create RULE_NAME \
  --allow tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=nginx-server

# Deletar regra
gcloud compute firewall-rules delete RULE_NAME
```

### IPs e Networking
```bash
# Listar IPs estáticos
gcloud compute addresses list

# Criar IP estático
gcloud compute addresses create IP_NAME --region=us-central1

# Deletar IP estático
gcloud compute addresses delete IP_NAME --region=us-central1

# Ver informações de rede
gcloud compute networks list
gcloud compute networks describe default
```

### Quotas e Limites
```bash
# Ver quotas do projeto
gcloud compute project-info describe --project=PROJECT_ID

# Ver quotas de região específica
gcloud compute regions describe us-central1
```

## 🔍 Debugging e Monitoramento

### Logs da Instância
```bash
# Via gcloud
gcloud compute instances get-serial-port-output nginx-immutable-demo --zone=us-central1-a

# Via SSH
gcloud compute ssh nginx-immutable-demo --zone=us-central1-a
sudo journalctl -u nginx -f
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Teste de Conectividade
```bash
# Obter IP da instância
NGINX_IP=$(cd terraform && terraform output -raw external_ip)

# Testar HTTP
curl -v http://$NGINX_IP
curl -I http://$NGINX_IP

# Testar porta
nc -zv $NGINX_IP 80

# Testar DNS
nslookup $NGINX_IP
dig $NGINX_IP
```

### Performance
```bash
# Testar latência
ping $NGINX_IP

# Benchmark simples
ab -n 1000 -c 10 http://$NGINX_IP/

# Requisições concorrentes
siege -c 100 -t 1M http://$NGINX_IP/
```

## 🛠️ Manutenção

### Atualizar Stack Completa
```bash
# 1. Modificar playbook Ansible
nano ansible/nginx.yml

# 2. Validar mudanças
ansible-playbook ansible/nginx.yml --syntax-check

# 3. Criar nova imagem
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl

# 4. Recriar instância
cd terraform
terraform apply -replace=google_compute_instance.nginx_server
```

### Rollback
```bash
# 1. Listar imagens antigas
gcloud compute images list --filter="family:nginx-immutable-family"

# 2. No Terraform, modificar para usar imagem específica
# Editar main.tf para apontar para imagem antiga

# 3. Aplicar
terraform apply -replace=google_compute_instance.nginx_server
```

### Backup
```bash
# Backup do state do Terraform
cd terraform
cp terraform.tfstate terraform.tfstate.backup

# Criar snapshot do disco da instância
gcloud compute disks snapshot nginx-immutable-demo \
  --zone=us-central1-a \
  --snapshot-names=nginx-backup-$(date +%Y%m%d)
```

## 📊 Monitoramento de Custos

```bash
# Ver estimativa de custos (requer configuração de billing)
gcloud beta billing projects describe PROJECT_ID

# Listar recursos que geram custo
gcloud compute instances list --format="table(name,zone,machineType,status)"
gcloud compute addresses list --format="table(name,region,status)"
gcloud compute images list --format="table(name,diskSizeGb)"
```

## 🔐 Segurança

```bash
# Verificar regras de firewall abertas
gcloud compute firewall-rules list --filter="sourceRanges:0.0.0.0/0"

# Verificar instâncias sem tags
gcloud compute instances list --filter="-tags:*"

# Ver service accounts usadas
gcloud iam service-accounts list

# Auditar permissões do projeto
gcloud projects get-iam-policy PROJECT_ID
```

## 💡 Dicas

### Aliases Úteis
Adicione ao seu `.bashrc` ou `.zshrc`:

```bash
# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfo='terraform output'

# Packer
alias pk='packer'
alias pkv='packer validate'
alias pkb='packer build'

# GCloud
alias gci='gcloud compute instances'
alias gcil='gcloud compute instances list'
alias gcim='gcloud compute images'
alias gciml='gcloud compute images list'

# Projeto
alias deploy-full='./deploy.sh --full'
alias deploy-packer='./deploy.sh --packer'
alias deploy-tf='./deploy.sh --terraform'
```

### Variáveis de Ambiente Úteis
```bash
# Terraform
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Packer
export PACKER_LOG=1
export PACKER_LOG_PATH=./packer.log

# GCloud
export CLOUDSDK_CORE_PROJECT=seu-projeto-gcp
export CLOUDSDK_COMPUTE_ZONE=us-central1-a
```

---

**Dica:** Adicione este arquivo aos favoritos para referência rápida!

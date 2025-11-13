# 🚀 Quick Start - 5 Minutos para Deploy

## Pré-requisitos
- Google Cloud SDK instalado e configurado
- Terraform, Packer e Ansible instalados
- Projeto GCP ativo

## Comandos Rápidos

### 1. Configurar Projeto GCP
```bash
export PROJECT_ID="seu-projeto-gcp"
gcloud config set project $PROJECT_ID
gcloud services enable compute.googleapis.com
gcloud auth application-default login
```

### 2. Configurar Variáveis
```bash
# Packer
cp packer/variables.pkrvars.hcl.example packer/variables.pkrvars.hcl
nano packer/variables.pkrvars.hcl  # Adicionar seu project_id

# Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
nano terraform/terraform.tfvars  # Adicionar seu project_id
```

### 3. Executar Deploy Automatizado
```bash
# Opção 1: Script interativo
./deploy.sh

# Opção 2: Deploy completo direto
./deploy.sh --full

# Opção 3: Passo a passo manual
./deploy.sh --packer    # Criar imagem
./deploy.sh --terraform # Deploy infraestrutura
```

### 4. Acessar Aplicação
```bash
# Obter URL
cd terraform
terraform output nginx_url

# Testar
curl $(terraform output -raw nginx_url)
```

## Limpeza
```bash
./deploy.sh --destroy
```

---

**Tempo total estimado:** 10-15 minutos (incluindo build da imagem)

Para documentação completa, veja [README.md](README.md)

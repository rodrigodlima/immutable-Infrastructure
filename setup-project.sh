#!/bin/bash

# Script para recriar toda a estrutura do projeto Infraestrutura Imutável GCP
# Uso: bash setup-project.sh

set -e

PROJECT_DIR="infraestrutura-imutavel-gcp"

echo "🚀 Criando estrutura do projeto: $PROJECT_DIR"

# Criar diretório raiz
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Criar estrutura de diretórios
echo "📁 Criando diretórios..."
mkdir -p ansible
mkdir -p packer
mkdir -p terraform

# ==========================================
# ANSIBLE
# ==========================================
echo "📝 Criando arquivo Ansible..."
cat > ansible/nginx.yml << 'EOF'
---
- name: Instalar e Configurar Nginx
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

    - name: Criar página HTML customizada
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>Infraestrutura Imutável</title>
              <style>
                  body {
                      font-family: Arial, sans-serif;
                      max-width: 800px;
                      margin: 50px auto;
                      padding: 20px;
                      background-color: #f0f0f0;
                  }
                  .container {
                      background-color: white;
                      padding: 30px;
                      border-radius: 10px;
                      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                  }
                  h1 {
                      color: #4285f4;
                  }
                  .badge {
                      display: inline-block;
                      padding: 5px 10px;
                      margin: 5px;
                      background-color: #34a853;
                      color: white;
                      border-radius: 5px;
                  }
              </style>
          </head>
          <body>
              <div class="container">
                  <h1>🚀 Infraestrutura Imutável - Demo</h1>
                  <p><strong>Esta instância foi provisionada usando:</strong></p>
                  <div>
                      <span class="badge">Packer</span>
                      <span class="badge">Ansible</span>
                      <span class="badge">Terraform</span>
                      <span class="badge">GCP</span>
                  </div>
                  <hr>
                  <p>✅ Nginx instalado via Ansible</p>
                  <p>✅ Imagem criada pelo Packer</p>
                  <p>✅ Instância provisionada pelo Terraform</p>
                  <p>✅ Infraestrutura 100% imutável</p>
                  <hr>
                  <p><em>Hostname: {{ ansible_hostname }}</em></p>
                  <p><em>Build Time: {{ ansible_date_time.iso8601 }}</em></p>
              </div>
          </body>
          </html>
        dest: /var/www/html/index.html
        mode: '0644'

    - name: Garantir que o Nginx está rodando e habilitado
      systemd:
        name: nginx
        state: started
        enabled: yes

    - name: Configurar firewall para permitir HTTP
      ufw:
        rule: allow
        port: '80'
        proto: tcp
      ignore_errors: yes

    - name: Verificar status do Nginx
      command: nginx -t
      register: nginx_test
      changed_when: false

    - name: Exibir status do Nginx
      debug:
        msg: "Nginx configurado com sucesso: {{ nginx_test.stdout }}"
EOF

# ==========================================
# PACKER
# ==========================================
echo "📝 Criando arquivos Packer..."
cat > packer/gce-nginx.pkr.hcl << 'EOF'
packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
    ansible = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "project_id" {
  type        = string
  description = "ID do projeto GCP"
}

variable "zone" {
  type        = string
  description = "Zona do GCP"
  default     = "us-central1-a"
}

variable "image_name" {
  type        = string
  description = "Nome da imagem a ser criada"
  default     = "nginx-immutable"
}

variable "image_family" {
  type        = string
  description = "Família da imagem"
  default     = "nginx-immutable-family"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  image_name_with_timestamp = "${var.image_name}-${local.timestamp}"
}

source "googlecompute" "nginx" {
  project_id          = var.project_id
  source_image_family = "ubuntu-2204-lts"
  zone                = var.zone
  image_name          = local.image_name_with_timestamp
  image_family        = var.image_family
  ssh_username        = "packer"
  machine_type        = "e2-medium"
  
  image_labels = {
    environment = "demo"
    managed_by  = "packer"
    tool        = "ansible"
    app         = "nginx"
    created     = local.timestamp
  }

  image_description = "Imagem Ubuntu 22.04 com Nginx instalado via Ansible - Infraestrutura Imutável"

  tags = ["packer", "nginx", "immutable-infrastructure"]
}

build {
  name = "nginx-immutable-image"
  
  sources = ["source.googlecompute.nginx"]

  provisioner "shell" {
    inline = [
      "echo 'Aguardando cloud-init...'",
      "sudo cloud-init status --wait",
      "echo 'Cloud-init concluído!'",
      "sudo apt-get update"
    ]
  }

  provisioner "ansible" {
    playbook_file = "./ansible/nginx.yml"
    user          = "packer"
    use_proxy     = false
    
    extra_arguments = [
      "--extra-vars",
      "ansible_python_interpreter=/usr/bin/python3"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo 'Limpando cache e arquivos temporários...'",
      "sudo apt-get clean",
      "sudo apt-get autoremove -y",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*",
      "echo 'Imagem otimizada e pronta!'"
    ]
  }

  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
EOF

cat > packer/variables.pkrvars.hcl.example << 'EOF'
# Arquivo de exemplo de variáveis do Packer
# Copie este arquivo para variables.pkrvars.hcl e preencha com seus valores

# OBRIGATÓRIO: ID do seu projeto GCP
project_id = "seu-projeto-gcp"

# Zona do GCP
zone = "us-central1-a"

# Nome base da imagem
image_name = "nginx-immutable"

# Família da imagem (IMPORTANTE: use o mesmo nome no Terraform)
image_family = "nginx-immutable-family"
EOF

# ==========================================
# TERRAFORM
# ==========================================
echo "📝 Criando arquivos Terraform..."
cat > terraform/main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_compute_image" "nginx_image" {
  family  = var.image_family
  project = var.project_id
}

resource "google_compute_address" "nginx_static_ip" {
  name   = "${var.instance_name}-static-ip"
  region = var.region
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-nginx-demo"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nginx-server"]

  description = "Permite tráfego HTTP para o servidor Nginx"
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-nginx-demo"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nginx-server"]

  description = "Permite acesso SSH para administração"
}

resource "google_compute_instance" "nginx_server" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["nginx-server", "immutable-infrastructure", "http-server"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.nginx_image.self_link
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.nginx_static_ip.address
    }
  }

  metadata = {
    environment          = var.environment
    managed_by           = "terraform"
    immutable_infrastructure = "true"
    image_family         = var.image_family
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    app         = "nginx"
    type        = "immutable"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    echo "Instância iniciada - Infraestrutura Imutável" >> /var/log/startup.log
    echo "Imagem: ${data.google_compute_image.nginx_image.name}" >> /var/log/startup.log
    echo "Timestamp: $(date)" >> /var/log/startup.log
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
EOF

cat > terraform/variables.tf << 'EOF'
variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "Região do GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona do GCP"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Nome da instância GCE"
  type        = string
  default     = "nginx-immutable-demo"
}

variable "machine_type" {
  description = "Tipo de máquina GCE"
  type        = string
  default     = "e2-micro"
}

variable "image_family" {
  description = "Família da imagem criada pelo Packer"
  type        = string
  default     = "nginx-immutable-family"
}

variable "environment" {
  description = "Ambiente de deployment"
  type        = string
  default     = "demo"
}
EOF

cat > terraform/outputs.tf << 'EOF'
output "instance_name" {
  description = "Nome da instância GCE"
  value       = google_compute_instance.nginx_server.name
}

output "instance_id" {
  description = "ID da instância GCE"
  value       = google_compute_instance.nginx_server.instance_id
}

output "external_ip" {
  description = "Endereço IP público da instância"
  value       = google_compute_address.nginx_static_ip.address
}

output "nginx_url" {
  description = "URL para acessar o Nginx"
  value       = "http://${google_compute_address.nginx_static_ip.address}"
}

output "ssh_command" {
  description = "Comando SSH para acessar a instância"
  value       = "gcloud compute ssh ${google_compute_instance.nginx_server.name} --zone=${var.zone}"
}

output "image_used" {
  description = "Imagem utilizada para criar a instância"
  value       = data.google_compute_image.nginx_image.name
}

output "image_family" {
  description = "Família da imagem utilizada"
  value       = data.google_compute_image.nginx_image.family
}

output "instance_zone" {
  description = "Zona onde a instância está rodando"
  value       = google_compute_instance.nginx_server.zone
}

output "instance_tags" {
  description = "Tags da instância"
  value       = google_compute_instance.nginx_server.tags
}
EOF

cat > terraform/terraform.tfvars.example << 'EOF'
# Arquivo de exemplo de variáveis do Terraform
# Copie este arquivo para terraform.tfvars e preencha com seus valores

# OBRIGATÓRIO: ID do seu projeto GCP
project_id = "seu-projeto-gcp"

# Região e zona do GCP (opcional - já tem defaults)
region = "us-central1"
zone   = "us-central1-a"

# Nome da instância (opcional)
instance_name = "nginx-immutable-demo"

# Tipo de máquina (opcional - e2-micro para free tier)
machine_type = "e2-micro"

# Família da imagem criada pelo Packer (deve ser o mesmo nome usado no Packer)
image_family = "nginx-immutable-family"

# Ambiente
environment = "demo"
EOF

# ==========================================
# GITIGNORE
# ==========================================
echo "📝 Criando .gitignore..."
cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
*.tfplan
terraform.tfvars
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Packer
packer_cache/
packer-manifest.json
*.box
variables.pkrvars.hcl

# Ansible
*.retry
.ansible/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Secrets
*.pem
*.key
credentials.json
service-account.json

# Backups
*.backup
*.bak
EOF

# ==========================================
# README
# ==========================================
echo "📝 Criando README.md..."
cat > README.md << 'EOF'
# 🚀 Demo de Infraestrutura Imutável - GCP

Demonstração completa de **Infraestrutura Imutável** usando **Packer**, **Ansible** e **Terraform** no Google Cloud Platform.

## 📋 Estrutura do Projeto

```
.
├── ansible/
│   └── nginx.yml                    # Playbook Ansible
├── packer/
│   ├── gce-nginx.pkr.hcl           # Template Packer
│   └── variables.pkrvars.hcl.example
└── terraform/
    ├── main.tf                      # Recursos principais
    ├── variables.tf                 # Definição de variáveis
    ├── outputs.tf                   # Outputs
    └── terraform.tfvars.example     # Exemplo de variáveis
```

## 🚀 Quick Start

### 1. Configurar GCP
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
nano terraform/terraform.tfvars     # Adicionar seu project_id
```

### 3. Criar Imagem
```bash
packer build -var-file=packer/variables.pkrvars.hcl packer/gce-nginx.pkr.hcl
```

### 4. Provisionar Infraestrutura
```bash
cd terraform
terraform init
terraform apply
```

### 5. Acessar
```bash
terraform output nginx_url
curl $(terraform output -raw nginx_url)
```

## 🧹 Limpeza

```bash
# Destruir infraestrutura
cd terraform
terraform destroy

# Deletar imagens (opcional)
gcloud compute images list --filter="family:nginx-immutable-family" \
  --format="value(name)" | xargs -I {} gcloud compute images delete {} --quiet
```

## 📚 Documentação

Para documentação completa, consulte os arquivos de documentação incluídos no projeto.

---

**Desenvolvido para demonstração de Infraestrutura Imutável** 🚀
EOF

echo ""
echo "✅ Projeto criado com sucesso em: $PROJECT_DIR"
echo ""
echo "📁 Estrutura criada:"
tree -L 2 "$PROJECT_DIR" 2>/dev/null || find "$PROJECT_DIR" -type f -o -type d | head -20
echo ""
echo "🚀 Próximos passos:"
echo "1. cd $PROJECT_DIR"
echo "2. Configure as variáveis nos arquivos .example"
echo "3. Execute os comandos do README.md"
echo ""
echo "🎉 Pronto para começar!"
EOF

chmod +x /mnt/user-data/outputs/setup-project.sh

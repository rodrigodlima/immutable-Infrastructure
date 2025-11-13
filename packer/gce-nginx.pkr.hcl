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
  
  # Tags para a imagem
  image_labels = {
    environment = "demo"
    managed_by  = "packer"
    tool        = "ansible"
    app         = "nginx"
    created     = local.timestamp
  }

  # Descrição da imagem
  image_description = "Imagem Ubuntu 22.04 com Nginx instalado via Ansible - Infraestrutura Imutável"

  # Tags para organização
  tags = ["packer", "nginx", "immutable-infrastructure"]
}

build {
  name = "nginx-immutable-image"
  
  sources = ["source.googlecompute.nginx"]

  # Aguardar o cloud-init terminar
  provisioner "shell" {
    inline = [
      "echo 'Aguardando cloud-init...'",
      "sudo cloud-init status --wait",
      "echo 'Cloud-init concluído!'",
      "sudo apt-get update"
    ]
  }

  # Executar o playbook Ansible
  provisioner "ansible" {
    playbook_file = "./ansible/nginx.yml"
    user          = "packer"
    use_proxy     = false
    
    # Variáveis extras para o Ansible
    extra_arguments = [
      "--extra-vars",
      "ansible_python_interpreter=/usr/bin/python3"
    ]
  }

  # Limpeza e otimização da imagem
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

  # Post-processor para exibir informações da imagem
  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}

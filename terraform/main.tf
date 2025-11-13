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

# Data source para obter a imagem mais recente da família
data "google_compute_image" "nginx_image" {
  family  = var.image_family
  project = var.project_id
}

# Criar endereço IP estático (opcional)
resource "google_compute_address" "nginx_static_ip" {
  name   = "${var.instance_name}-static-ip"
  region = var.region
}

# Criar regra de firewall para permitir HTTP
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

# Criar regra de firewall para permitir SSH
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

# Criar a instância GCE
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

  # Startup script (opcional - apenas para logging)
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

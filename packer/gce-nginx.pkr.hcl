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
  description = "GCP project ID"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "us-central1-a"
}

variable "image_name" {
  type        = string
  description = "Name of the image to be created"
  default     = "nginx-immutable"
}

variable "image_family" {
  type        = string
  description = "Image family"
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

  # Image tags
  image_labels = {
    environment = "demo"
    managed_by  = "packer"
    tool        = "ansible"
    app         = "nginx"
    created     = local.timestamp
  }

  # Image description
  image_description = "Ubuntu 22.04 image with Nginx installed via Ansible - Immutable Infrastructure"

  # Tags for organization
  tags = ["packer", "nginx", "immutable-infrastructure"]
}

build {
  name = "nginx-immutable-image"
  
  sources = ["source.googlecompute.nginx"]

  # Wait for cloud-init to finish
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init...'",
      "sudo cloud-init status --wait",
      "echo 'Cloud-init completed!'",
      "sudo apt-get update"
    ]
  }

  # Execute Ansible playbook
  provisioner "ansible" {
    playbook_file = "./ansible/nginx.yml"
    user          = "packer"
    use_proxy     = false

    # Extra variables for Ansible
    extra_arguments = [
      "--extra-vars",
      "ansible_python_interpreter=/usr/bin/python3"
    ]
  }

  # Cleanup and image optimization
  provisioner "shell" {
    inline = [
      "echo 'Cleaning cache and temporary files...'",
      "sudo apt-get clean",
      "sudo apt-get autoremove -y",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*",
      "echo 'Image optimized and ready!'"
    ]
  }

  # Post-processor to display image information
  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}

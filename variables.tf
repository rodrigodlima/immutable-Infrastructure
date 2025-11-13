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

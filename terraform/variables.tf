variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "GCE instance name"
  type        = string
  default     = "nginx-immutable-demo"
}

variable "machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "e2-micro"
}

variable "image_family" {
  description = "Image family created by Packer"
  type        = string
  default     = "nginx-immutable-family"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "demo"
}

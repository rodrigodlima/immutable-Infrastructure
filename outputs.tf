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

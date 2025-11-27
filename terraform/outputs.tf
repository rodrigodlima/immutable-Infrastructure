output "instance_name" {
  description = "GCE instance name"
  value       = google_compute_instance.nginx_server.name
}

output "instance_id" {
  description = "GCE instance ID"
  value       = google_compute_instance.nginx_server.instance_id
}

output "external_ip" {
  description = "Instance public IP address"
  value       = google_compute_address.nginx_static_ip.address
}

output "nginx_url" {
  description = "URL to access Nginx"
  value       = "http://${google_compute_address.nginx_static_ip.address}"
}

output "ssh_command" {
  description = "SSH command to access the instance"
  value       = "gcloud compute ssh ${google_compute_instance.nginx_server.name} --zone=${var.zone}"
}

output "image_used" {
  description = "Image used to create the instance"
  value       = data.google_compute_image.nginx_image.name
}

output "image_family" {
  description = "Image family used"
  value       = data.google_compute_image.nginx_image.family
}

output "instance_zone" {
  description = "Zone where the instance is running"
  value       = google_compute_instance.nginx_server.zone
}

output "instance_tags" {
  description = "Instance tags"
  value       = google_compute_instance.nginx_server.tags
}

output "NGINX_IP" {
  value = "${kubernetes.nginx.dns_name}"
}
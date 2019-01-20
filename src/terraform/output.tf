# Output IP of Nginx server
output "NGINX_IP" {
  value = "${module.kubernetes.NGINX_IP}"
}

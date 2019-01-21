output "MASTERPUBLIC" {
  value = "${join(",", aws_instance.kubernetes-master.*.public_ip)}"
}

output "MASTERPRIVATE" {
  value = "${join(",", aws_instance.kubernetes-master.*.private_ip)}"
}

output "MASTERDNS" {
  value = "${join(",", aws_instance.kubernetes-master.*.public_dns)}"
}

output "WORKERPUBLIC" {
  value = "${join(",", aws_instance.kubernetes-worker.*.public_ip)}"
}

output "WORKERPRIVATE" {
  value = "${join(",", aws_instance.kubernetes-worker.*.private_ip)}"
}

output "WORKERDNS" {
  value = "${join(",", aws_instance.kubernetes-worker.*.public_dns)}"
}

output "NGINXPUBLIC" {
  value = "${aws_instance.nginx-lb.public_ip}"
}

output "NGINXPRIVATE" {
  value = "${aws_instance.nginx-lb.private_ip}"
}

output "NGINXDNS" {
  value = "${aws_instance.nginx-lb.public_dns}"
}
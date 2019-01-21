output "MASTERPUBLICIP" {
  value = "${join(",", aws_instance.kubernetes-master.*.public_ip)}"
}

output "MASTERPRIVATEIP" {
  value = "${join(",", aws_instance.kubernetes-master.*.private_ip)}"
}

output "MASTERPUBLICDNS" {
  value = "${join(",", aws_instance.kubernetes-master.*.public_dns)}"
}

output "MASTERPRIVATEDNS" {
  value = "${join(",", aws_instance.kubernetes-master.*.private_dns)}"
}

output "WORKERPUBLICIP" {
  value = "${join(",", aws_instance.kubernetes-worker.*.public_ip)}"
}

output "WORKERPRIVATEIP" {
  value = "${join(",", aws_instance.kubernetes-worker.*.private_ip)}"
}

output "WORKERPUBLICDNS" {
  value = "${join(",", aws_instance.kubernetes-worker.*.public_dns)}"
}

output "WORKERPRIVATEDNS" {
  value = "${join(",", aws_instance.kubernetes-worker.*.private_dns)}"
}

output "NGINXPUBLICIP" {
  value = "${aws_instance.nginx-lb.public_ip}"
}

output "NGINXPRIVATEIP" {
  value = "${aws_instance.nginx-lb.private_ip}"
}

output "NGINXPUBLICDNS" {
  value = "${aws_instance.nginx-lb.public_dns}"
}

output "NGINXPRIVATEDNS" {
  value = "${aws_instance.nginx-lb.private_dns}"
}
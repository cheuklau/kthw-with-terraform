# Output public IP, private IP and public DNS of all EC2 instances

output "MASTERPUBLIC" {
  value = "${module.ec2.MASTERPUBLIC}"
}

output "MASTERPRIVATE" {
  value = "${module.ec2.MASTERPRIVATE}"
}

output "MASTERDNS" {
  value ="${module.ec2.MASTERDNS}"
}

output "WORKERPUBLIC" {
  value = "${module.ec2.WORKERPUBLIC}"
}

output "WORKERPRIVATE" {
  value = "${module.ec2.WORKERPRIVATE}"
}

output "WORKERDNS" {
  value ="${module.ec2.WORKERDNS}"
}

output "NGINXPUBLIC" {
  value = "${module.ec2.NGINXPUBLIC}"
}

output "NGINXPRIVATE" {
  value = "${module.ec2.NGINXPRIVATE}"
}

output "NGINXDNS" {
  value ="${module.ec2.NGINXDNS}"
}
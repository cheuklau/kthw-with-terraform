# Output public IP, private IP and public DNS of all EC2 instances

output "MASTERPUBLICIP" {
  value = "${module.ec2.MASTERPUBLICIP}"
}

output "MASTERPUBLICLISTIP" {
  value = ["${module.ec2.MASTERPUBLICLISTIP}"]
}

output "MASTERPRIVATEIP" {
  value = "${module.ec2.MASTERPRIVATEIP}"
}

output "MASTERPUBLICDNS" {
  value ="${module.ec2.MASTERPUBLICDNS}"
}

output "MASTERPUBLICLISTDNS" {
  value = ["${module.ec2.MASTERPUBLICLISTDNS}"]
}

output "MASTERPRIVATEDNS" {
  value ="${module.ec2.MASTERPRIVATEDNS}"
}

output "WORKERPUBLICIP" {
  value = "${module.ec2.WORKERPUBLICIP}"
}

output "WORKERPRIVATEIP" {
  value = "${module.ec2.WORKERPRIVATEIP}"
}

output "WORKERPUBLICDNS" {
  value ="${module.ec2.WORKERPUBLICDNS}"
}

output "WORKERPRIVATEDNS" {
  value ="${module.ec2.WORKERPRIVATEDNS}"
}

output "NGINXPUBLICIP" {
  value = "${module.ec2.NGINXPUBLICIP}"
}

output "NGINXPRIVATEIP" {
  value = "${module.ec2.NGINXPRIVATEIP}"
}

output "NGINXPUBLICDNS" {
  value ="${module.ec2.NGINXPUBLICDNS}"
}

output "NGINXPRIVATEDNS" {
  value ="${module.ec2.NGINXPRIVATEDNS}"
}
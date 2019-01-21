# Provision EC2 instances for Kubernetes master nodes
resource "aws_instance" "kubernetes-master" {
  ami = "ami-70e90210"
  instance_type = "${var.AWS_TYPE}"
  key_name = "${var.KEY_NAME}"
  count = "${var.NUM_MASTERS}"
  vpc_security_group_ids = ["${var.SECURITY_GROUP_ID}"]
  subnet_id = "${var.SUBNET}"
  associate_public_ip_address = true
  root_block_device {
    volume_size = 100
    volume_type = "standard"
  }
  tags {
    Name = "kubernetes-master-${count.index}"
    Environment = "dev"
    Terraform = "true"
    Cluster = "kubernetes"
    ClusterRole = "master"
  }
}

# Kubernetes workers nodes
resource "aws_instance" "kubernetes-worker" {
  ami = "ami-70e90210"
  instance_type = "${var.AWS_TYPE}"
  key_name = "${var.KEY_NAME}"
  count = "${var.NUM_WORKERS}"
  vpc_security_group_ids = ["${var.SECURITY_GROUP_ID}"]
  subnet_id = "${var.SUBNET}"
  associate_public_ip_address = true
  root_block_device {
    volume_size = 100
    volume_type = "standard"
  }
  tags {
    Name = "kubernetes-worker-${count.index}"
    Environment = "dev"
    Terraform = "true"
    Cluster = "kubernetes"
    ClusterRole = "worker"
  }
}

# Nginx load balancer node
resource "aws_instance" "nginx-lb" {
  ami = "ami-70e90210"
  instance_type = "${var.AWS_TYPE}"
  key_name = "${var.KEY_NAME}"
  vpc_security_group_ids = ["${var.SECURITY_GROUP_ID}"]
  subnet_id = "${var.SUBNET}"
  associate_public_ip_address = true
  root_block_device {
    volume_size = 100
    volume_type = "standard"
  }
  tags {
    Name = "nginx-lb"
    Environment = "dev"
    Terraform = "true"
  }
}
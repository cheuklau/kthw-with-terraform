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

# Configure master nodes
resource "null_resource" "kubernetes-master" {

  count = "${var.NUM_MASTERS}"

  # Establish connection to master
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${element(aws_instance.kubernetes-master.*.public_ip, "${count.index}")}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  #  Need the masters and workers spun up first
  depends_on = [ "aws_instance.kubernetes-master", "aws_instance.kubernetes-worker" ]

  # Execute master configuration remotely
  # Note: We copy the worker join command to a text file which will be used later by the worker nodes
  provisioner "remote-exec" {
    inline = [ 
    "echo \"net.bridge.bridge-nf-call-iptables=1\" | sudo tee -a /etc/sysctl.conf",
    "sudo sysctl -p",
    "sudo kubeadm init --pod-network-cidr=10.244.0.0/16 > join_command.txt",
    "mkdir -p $HOME/.kube",
    "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
    "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
    "https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml"
    ]
  }
}

# Configure workers
resource "null_resource" "kubernetes-workers" {

  count = "${var.NUM_WORKERS}"

  # Establish connection to workers
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${element(aws_instance.kubernetes-worker.*.public_ip, "${count.index}")}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  # Need the masters configured first
  depends_on = [ "null_resource.kubernetes-master" ]

  # Get join command from a Kubernetes master node
  provisioner "local-exec" {
    inline = [
      "scp -i ${file(\"${var.PATH_TO_PRIVATE_KEY}\")} ubuntu@\"${aws_instance.kubernetes-master.0.public_ip}\":join_command.txt ."
    ]
  }

  # Copy join command to worker node
  provisioner "file" {
    source = "./join_command.txt"
    destination = "~/join_command.txt"
  }

  # Execute worker configuration script remotely 
  provisioner "remote-exec" {
    inline = [
      "echo \"net.bridge.bridge-nf-call-iptables=1\" | sudo tee -a /etc/sysctl.conf",
      "sudo sysctl -p",
      "bash join_command.txt"
    ]
  }
}
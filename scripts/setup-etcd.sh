#!/bin/bash

PRIVATEKEY=$1
BASEDIR=$2

# Gather master private IPs
file="$(grep 'MASTERPRIVATEIP' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ MASTERPRIVATEIP\ =\ (.*) ]]
then
    IFS=, read -ra masterprivateip <<< "${BASH_REMATCH[1]}"
else
    exit "Error: private IP of master nodes not found!"
fi

# Gather master private dns
file="$(grep 'MASTERPRIVATEDNS' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ MASTERPRIVATEDNS\ =\ (.*) ]]
then
    IFS=, read -ra masterprivatedns <<< "${BASH_REMATCH[1]}"
else
    exit "Error: private DNS of master nodes not found!"
fi

# Create INITIAL_CLUSTER variable for use in Terraform main.tf
INITIAL_CLUSTER=''
for ((i=0; i<${#masterprivateip[@]};++i)); do
  INITIAL_CLUSTER=$INITIAL_CLUSTER${masterprivatedns[i]}=https://${masterprivateip[i]}:2380,
done
INITIAL_CLUSTER=${INITIAL_CLUSTER%?}

# Form Terraform main.tf file
cat << EOF >> main.tf
data "terraform_remote_state" "aws-ec2" {
  backend = "local"
  config {
    path = "${BASEDIR}/src/aws/terraform.tfstate"
  }
}
EOF

cat << "EOF" >> main.tf
resource "null_resource" "etcd-master" {
  count = "${var.NUM_MASTERS}"
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${element(data.terraform_remote_state.aws-ec2.MASTERPUBLICLISTIP, "${count.index}")}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }
EOF

cat << EOF >> main.tf
  provisioner "file" {
    source = "${BASEDIR}/src/etcd/etcd.service"
    destination = "~/etcd.service"
  }
  provisioner "file" {
    source = "${BASEDIR}/src/etcd/etcd-v3.3.9-linux-amd64.tar.gz"
    destination = "~/etcd-v3.3.9-linux-amd64.tar.gz"
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'INITIAL_CLUSTER=${INITIAL_CLUSTER}' | sudo tee -a /etc/environment",
EOF

# THERE IS SOMETHING WRONG WITH LINE 68, it shows up as curl... as the environment variable
cat << "EOF" >> main.tf
      "echo 'INTERNAL_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)' | sudo tee -a /etc/environment",
      "echo 'ETCD_NAME=${element(data.terraform_remote_state.aws-ec2.MASTERPUBLICLISTDNS, "${count.index}")}' | sudo tee -a /etc/environment",
      "tar -xvf etcd-v3.3.9-linux-amd64.tar.gz",
      "sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/",
      "sudo mkdir -p /etc/etcd /var/lib/etcd",
      "sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/",
      "sudo mv etcd.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable etcd",
      "sudo systemctl start etcd"
    ]
  }
}
EOF

mv main.tf $BASEDIR/src/etcd

# Create etcd.service file
cat << "EOF" >> etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \
  --name ${ETCD_NAME} \
  --cert-file=/etc/etcd/kubernetes.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --peer-cert-file=/etc/etcd/kubernetes.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --trusted-ca-file=/etc/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \
  --listen-peer-urls https://${INTERNAL_IP}:2380 \
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://${INTERNAL_IP}:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster ${INITIAL_CLUSTER} \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

mv etcd.service $BASEDIR/src/etcd

# Apply Terraform files
cd $BASEDIR/src/etcd
terraform init
# terraform apply
echo 'Finished setting up etcd cluster'
echo '**************************************'
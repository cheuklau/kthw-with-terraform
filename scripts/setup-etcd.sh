#!/bin/bash

BASEDIR=$1

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

# Form initial cluster input for main.tf
INITIAL_CLUSTER=''
for ((i=0; i<${#masterprivateip[@]};++i)); do
  INITIAL_CLUSTER=$INITIAL_CLUSTER${masterprivatedns[i]}=https://${masterprivateip[i]}:2380,
done
INITIAL_CLUSTER=${INITIAL_CLUSTER%?}

cat << "EOF" | tee main.tf
resource "null_resource" "etcd-master" {
  count = "${var.NUM_MASTERS}"
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${element(aws_instance.kubernetes-master.*.public_ip, "${count.index}")}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }
  provisioner "remote-exec" {
    inline = [
      "wget -q --show-progress --https-only --timestamping \"https://github.com/coreos/etcd/releases/download/v3.3.5/etcd-v3.3.5-linux-amd64.tar.gz\""
      "tar -xvf etcd-v3.3.5-linux-amd64.tar.gz"
      "sudo mv etcd-v3.3.5-linux-amd64/etcd* /usr/local/bin/"
      "sudo mkdir -p /etc/etcd /var/lib/etcd"
      "sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/"
      "ETCD_NAME='${element(aws_instance.kubernetes-master.*.public_dns, "${count.index}")}'"
      "INTERNAL_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
EOF

cat << EOF >> main.tf
      "INITIAL_CLUSTER=${INITIAL_CLUSTER}"
EOF

cat << "EOF" >> main.tf
      cat << EOF | sudo tee /etc/systemd/system/etcd.service
        [Unit]
        Description=etcd
        Documentation=https://github.com/coreos
        [Service]
        ExecStart=/usr/local/bin/etcd \\
          --name ${ETCD_NAME} \\
          --cert-file=/etc/etcd/kubernetes.pem \\
          --key-file=/etc/etcd/kubernetes-key.pem \\
          --peer-cert-file=/etc/etcd/kubernetes.pem \\
          --peer-key-file=/etc/etcd/kubernetes-key.pem \\
          --trusted-ca-file=/etc/etcd/ca.pem \\
          --peer-trusted-ca-file=/etc/etcd/ca.pem \\
          --peer-client-cert-auth \\
          --client-cert-auth \\
          --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
          --listen-peer-urls https://${INTERNAL_IP}:2380 \\
          --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
          --advertise-client-urls https://${INTERNAL_IP}:2379 \\
          --initial-cluster-token etcd-cluster-0 \\
          --initial-cluster ${INITIAL_CLUSTER} \\
          --initial-cluster-state new \\
          --data-dir=/var/lib/etcd
        Restart=on-failure
        RestartSec=5
        [Install]
        WantedBy=multi-user.target
        EOF
      sudo systemctl daemon-reload
      sudo systemctl enable etcd
      sudo systemctl start etcd
    ]
  }
}

module "vpc" {
  source = "./modules/vpc"
  AWS_ACCESS_KEY = "${var.AWS_ACCESS_KEY}"
  AWS_SECRET_KEY = "${var.AWS_SECRET_KEY}"
  AWS_REGION = "${var.AWS_REGION}"
  PATH_TO_PUBLIC_KEY = "${var.PATH_TO_PUBLIC_KEY}"
}

# Provision AWS EC2 instances
module "ec2" {
  source = "./modules/ec2"
  AWS_ACCESS_KEY = "${var.AWS_ACCESS_KEY}"
  AWS_SECRET_KEY = "${var.AWS_SECRET_KEY}"
  AWS_REGION = "${var.AWS_REGION}"
  AWS_TYPE = "${var.AWS_TYPE}"
  KEY_NAME = "${module.vpc.KEY_NAME}"
  NUM_MASTERS = "${var.NUM_MASTERS}"
  SECURITY_GROUP_ID = "${module.vpc.SECURITY_GROUP_ID}"
  SUBNET = "${module.vpc.SUBNET}"
  NUM_WORKERS = "${var.NUM_WORKERS}"
  PATH_TO_PRIVATE_KEY = "${var.PATH_TO_PRIVATE_KEY}"
}
EOF
mv main.tf $BASEDIR/src/etcd

cd $BASEDIR/src/etcd
if [ -d ".terraform" ]; then
  echo 'Using previous Terraform state...'
else
  echo 'Initializing Terraform for AWS setup...'
  terraform init
fi
terraform apply
echo 'Finished setting up etcd cluster'
echo '**************************************'
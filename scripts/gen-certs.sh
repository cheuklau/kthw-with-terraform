#!/bin/bash

PRIVATEKEY=$1
BASEDIR=$2

echo ' '
echo '**************************************'
echo 'Provisioning the certificate authority...'

# Provision the certificate authority
# This creates ca-csr.json, ca-key.pem, ca.csr, ca.pem
cat > ca-csr.json << EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

# Generate the admin client certificates
# This creates ca-config.json, admin-csr.json, admin-key.pem, admin.csr, admin.pem
echo 'Generating the admin client certificates...'

cat > ca-config.json << EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > admin-csr.json << EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin

# Generate kubelet client certificates for each worker
# Requires pricate DNS and private IP of each worker
# Generates for each worker node:
# <worker-private-dns>-csr.json,
# <worker-private-dns>-key.pem,
# <worker-private-dns>.csr,
# <worker-private-dns>.pem
echo 'Generating the kubelet client certificates...'

file="$(grep 'WORKERPRIVATEDNS' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ WORKERPRIVATEDNS\ =\ (.*) ]]
then
    IFS=, read -ra workerprivatedns <<< "${BASH_REMATCH[1]}"
else
    exit "Error: private DNS of worker nodes not found!"
fi

file="$(grep 'WORKERPRIVATEIP' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ WORKERPRIVATEIP\ =\ (.*) ]]
then
    IFS=, read -ra workerprivateip <<< "${BASH_REMATCH[1]}"
else
    exit "Error: private IP of worker nodes not found!"
fi

for ((i=0; i<${#workerprivatedns[@]};++i)); do

cat > ${workerprivatedns[i]}-csr.json << EOF
{
  "CN": "system:node:${workerprivatedns[i]}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=ca-config.json \
-hostname=${workerprivateip[i]},${workerprivatedns[i]} \
-profile=kubernetes \
${workerprivatedns[i]}-csr.json | cfssljson -bare ${workerprivatedns[i]}

cat > ${workerprivatedns[i]}-csr.json << EOF
{
  "CN": "system:node:${workerprivatedns[i]}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=ca-config.json \
-hostname=${workerprivateip[i]},${workerprivatedns[i]} \
-profile=kubernetes \
${workerprivatedns[i]}-csr.json | cfssljson -bare ${workerprivatedns[i]}

done

# Generate controller-manager client certificate
# Generates:
# kube-controller-manager-csr.json
# kube-controller-manager-key.pem
# kube-controller-manager.csr
# kube-controller-manager.pem
echo 'Generating the controller-manager client certificate...'
cat > kube-controller-manager-csr.json << EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

# Generate the kube-proxy client certificate
# Generates:
# kube-proxy-csr.json
# kube-proxy-key.pem
# kube-proxy.csr
# kube-proxy.pem
echo 'Generating the kube-proxy client certificate...'
cat > kube-proxy-csr.json << EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

# Generate the kube-scheduler client certificates
# Generates:
# kube-scheduler-csr.json
# kube-scheduler-key.pem
# kube-scheduler.csr
# kube-scheduler.pem
echo 'Generating the kube-scheduler client certificate...'
cat > kube-scheduler-csr.json << EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

# Generate the kubernetes API server certificate
# Generates:
# kubernetes-csr.json
# kubernetes-key.pem
# kubernetes.csr
# kubernetes.pem
echo 'Generating the kubernetes api server certificate...'
CERT_HOSTNAME=10.32.0.1

echo $CERT_HOSTNAME

file="$(grep 'MASTERPRIVATEDNS' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ MASTERPRIVATEDNS\ =\ (.*) ]]
then
    IFS=, read -ra masterprivatedns <<< "${BASH_REMATCH[1]}"
else
    exit "Error: private DNS of master nodes not found!"
fi

file="$(grep 'MASTERPRIVATEIP' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ MASTERPRIVATEIP\ =\ (.*) ]]
then
    IFS=, read -ra masterprivateip <<< "${BASH_REMATCH[1]}"
else
    exit "Error: private IP of master nodes not found!"
fi

for ((i=0; i<${#masterprivatedns[@]};++i)); do
  CERT_HOSTNAME=$CERT_HOSTNAME,${masterprivateip[i]},${masterprivatedns[i]}
done

file="$(grep 'NGINXPRIVATEDNS' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ NGINXPRIVATEDNS\ =\ (.*) ]]
then
    IFS=, read -ra nginxprivatedns <<< "${BASH_REMATCH[1]}"
else
    exit "Error: private DNS of nginx node not found!"
fi

file="$(grep 'NGINXPRIVATEIP' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ NGINXPRIVATEIP\ =\ (.*) ]]
then
    IFS=, read -ra nginxprivateip <<< "${BASH_REMATCH[1]}"
else
    exit "Error: private IP of nginx node not found!"
fi

CERT_HOSTNAME=$CERT_HOSTNAME,$nginxprivateip,$nginxprivatedns
CERT_HOSTNAME=$CERT_HOSTNAME,127.0.0.1,localhost,kubernetes.default

cat > kubernetes-csr.json << EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${CERT_HOSTNAME} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

# Generate the service account key pair
# Generates:
# service-account-csr.json
# service-account-key.pem
# service-account.csr
# service-account.pem
echo 'Generating the service account key pair...'
cat > service-account-csr.json << EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

# Distribute certificate files
echo 'Distributing the certificate files...'

file="$(grep 'WORKERPUBLICIP' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ WORKERPUBLICIP\ =\ (.*) ]]
then
    IFS=, read -ra workerpublicip <<< "${BASH_REMATCH[1]}"
else
    exit "Error: public IP of worker nodes not found!"
fi

file="$(grep 'MASTERPUBLICIP' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ MASTERPUBLICIP\ =\ (.*) ]]
then
    IFS=, read -ra masterpublicip <<< "${BASH_REMATCH[1]}"
else
    exit "Error: public IP of master nodes not found!"
fi

for ((i=0; i<${#workerprivatedns[@]};++i)); do
scp -i ${PRIVATEKEY} -o StrictHostKeyChecking=no ca.pem ${workerprivatedns[i]}-key.pem ${workerprivatedns[i]}.pem ubuntu@${workerpublicip[i]}:~/
done 

for ((i=0; i<${#masterpublicip[@]};++i)); do
scp -i ${PRIVATEKEY} -o StrictHostKeyChecking=no ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ubuntu@${masterpublicip[i]}:~/
done

echo 'Finished setting up certificates!'
echo '**************************************'
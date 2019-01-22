#!/bin/bash

PRIVATEKEY=$1
BASEDIR=$2

echo ' '
echo '**************************************'
echo 'Generating kube-config files...'

# Generate kubelet kube-config file for each worker node
echo 'Generating kubelet kube-config file for worker nodes...'

file="$(grep 'NGINXPRIVATEIP' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ NGINXPRIVATEIP\ =\ (.*) ]]
then
    IFS=, read -ra nginxprivateip <<< "${BASH_REMATCH[1]}"
else
    exit "Error: private IP of nginx node not found!"
fi

file="$(grep 'WORKERPRIVATEDNS' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ WORKERPRIVATEDNS\ =\ (.*) ]]
then
    IFS=, read -ra workerprivatedns <<< "${BASH_REMATCH[1]}"
else
    exit "Error: private DNS of worker nodes not found!"
fi

for ((i=0; i<${#workerprivatedns[@]};++i)); do

kubectl config set-cluster kubernetes-the-hard-way \
--certificate-authority=ca.pem \
--embed-certs=true \
--server=https://${nginxprivateip}:6443 \
--kubeconfig=${workerprivatedns[i]}.kubeconfig

kubectl config set-credentials system:node:${workerprivatedns[i]} \
--client-certificate=${workerprivatedns[i]}.pem \
--client-key=${workerprivatedns[i]}-key.pem \
--embed-certs=true \
--kubeconfig=${workerprivatedns[i]}.kubeconfig

kubectl config set-context default \
--cluster=kubernetes-the-hard-way \
--user=system:node:${workerprivatedns[i]} \
--kubeconfig=${workerprivatedns[i]}.kubeconfig

kubectl config use-context default --kubeconfig=${workerprivatedns[i]}.kubeconfig

done

# Generate kube-proxy kube-config file for each worker node
echo 'Generating kube-proxy kube-config file...'

kubectl config set-cluster kubernetes-the-hard-way \
--certificate-authority=ca.pem \
--embed-certs=true \
--server=https://${nginxprivateip}:6443 \
--kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
--client-certificate=kube-proxy.pem \
--client-key=kube-proxy-key.pem \
--embed-certs=true \
--kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
--cluster=kubernetes-the-hard-way \
--user=system:kube-proxy \
--kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

# Generate kube-controller-manager kube-config file
echo 'Generating kube-controller-manager kube-config file...'

kubectl config set-cluster kubernetes-the-hard-way \
--certificate-authority=ca.pem \
--embed-certs=true \
--server=https://127.0.0.1:6443 \
--kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
--client-certificate=kube-controller-manager.pem \
--client-key=kube-controller-manager-key.pem \
--embed-certs=true \
--kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
--cluster=kubernetes-the-hard-way \
--user=system:kube-controller-manager \
--kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

# Generate kube-scheduler kube-config file
echo 'Generating kube-scheduler kube-config file...'

kubectl config set-cluster kubernetes-the-hard-way \
--certificate-authority=ca.pem \
--embed-certs=true \
--server=https://127.0.0.1:6443 \
--kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
--client-certificate=kube-scheduler.pem \
--client-key=kube-scheduler-key.pem \
--embed-certs=true \
--kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
--cluster=kubernetes-the-hard-way \
--user=system:kube-scheduler \
--kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

# Generate admin kube-config file
echo 'Generating admin kube-config file...'

kubectl config set-cluster kubernetes-the-hard-way \
--certificate-authority=ca.pem \
--embed-certs=true \
--server=https://127.0.0.1:6443 \
--kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
--client-certificate=admin.pem \
--client-key=admin-key.pem \
--embed-certs=true \
--kubeconfig=admin.kubeconfig

kubectl config set-context default \
--cluster=kubernetes-the-hard-way \
--user=admin \
--kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig

# Distribute kube-config files
echo 'Distributing kube-config files...'

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
scp -i ${PRIVATEKEY} -o StrictHostKeyChecking=no ${workerprivatedns[i]}.kubeconfig kube-proxy.kubeconfig ubuntu@${workerpublicip[i]}:~/
done

for ((i=0; i<${#masterpublicip[@]};++i)); do
scp -i ${PRIVATEKEY} -o StrictHostKeyChecking=no admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ubuntu@${masterpublicip[i]}:~/
done

echo 'Finished setting up kube-config files!'
echo '**************************************'
#!/bin/bash

echo ' '
echo '**************************************'
echo 'Setting up local environment...'

# Download and install Terraform binaries
if command -v terraform 2>/dev/null; then
  echo 'Terraform exists'
else
  echo 'Installing Terraform...'
  sudo apt-get install unzip
  wget https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip
  unzip terraform_0.11.10_linux_amd64.zip
  sudo mv terraform /usr/local/bin/
fi


# Download and install cfssl and cfssl-json binaries
if command -v cfssl 2>/dev/null; then
  echo 'Cfssl exists'
else
  echo 'Installing cfssl and cfssl-json...'
  wget -q --show-progress --https-only --timestamping https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
  chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
  sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
  sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
  cfssl version
fi

# Download and install kubectl binaries
if command -v kubectl 2>/dev/null; then
  echo 'Kubectl exists'
else
  echo 'Installing kubectl...'
  wget https://storage.googleapis.com/kubernetes-release/release/v1.10.2/bin/linux/amd64/kubectl
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
  kubectl version --client
fi

echo 'Finished setting up local environment!'
echo '**************************************'
#!/bin/bash

PRIVATEKEY=$1
BASEDIR=$2

echo ' '
echo '**************************************'
echo 'Generating data encryption keys...'

# Generate data encryption keys for each master node
echo 'Generating data encryption keys for each master node...'

file="$(grep 'MASTERPUBLICIP' ${BASEDIR}/src/aws/ec2_resources.log)"
if [[ "$file" =~ MASTERPUBLICIP\ =\ (.*) ]]
then
    IFS=, read -ra masterpublicip <<< "${BASH_REMATCH[1]}"
else
    exit "Error: public IP of master nodes not found!"
fi

# Generate the key
KEY=$(head -c 32 /dev/urandom | base64)

# Pass key as a kubernetes EncryptionConfig object
cat > encryption-config.yaml << EOF
kind: EncryptionConfig
apiVersion: v1
resources:
    - resources:
        - secrets
      providers:
        - aescbc:
          keys:
          - name: key1
            secret: ${KEY}
        - identity: {}
EOF

# Copy object to master nodes
for ((i=0; i<${#masterpublicip[@]};++i)); do
scp -i ${PRIVATEKEY} -o StrictHostKeyChecking=no encryption-config.yaml ubuntu@${masterpublicip[i]}:~/
done

echo 'Finished setting up data encryption keys!'
echo '**************************************'
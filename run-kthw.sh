#!/bin/bash

# Set base directory path
BASEDIR=$(pwd)

# Parse input
function usage() {
  echo "Make sure Terraform is installed and in your PATH."
  echo "Make sure environment variables TF_VAR_AWS_ACCESS_KEY and TF_VAR_AWS_SECRET_KEY are set."
  echo "USAGE: $0 [--aws-region string] \ "
  echo "          [--aws-public-key string] \ "
  echo "          [--aws-private-key string] \ "
  echo "          [--aws-instance-type string] \ "
  echo "          [--num-kube-masters int] \ "
  echo "          [--num-kube-workers int] \ "
  echo "          [--help] "
  echo "Example:"
  echo "$0 --aws-region us-west-2 \ "
  echo "   --aws-public-key /Users/cheuklau/.ssh/mykey.pub \ "
  echo "   --aws-private-key /Users/cheuklau/.ssh/mykey \ "
  echo "   --aws-instance-type t2.medium \ "
  echo "   --num-kube-masters 2 \ "
  echo "   --num-kube-workers 2 "
  exit 1
}

# Need at least 12 arguments
if [ $# -lt 12 ]; then
  usage
fi

# Parse two arguments at a time
while [ $# -gt 0 ]
do
  case $1 in
    --aws-region )
      REGION=$2
      shift
	    shift
	    ;;
	  --aws-public-key )
	    PUBLICKEY=$2
	    shift
	    shift
	    ;;
    --aws-private-key )
      PRIVATEKEY=$2
      shift
      shift
      ;;
    --aws-instance-type )
      TYPE=$2
      shift
      shift
      ;;
    --num-kube-masters )
      NMASTERS=$2
      shift
      shift
      ;;
    --num-kube-workers )
      NWORKERS=$2
      shift
      shift
      ;;
	  --help )
	    usage
	    ;;
	  * )
	    usage
	    ;;
  esac
done

# Make sure local dependencies are met
chmod +x $BASEDIR/scripts/setup-local.sh
$BASEDIR/scripts/setup-local.sh

# Set up AWS VPC, allocate EC2 instances, retrieve hostname, public IPs and private IPs
echo ' '
echo '**************************************'
echo 'Setting up AWS environment and EC2 instances...'
rm $BASEDIR/scr/aws/vars.tf > /dev/null 2>&1 &
cat << EOF | tee vars.tf
variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" { default = "${REGION}" }
variable "AWS_TYPE" { default = "${TYPE}" }
variable "PATH_TO_PUBLIC_KEY" { default = "${PUBLICKEY}" }
variable "PATH_TO_PRIVATE_KEY" { default = "${PRIVATEKEY}" }
variable "NUM_MASTERS" { default = "${NMASTERS}" }
variable "NUM_WORKERS" { default = "${NWORKERS}" }
EOF
export AWS_DEFAULT_REGION='us-west-2'
mv vars.tf $BASEDIR/src/aws
# There is a Terraform bug with defining the AWS region within modules
# Setting it as an evironment variable overrides this
cd $BASEDIR/src/aws
terraform init
terraform apply
terraform output > ec2_resources.log
echo 'Finished setting up AWS environment and EC2 instances!'
echo '**************************************'

# Generate and distribute certificates
rm $BASEDIR/certs/*
chmod +x $BASEDIR/scripts/gen-certs.sh
$BASEDIR/scripts/gen-certs.sh $PRIVATEKEY $BASEDIR

# Generate and distribute kubernetes configuration files
rm $BASEDIR/kubeconfigs/*
chmod +x $BASEDIR/scripts/gen-kubeconfig.sh
$BASEDIR/scripts/gen-kubeconfig.sh $PRIVATEKEY $BASEDIR

# Move certificates and kubernetes configuration files for local storage
mv *.json *.pem *.csr $BASEDIR/certs/
mv *.kubeconfig $BASEDIR/kubeconfigs/

# Generate data encryption keys and send to master nodes
rm $BASEDIR/keys/*
chmod +x $BASEDIR/scripts/gen-encrypt-key.sh
$BASEDIR/scripts/gen-encrypt-key.sh $PRIVATEKEY $BASEDIR
mv encryption-config.yaml $BASEDIR/keys/

# Bootstrap etcd cluster on kubernetes master nodes
echo ' '
echo '**************************************'
echo 'Bootstrapping etcd cluster on master nodes...'
rm $BASEDIR/src/etcd/vars.tf $BASEDIR/src/etcd/main.tf > /dev/null 2>&1 &
cat << EOF | tee vars.tf
variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" { default = "${REGION}" }
variable "AWS_TYPE" { default = "${TYPE}" }
variable "PATH_TO_PUBLIC_KEY" { default = "${PUBLICKEY}" }
variable "PATH_TO_PRIVATE_KEY" { default = "${PRIVATEKEY}" }
variable "NUM_MASTERS" { default = "${NMASTERS}" }
variable "NUM_WORKERS" { default = "${NWORKERS}" }
EOF
mv vars.tf $BASEDIR/src/etcd
chmod +x $BASEDIR/scripts/setup-etcd.sh
$BASEDIR/scripts/setup-etcd.sh $PRIVATEKEY $BASEDIR
# Set up AWS VPC
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
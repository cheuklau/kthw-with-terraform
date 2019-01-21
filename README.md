# Kubernetes the Hard Way with Terraform

This repository contains code for automating the setup of a Kubernetes cluster using the method outlined in [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) onto AWS. There are simpler alternatives (e.g., Kubeadm, Kops for AWS, etc) that handle a lot of the intricacies, but this is simply a learning exercise. Terraform will be used to setup the AWS environment (VPC, subnets, security groups) and set up the Kubernetes cluster from an Ubuntu 16.04 Amazon Machine Image (AMI).

## Final Architecture

The client will connect from their local machine via `kubectl` to an Nginx load balancer which will distribute traffic between the `kube-api-server` running in each controller (master) node. Each controller node contains the following services: 
- `etcd` - datastore to track cluster status
- `kube-api-server` - serves Kubernetes API allowing users to interact with the cluster
- `kube-controller-manager` - runs a series of controllers providing a wide range of functionality
- `kube-scheduler` - schedules pods on available worker nodes

Each worker node contains the following services:
- `containerd` - download and run images (Docker is another option)
- `kubelet` - provides APIs used by control plane to manage nodes and pods
- `kube-proxy` - manages pod networking

Note that we can also set up an AWS Elastic Load Balancer (ELB) in place of the Nginx load balancer.

## Build Dependencies

The local machine must have the following installed and in PATH:
- terraform
- cfssl/cfssl-json
- kubectl

`scripts/local-setup.sh` will install the dependencies for Ubuntu users and is run as part of the main script `run-kthw.sh`. Refer to online documentation of each dependency for other operating systems.

## Run Instructions

1. Make sure environment variables `TF_VAR_AWS_ACCESS_KEY` and `TF_VAR_AWS_SECRET_KEY` are set:
- Go to AWS console
- Click on username then `Security Credentials`
- Click on `Access Keys` then `Create New Access Key`
- `export TF_VAR_AWS_ACCESS_KEY=<aws access key> && export TF_VAR_AWS_SECRET_KEY=<aws secret key>`
2. Make the build script executable: `chmod +x run-kthw.sh`
3. Create SSH key-pair for EC2 instances: `ssh-keygen -f mykey`
4. Run the build script. Sample configuration:
```
./run-kthw.sh --aws-region us-west-2 \
              --aws-public-key /path/to/mykey.pub\
              --aws-private-key /path/to/mykey \
              --aws-instance-type t2.micro \
              --num-kube-masters 2 \
              --num-kube-workers 2
```
- The above example spins up two master nodes, two worker nodes and one node for the Nginx load balancer (all of t2.micro size and running in us-west-2). Note that every node allows all incoming and outgoing connections! Please secure as necessary within AWS security group settings!

## Running Smoke Tests

To run the smoke tests validating cluster setup: 
``` 
cd scripts/
chmod + x run-smoke.sh
./run-smoke.sh
```

## Working with the Kubernetes Cluster

Once all smoke tests have passed, you should be able to now deploy your own objects as necessary using `kubectl`.

## What is Happening Behind the Scenes

### Set up Certificate Authority and Generate TLS Certificates

Certificates are used to authenticate identity. Certificate Authorities (CA) issue and confirm that a certificate is valid. Kubernetes uses certificates for a variety of security functions. Different parts of the cluster will validate certificates using the CA we provision. We need to set up a local Certificate Authority then use it to generate the following certificates:
- `admin`
- `kubelet`
- `controller-manager`
- `kube-proxy`
- `kube-scheduler` 
- `kube-api`
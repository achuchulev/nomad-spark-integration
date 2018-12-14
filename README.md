# A sample repo with example of how to run Apache Spark on Nomad

### Pre-requisites

- Vagrant
- Virtualbox
- Git
- AWS account
- API access keys
- SSH key pair

### How to build

### Get the repo and run lab

```
https://github.com/achuchulev/spark-on-nomad.git
cd spark-on-nomad
vagrant up
```

Vagrant up will start a VM on virtualbox and will run `scripts/provision.sh` to install:

- Packer
- Terraform

### SSH to VM

```
vagrant ssh
```

### Set the AWS environment variables

```
$ export AWS_ACCESS_KEY_ID=[AWS_ACCESS_KEY_ID]
$ export AWS_SECRET_ACCESS_KEY=[AWS_SECRET_ACCESS_KEY]
```

### Build an AWS machine image with Packer

Packer will bake an AMI on AWS using a publicly available AMI by default that is customized through modifications to the build configuration script and packer.json.

To use custom AMI from specific region modify the lines below within `packer.json`

```
"source_ami": "ami-80861296"
"instance_type": "t2.medium"
```

Use the following command to build the AMI:

```
$ packer build packer.json
```

### Provision a cluster with Terraform

cd to an environment subdirectory:

```
$ cd env/us-east
```

### Update terraform.tfvars with your SSH key name and your AMI ID if you created a custom AMI:

```
region                  = "us-east-1"
ami                     = "ami-0c207c24df48e155a"
instance_type           = "t2.medium"
key_name                = "KEY_NAME"
server_count            = "3"
client_count            = "4"
```

### Provision the cluster:

```
$ terraform init
$ terraform plan
$ terraform apply
```

### Access the cluster

SSH to one of the servers using its public IP:

```
$ ssh -i /path/to/private/key ubuntu@PUBLIC_IP
```

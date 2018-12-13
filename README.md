# A sample repo with example of how to run Apache Spark on Nomad

### Pre-requisites
To get started, create the following:

- AWS account
- API access keys
- SSH key pair

### Set the AWS environment variables

```
$ export AWS_ACCESS_KEY_ID=[AWS_ACCESS_KEY_ID]
$ export AWS_SECRET_ACCESS_KEY=[AWS_SECRET_ACCESS_KEY]
```

### Build an AWS machine image with Packer

Packer is HashiCorp's open source tool for creating identical machine images for multiple platforms from a single source configuration. The Terraform templates included in this repo reference a publicly available Amazon machine image (AMI) by default. The AMI can be customized through modifications to the build configuration script and packer.json.

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

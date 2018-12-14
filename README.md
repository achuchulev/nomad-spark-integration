# Run Apache Spark on Nomad

Apache Spark is a data processing engine/framework that has been architected to use third-party schedulers and natively integrates Nomad as a cluster manager and scheduler for Spark. When running on Nomad, the Spark executors that run Spark tasks for your application, and optionally the application driver itself, run as Nomad tasks in a Nomad job.

#### Pre-requisites

- Vagrant
- Virtualbox
- Git
- AWS account
- API access keys
- SSH key pair

## How to build

### Get the repo and run lab

```
$ https://github.com/achuchulev/spark-on-nomad.git
$ cd spark-on-nomad
$ vagrant up
```

Vagrant up will start a VM on virtualbox and will run `scripts/provision.sh` to install:

- Packer
- Terraform

### Access lab VM

```
$ vagrant ssh
$ cd /vagrant
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
"region": "us-east-2"
"source_ami": "ami-618fab04"
```

Use the following command to build the AMI:

```
$ packer build packer.json
```

### Provision a Nomad cluster with Terraform on AWS

cd to the environment subdirectory:

```
$ cd aws/env/us-east
```

Update `terraform.tfvars` with your SSH key name and your AMI ID if you created a custom AMI:

```
region                  = "us-east-2"
ami                     = "ami-023db6a9decf31f96"
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

- The Nomad UI can be accessed at http://PUBLIC_IP:4646/ui.
- The Consul UI can be accessed at http://PUBLIC_IP:8500/ui.

SSH to one of the servers using its public IP:

```
$ ssh -i /path/to/private/key ubuntu@PUBLIC_IP
```

The infrastructure that is provisioned for this test environment is configured to allow all traffic on port 22 that is not recommended for production deployments.

### Test Nomad cluster

Run a few basic status commands to verify that Consul and Nomad are up and running properly:

```
$ consul members
$ nomad server members
$ nomad node status
```

## Setup Nomad / Spark integration

The Spark history server and several of the sample Spark jobs below require HDFS. Using the included job file, deploy an HDFS cluster on Nomad:

```
$ cd $HOME/examples/spark
$ nomad run hdfs.nomad
$ nomad status hdfs
```

When the allocations are all in the running state (as shown by nomad status hdfs), query Consul to verify that the HDFS service has been registered:

```
$ dig hdfs.service.consul
```

Next, create directories and files in HDFS for use by the history server and the sample Spark jobs:

```
$ hdfs dfs -mkdir /foo
$ hdfs dfs -put /var/log/apt/history.log /foo
$ hdfs dfs -mkdir /spark-events
$ hdfs dfs -ls /
```

Finally, deploy the Spark history server:

```
$ nomad run spark-history-server-hdfs.nomad
```

You can get the private IP for the history server with a Consul DNS lookup:

```
$ dig spark-history.service.consul
```

Cross-reference the private IP with the terraform apply output to get the corresponding public IP. You can access the history server at http://PUBLIC_IP:18080.

### Sample Spark jobs

The sample spark-submit commands listed below demonstrate several of the official Spark examples. Features like spark-sql, spark-shell and pyspark are included. The commands can be executed from any client or server.

You can monitor the status of a Spark job in a second terminal session with:

```
$ nomad status
$ nomad status JOB_ID
$ nomad alloc-status DRIVER_ALLOC_ID
$ nomad logs DRIVER_ALLOC_ID
```

To view the output of the job, run nomad logs for the driver's Allocation ID.

#### SparkPi (Java)

```
spark-submit \
  --class org.apache.spark.examples.JavaSparkPi \
  --master nomad \
  --deploy-mode cluster \
  --conf spark.executor.instances=4 \
  --conf spark.nomad.cluster.monitorUntil=complete \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=hdfs://hdfs.service.consul/spark-events \
  --conf spark.nomad.sparkDistribution=https://s3.amazonaws.com/nomad-spark/spark-2.1.0-bin-nomad.tgz \
  https://s3.amazonaws.com/nomad-spark/spark-examples_2.11-2.1.0-SNAPSHOT.jar 100
  ```

#### Word count (Java)

```
spark-submit \
  --class org.apache.spark.examples.JavaWordCount \
  --master nomad \
  --deploy-mode cluster \
  --conf spark.executor.instances=4 \
  --conf spark.nomad.cluster.monitorUntil=complete \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=hdfs://hdfs.service.consul/spark-events \
  --conf spark.nomad.sparkDistribution=https://s3.amazonaws.com/nomad-spark/spark-2.1.0-bin-nomad.tgz \
  https://s3.amazonaws.com/nomad-spark/spark-examples_2.11-2.1.0-SNAPSHOT.jar \
  hdfs://hdfs.service.consul/foo/history.log
```

#### DFSReadWriteTest (Scala)

```
spark-submit \
  --class org.apache.spark.examples.DFSReadWriteTest \
  --master nomad \
  --deploy-mode cluster \
  --conf spark.executor.instances=4 \
  --conf spark.nomad.cluster.monitorUntil=complete \
  --conf spark.eventLog.enabled=true \
  --conf spark.eventLog.dir=hdfs://hdfs.service.consul/spark-events \
  --conf spark.nomad.sparkDistribution=https://s3.amazonaws.com/nomad-spark/spark-2.1.0-bin-nomad.tgz \
  https://s3.amazonaws.com/nomad-spark/spark-examples_2.11-2.1.0-SNAPSHOT.jar \
  /etc/sudoers hdfs://hdfs.service.consul/foo
  ```
  
### Destroy Nomad cluster

```
$ exit              # to exit ssh session to nomad server
$ terraform destroy
$ exit              # to exit ssh session to lab server
$ vagrant destroy
```


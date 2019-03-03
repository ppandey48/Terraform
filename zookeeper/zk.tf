variable "ami" {
  type = "map"

  default {
    eu-central-1 = "ami-086a09d5b9fa35dc7"
    us-east-1 = "ami-0f9cf087c1f27d9b1"
    us-west-2 = "ami-076e276d85f524150"
  }
}

variable "pem" {
  type = "map"

  default {
    eu-central-1 = "/path/to/keyname.pem"
    us-east-1 = "/path/to/keyname.pem"
    us-west-2 = "/path/to/keyname.pem"
  }
}

variable "aws_region" {
  default = "eu-central-1"
 
}


variable "sec_group" {
  type = "map"

  default {
    eu-central-1 = "sg-XXXXXXXXXXXXXX"
    us-east-1 = "sg-XXXXXXXXXXXXXXX"
    us-west-2 = "sg-XXXXXXXXXXX"
  }
}

variable "key_name" {
  type = "map"

  default {
    eu-central-1 = "region-key-name"
    us-east-1 = "region-key-name"
    us-west-2 = "region-key-name"
  }
}

variable "subnet_id" {
  type = "map"

  default {
    eu-central-1 = "subnet-XXXXXXXXX"
    us-east-1 = "subnet-XXXXXXXX"
    us-west-2 = "subnet-XXXXXXXXX"
  }
}

provider "aws" {
  access_key = "XXXXXXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  region = "${var.aws_region}"
}

variable "count" {
  default = 1
}


resource "aws_instance" "zk-nodes" {
  count                       = "${var.count}"
  ami                         = "${lookup(var.ami, var.aws_region)}"
  instance_type               = "t2.micro"
  key_name                    = "${lookup(var.key_name, var.aws_region)}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${lookup(var.sec_group, var.aws_region)}"]
  subnet_id                   = "${lookup(var.subnet_id, var.aws_region)}"

  tags {
    Name = "${format("zk-stage-tf-%01d",count.index+1)}"
  }

  provisioner "remote-exec" {
    connection {
      user        = "ubuntu"
      host        = "${self.public_ip}"
      agent       = false
      private_key = "${file("${lookup(var.pem, var.aws_region)}")}"
    }

    inline = [
      "sudo apt-get update",
      "sleep 10s",
      "sudo apt-get install -y default-jre",
      "sleep 10s",
      "java -version",
      "sudo add-apt-repository -y ppa:saltstack/salt",
      "sudo apt-get update",
      "sudo apt-get install -y salt-minion",
      "ip=$(curl -XGET ipinfo.io/ip)",
      "sleep 10s",
      "sudo mv /etc/salt/minion /etc/salt/minion-orig",
      "sudo touch /etc/salt/minion",
      "sudo cp -a /home/ubuntu/test-file.txt /etc/salt/minion_id",
      "sudo chmod -R 777 /etc/salt",
      "sudo echo 'master: ip' > /etc/salt/minion",
      "sudo service salt-minion restart",
      "echo $ip >> /home/ubuntu/test-file.txt",
      "cd /opt",
      "sudo wget http://www-eu.apache.org/dist/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz",
      "sudo tar -xvf zookeeper-3.4.10.tar.gz",
      "sudo mv zookeeper-3.4.10 zookeeper",
      "cd /opt/zookeeper/conf",
      "sudo wget https://s3.amazonaws.com/path/to/zoo.cfg",
      "sudo mkdir /var/lib/zookeeper",
      "sudo mkdir /var/lib/zookeeper/logs",
      "sudo mkdir /var/run/zookeeper",
      "sudo chown -R ubuntu:nogroup /opt/zookeeper",
      "sudo chown -R ubuntu:nogroup /var/lib/zookeeper",
      "sudo chown -R ubuntu:nogroup /var/run/zookeeper",
      "sudo echo '${format("%01d",count.index+1)}' > /var/lib/zookeeper/myid",
      "cd /opt/zookeeper/bin",
      "sudo chmod 666 /opt/zookeeper/bin/zookeeper.out",
      "sudo ./zkServer.sh start",
    ]
  }
}

output "EC2 instance Endpoint" {
  value = "${aws_instance.zk-nodes.*.public_ip}"
}


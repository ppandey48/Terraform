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
    eu-central-1 = "/path/to/key.pem"
    us-east-1 = "/path/to/key.pem"
    us-west-2 = "/path/to/key.pem"
  }
}

variable "aws_region" {
  default = "us-east-1"
 
}


variable "sec_group" {
  type = "map"

  default {
    eu-central-1 = "sg-XXXXXXXXXXXXX"
    us-east-1 = "sg-XXXXXXXXXXXXX"
    us-west-2 = "sg-XXXXXXXXX"
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
    eu-central-1 = "subnet-XXXXXXXXXX"
    us-east-1 = "subnet-XXXXXX"
    us-west-2 = "subnet-XXXXXXX"
  }
}

provider "aws" {
  access_key = "XXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  region = "${var.aws_region}"
}

variable "count" {
  default = 1
}


resource "aws_instance" "kafka-nodes" {
  count                       = "${var.count}"
  ami                         = "${lookup(var.ami, var.aws_region)}"
  instance_type               = "t2.small"
  key_name                    = "${lookup(var.key_name, var.aws_region)}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${lookup(var.sec_group, var.aws_region)}"]
  subnet_id                   = "${lookup(var.subnet_id, var.aws_region)}"

  tags {
    Name = "${format("kafka-tf-%01d",count.index+1)}"
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
      "sudo apt-get install -y zookeeperd",
      "ip=$(curl -XGET ipinfo.io/ip)",
      "sleep 10s",
      "sudo chmod -R 777 /opt/",
      "sudo wget https://www-us.apache.org/dist/kafka/2.1.0/kafka_2.11-2.1.0.tgz",
      "sudo tar -xzf kafka_2.11-2.1.0.tgz",
      "sudo mv kafka_2.11-2.1.0 kafka",
      "sudo cp -r /home/ubuntu/kafka /opt/"
    ]
  }
}

output "EC2 instance Endpoint" {
  value = "${aws_instance.kafka-nodes.*.public_ip}"
}


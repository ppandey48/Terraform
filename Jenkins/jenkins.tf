variable "ami" {
  type = "map"

  default {
    eu-central-1 = "ami-086a09d5b9fa35dc7"
    us-east-1 = "ami-0f9cf087c1f27d9b1"
  }
}

variable "pem" {
  type = "map"

  default {
    eu-central-1 = "/path/to/pem/key"
    us-east-1 = "/path/to/pem/key"
  }
}

variable "aws_region" {
  default = "eu-central-1"
 
}


variable "sec_group" {
  type = "map"

  default {
    eu-central-1 = "sg-name"
    us-east-1 = "sg-name"
  }
}

variable "key_name" {
  type = "map"

  default {
    eu-central-1 = "region-key-name"
    us-east-1 = "region-key-name"
  }
}


variable "subnet_id" {
  type = "map"

  default {
    eu-central-1 = "subnet-XXXXXXX"
    us-east-1 = "subnet-XXX"
  }
}

provider "aws" {
  access_key = "XXXXXXXXXXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXX"
  region = "${var.aws_region}"
}

variable "count" {
  default = 1
}


resource "aws_instance" "jenkins-tf" {
  count                       = "${var.count}"
  ami                         = "${lookup(var.ami, var.aws_region)}"
  instance_type               = "t2.micro"
  key_name                    = "${lookup(var.key_name, var.aws_region)}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${lookup(var.sec_group, var.aws_region)}"]
  subnet_id                   = "${lookup(var.subnet_id, var.aws_region)}"

  tags {
    Name = "${format("jenkins-tf-%01d",count.index+1)}"
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
      "sudo apt-get install -y default-jre",
      "wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -",
      "echo deb https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list",
      "sudo apt-get update",
      "sudo apt-get install -y jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl status jenkins",
      "sudo ufw allow 8080",
      "sudo apt-get install -y build-essential checkinstall",
      "sudo apt-get install -y libreadline-gplv2-dev libncursesw5-dev libssl-dev \libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev",
      "cd /usr/src",
      "sudo wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz",
      "sudo tar xzf Python-3.7.0.tgz",
      "cd Python-3.7.0",
      "sudo ./configure --enable-optimizations",
      "sudo make altinstall",
      "python3.7 -V",
      "sudo apt-get install -y maven",
      "sudo apt-get install -y gradle"
      "gradle -v",
      "sudo apt-get install -y ruby2.3"
      "ruby2.3 -v"
  
    ]
  }
}

output "EC2 instance Endpoint" {
  value = "${aws_instance.jenkins-tf.*.public_ip}"
}


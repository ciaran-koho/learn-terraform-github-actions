terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.26.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
  }
  required_version = "~> 0.14"

  backend "remote" {
    organization = "koho"

    workspaces {
      name = "gh-actions-demo"
    }
  }
}


provider "aws" {
  assume_role {
    role_arn     = "arn:aws:iam::022292195207:role/StagingTerraformAdminRole"
    session_name = "Terraform"
    external_id  = var.external_id
  }
  region     = "us-west-2"
  access_key = var.access_key
  secret_key = var.secret_key
}
variable "access_key" {}
variable "secret_key" {}
variable "external_id" {}



resource "random_pet" "sg" {}

resource "aws_instance" "web" {
  ami                    = "ami-830c94e3"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}

resource "aws_security_group" "web-sg" {
  name = "${random_pet.sg.id}-sg"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "web-address" {
  value = "${aws_instance.web.public_dns}:8080"
}

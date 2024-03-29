terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.40.0"
    }
  }
}
provider "aws" {
  region = "ap-south-1"
}
resource "aws_key_pair" "pub-key" {
  key_name   = "pub-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDTS3/Fys9fVthYPCPtqYEskIpOR3bup4gjxZe/SikDdRXRR+iQnRH1tf+Vqw2YwwH5X0AbfN7iWkXbPg2iikLguAx9GVrgDvQtD2otmKVwyKdiMWAzgkXYHv4nM8u1cvqvp/AOiRAQN0UGEqWoI4IY2AM/fmJAb+bN8zCSQx4vZbl0lWHkEVagd+ODllFYgJ1apRgfSEpsFifJOuZqH7zhsHluK4yBPfth8N4FMhfmTjQBdEaSyb+sa09qVNAismgTthl4H0Iq3owLL/QA+wU7kq5D4uitz/2r9bjy/EYNn1R1ZdGnIiV8w0aDr1PzzhqkloS0dWNiBhSoQl0JAvZuWITYzQP1R+NxHhA94ZvtBOyVGFmk8hlkN9oSbSXfk51XTigCm7t4PNQM/VJQaJcwvNAWqmtHVrby0Fg4YlwRm0Tpb5Bgmqe+tW6Zkgr+OJ5qTAFxihDADPllIwsH2RmFMWJRxiG0t7sPvMGfMsLloqClyLt3BjK60VI9SqAqVH8= user@DESKTOP-ANCPI7M"
}

resource "aws_instance" "cicdtest" {
  ami           = "ami-0a1b648e2cd533174"
  instance_type = "t2.large"
  key_name      = "pub-key"
  
  tags = {
    Name = "cicd"
  }
user_data = <<-EOF
#!/bin/bash
sudo apt update
sudo apt install fontconfig openjdk-17-jre -y
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y
sudo apt-get update
sudo apt-get install docker.io -y
sudo usermod -aG docker $USER
sudo chmod 777 /var/run/docker.sock 
sudo docker ps
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y

EOF
}

resource "aws_security_group" "ports" {
  name        = "allport-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      =  "vpc-06e28ba197da2d28b" 
# SSH access from anywhere
  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
      }
  # HTTP access from anywhere
  ingress {
    description      = "TLS from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
      }
    ingress {
    description      = "TLS from VPC"
    from_port        = 9000
    to_port          = 9000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
      }
      # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allports-sg"
  }
}
resource "aws_s3_bucket" "cicdinstalls" {
  bucket = "cicdinstallscripts"
}
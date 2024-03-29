# terraform VPC

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.27.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

#subnet public
resource "aws_subnet" "pub-sub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b" #missed availablity zone
  tags = {
    Name = "Public subnet"
  }
}
#subnet private
resource "aws_subnet" "pvt-sub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "Private subnet"
  }
}
#Internet_gateway
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "internet gateway"
  }
}
#route_table Public
resource "aws_route_table" "pub-r" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
   tags = {
    Name = "Public Route"
  }
}
 #route association public
 resource "aws_route_table_association" "pub-a" {
  subnet_id      = aws_subnet.pub-sub.id
  route_table_id = aws_route_table.pub-r.id
}
#elastic IP
resource "aws_eip" "eip" {
  domain   = "vpc"
}
#Nat Gateway
resource "aws_nat_gateway" "vnat" {
  allocation_id = aws_eip.eip.id    #need to mention elstic ip
  subnet_id     = aws_subnet.pub-sub.id  #specify public subnet

  tags = {
    Name = "NAT"
  }
}
#route_table Private
resource "aws_route_table" "pvt-r" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.vnat.id
  }
   tags = {
    Name = "Private Route"
  }
}
 #route association privte
 resource "aws_route_table_association" "pvt-a" {
  subnet_id      = aws_subnet.pvt-sub.id
  route_table_id = aws_route_table.pvt-r.id
}
# aws_security_group Public
resource "aws_security_group" "Pub-sg" {
  name        = "Public-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id
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
    from_port        = 80
    to_port          = 80
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
    Name = "Public-sg"
  }
}
# aws_security_group Private
resource "aws_security_group" "Pvt-sg" {
  name        = "Private-sg"
  description = "Allow Public sg inbound traffic"
  vpc_id      = aws_vpc.myvpc.id
  ingress {
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  #security_group_id = aws_security_group.Pvt-sg.id
  }
}
resource "aws_instance" "Server1" {
  ami                         = "ami-0a7cf821b91bcccbc" 
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.pub-sub.id
  vpc_security_group_ids      = [aws_security_group.Pub-sg.id]
  key_name                    = "password"
  associate_public_ip_address = true
}
resource "aws_instance" "Server2" {
  ami                         = "ami-0a7cf821b91bcccbc" 
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.pvt-sub.id
  vpc_security_group_ids      = [aws_security_group.Pvt-sg.id]
  key_name                    = "password"
}
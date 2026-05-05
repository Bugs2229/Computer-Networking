terraform {
  required_version = ">=1.7.0, <2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals { # Stored Variables that you claim inside your project, use Merge to merge two objects
  common_tags = {
    Name       = "NGINX_vpc"
    ManagedBy  = "Terraform"
    Project    = "06-resources"
    CostCenter = "12345"

  }

}
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.16.0.0/16"
  tags = merge(local.common_tags, {
    Name = "NGINX_vpc"

  })

}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.16.1.0/24"
  tags = merge(local.common_tags, {
    Name = "public_subnet"

  })

}
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.16.2.0/24"
  tags = merge(local.common_tags, {
    Name = "private_subnet"
  })

}

resource "aws_internet_gateway" "main_IGW" {
  vpc_id = aws_vpc.main_vpc.id
  tags = merge(local.common_tags, {
    Name = "Internet_gateway"
  })

}
# route tables doesn't need tags because its a connection between two resources
# Only resources that exist by themselves can be tagged
resource "aws_route_table" "main_RTB" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/00"
    gateway_id = aws_internet_gateway.main_IGW.id
  }
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.main_RTB.id

}

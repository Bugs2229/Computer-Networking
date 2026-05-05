resource "aws_instance" "web" {
  ami                         = "ami-0629564b92a07fced" #make sure to use an AMD64 ami
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.public_http_traffic.id] #associate SG with Ec2
  root_block_device {
    delete_on_termination = true
    volume_size           = 10
    volume_type           = "gp3" # EBS volume attached to EC2 instance 
  }
  tags = merge(local.common_tags, {
    Name = "NGNIX_instance"
  })

  lifecycle {
    create_before_destroy = true

  }

}
resource "aws_security_group" "public_http_traffic" {  # SG's only allow private traffic from other SG  
  description = "Allowing traffic on ports 443 and 80" # Open Ports 443 and 80 to allow public traffic. port 80 isn't secure
  name        = "public_http_traffic"
  vpc_id      = aws_vpc.main_vpc.id

  tags = merge(local.common_tags, { #add your tags from locals 
    Name = "06-resources-sg"
  })

}


resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.public_http_traffic.id
  cidr_ipv4         = "0.0.0.0/00" #from anywhere
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}


resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.public_http_traffic.id
  cidr_ipv4         = "0.0.0.0/00" # traffic from anywhere
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}



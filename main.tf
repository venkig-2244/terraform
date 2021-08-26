###########################################
# VPC
###########################################

resource "aws_vpc" "vpc" {
        cidr_block              = var.vpc_cidr
        instance_tenancy        = "default"
        enable_dns_hostnames    = true

        tags = {
                Name = "${var.project}-vpc"
        }
}

###########################################
# Internet Gateway
###########################################

resource "aws_internet_gateway" "igw" {
        vpc_id                  = aws_vpc.vpc.id
        tags = {
                Name = "${var.project}-igw"
        }

}

###########################################
# Public1 Subnet
###########################################

resource "aws_subnet" "public1" {
        vpc_id                  = aws_vpc.vpc.id
        cidr_block              = var.public1.cidr
        availability_zone       = var.public1.az
        map_public_ip_on_launch = true

        tags = {
                Name = "${var.project}-public1"
        }
}

###########################################
# Public2 Subnet
###########################################

resource "aws_subnet" "public2" {
        vpc_id                  = aws_vpc.vpc.id
        cidr_block              = var.public2.cidr
        availability_zone       = var.public2.az
        map_public_ip_on_launch = true

        tags = {
                Name = "${var.project}-public2"
        }
}

###########################################
# Private1 Subnet
###########################################

resource "aws_subnet" "private1" {
        vpc_id                  = aws_vpc.vpc.id
        cidr_block              = var.private1.cidr
        availability_zone       = var.private1.az
        map_public_ip_on_launch = false

        tags = {
                Name = "${var.project}-private1"
        }
}

###########################################
# Private2 Subnet
###########################################

resource "aws_subnet" "private2" {
        vpc_id                  = aws_vpc.vpc.id
        cidr_block              = var.private2.cidr
        availability_zone       = var.private2.az
        map_public_ip_on_launch = false

        tags = {
                Name = "${var.project}-private2"
        }
}

###########################################
# Elastic IP for NAT GW
###########################################

resource "aws_eip" "nat" {
        vpc                     = true
        tags = {
                Name = "${var.project}-natip"
        }
}

###########################################
# NAT Gateway
###########################################

resource "aws_nat_gateway" "nat" {
        allocation_id           = aws_eip.nat.id
        subnet_id               = aws_subnet.public1.id

        tags = {
                Name = "${var.project}-natgw"
        }
}

###########################################
# Route Table - Public
###########################################

resource "aws_route_table" "public" {
        vpc_id                  = aws_vpc.vpc.id

        route {
                cidr_block      = "0.0.0.0/0"
                gateway_id      = aws_internet_gateway.igw.id
        }

        tags = {
                Name = "${var.project}-rtpub"
        }
}

###########################################
# Route Table - Private
###########################################

resource "aws_route_table" "private" {
        vpc_id                  = aws_vpc.vpc.id
        route {
                cidr_block      = "0.0.0.0/0"
                nat_gateway_id  = aws_nat_gateway.nat.id
        }

        tags = {
                Name = "${var.project}-rtpri"
        }
}

###########################################
# Associate Public subnets to RT
###########################################

resource "aws_route_table_association" "public1" {
        subnet_id               = aws_subnet.public1.id
        route_table_id          = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
        subnet_id               = aws_subnet.public2.id
        route_table_id          = aws_route_table.public.id
}

###########################################
# Associate Private subnets to RT
###########################################

resource "aws_route_table_association" "private1" {
        subnet_id               = aws_subnet.private1.id
        route_table_id          = aws_route_table.private.id
}

resource "aws_route_table_association" "private2" {
        subnet_id               = aws_subnet.private2.id
        route_table_id          = aws_route_table.private.id
}

###########################################
###########################################
# Security Group for bastion, web, Jenkins
###########################################

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "bastion" {
        name                    = "${var.project}-bastion"
        description             = "Allows 22 from my ip"
        vpc_id                  = aws_vpc.vpc.id

        ingress {
                from_port        = 22
                to_port          = 22
                protocol         = "tcp"
                cidr_blocks      = [ "${chomp(data.http.myip.body)}/32"]
        }

        egress {
                from_port        = 0
                to_port          = 0
                protocol         = "-1"
                cidr_blocks      = [ "0.0.0.0/0" ]
                ipv6_cidr_blocks = [ "::/0" ]
        }

        tags = {
                Name = "${var.project}-bastion"
        }
}

resource "aws_security_group" "private_sg" {
        name                    = "${var.project}-webserver"
        description             = "Private SG"
        vpc_id                  = aws_vpc.vpc.id
  
        ingress {
    
                from_port        = 0
                to_port          = 0
                protocol         = "-1"
                security_groups  = [ aws_security_group.bastion.id ]
        }
  
        egress {
                from_port        = 0
                to_port          = 0
                protocol         = "-1"
                cidr_blocks      = [ "0.0.0.0/0" ]
                ipv6_cidr_blocks = [ "::/0" ]
        }

        tags = {
                Name = "${var.project}-webserver"
        }
}

resource "aws_security_group" "public_sg" {
    
        name        = "${var.project}-database"
        description = "Allows 3306 from webserver & 22 from bastion"
        vpc_id      = aws_vpc.vpc.id

        ingress {
    
                from_port        = 80
                to_port          = 80
                protocol         = "tcp"
                cidr_blocks      = [ "${chomp(data.http.myip.body)}/32" ]

        }
  
        egress {
                from_port        = 0
                to_port          = 0
                protocol         = "-1"
                cidr_blocks      = [ "0.0.0.0/0" ]
                ipv6_cidr_blocks = [ "::/0" ]
        }

        tags = {
                Name = "${var.project}-database"
        }
}


###########################################
# Key Pair
###########################################

resource "aws_key_pair" "key" {

  key_name   = "${var.project}-kp"
  public_key = file("my-key.pub")
  tags = {
    Name = "${var.project}-kp"
  }
    
}

###########################################
# Bastion server
###########################################

resource  "aws_instance"  "bastion" {
    
        ami                           =     var.ami
        instance_type                 =     "t2.micro"
        associate_public_ip_address   =     true
        key_name                      =     aws_key_pair.key.key_name
        vpc_security_group_ids        =     [  aws_security_group.bastion.id ]
        subnet_id                     =     aws_subnet.public1.id  
  
        tags = {
                Name = "${var.project}-bastion"
        }
}

###########################################

resource  "aws_instance"  "app" {
    
        ami                           =     var.ami
        instance_type                 =     "t2.micro"
        associate_public_ip_address   =     true
        key_name                      =     aws_key_pair.key.key_name
        vpc_security_group_ids        =     [  aws_security_group.public_sg.id ]
        subnet_id                     =     aws_subnet.private1.id  
        tags = {
                Name = "${var.project}-database"
        }
}

###########################################


resource  "aws_instance"  "jenkins" {

        ami                           =     var.ami
        instance_type                 =     "t2.micro"
        associate_public_ip_address   =     true
        key_name                      =     aws_key_pair.key.key_name
        vpc_security_group_ids        =     [  aws_security_group.private_sg.id ]
        subnet_id                     =     aws_subnet.public2.id
        tags = {
                Name = "${var.project}-webserver"
        }
}

################################################

#resource "aws_lb" "alb" {
#  name               = "alb"
#  internal           = false
#  load_balancer_type = "application"
#  subnets            = [ aws_subnet.public1.*.id, aws_subnet.public2.*.id ]

#  tags = {
#    Name = "Load Balancer"
#  }
#}


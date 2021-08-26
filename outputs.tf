output "app-public-ip" {
        value = aws_instance.app.public_ip
}

output "bastion-public-ip" {
        value = aws_instance.bastion.public_ip
}

output "app-private-ip" {
        value = aws_instance.app.private_ip

}

output "jenkins-private-ip" {
        value = aws_instance.jenkins.private_ip

}



output "Bastion_IP" {
  value = aws_instance.bastion.public_ip
}


#output "Load-Balancer" {
#  value = aws_lb.alb.arn
#}


output "VPC" {
  value = aws_vpc.vpc.arn
}

output "Internet-gateway" {
  value = aws_internet_gateway.igw.arn
}




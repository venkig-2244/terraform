variable "project" {
        default = "gopal"
}

variable "vpc_cidr" {
        default = "10.0.0.0/16"
}

variable "public1" {
        type            = map
        default = {
                "cidr"  = "10.0.101.0/24"
		"az"	= "us-east-1a"
        }

}

variable "public2" {
        type            = map
        default = {
                "cidr"  = "10.0.102.0/24"
		"az"    = "us-east-1b"
        }

}


variable "private1" {
        type            = map
        default = {
                "cidr"  = "10.0.1.0/24"
		"az"	= "us-east-1a"
        }

}

variable "private2" {
        type            = map
        default = {
                "cidr"  = "10.0.2.0/24"
		"az"	= "us-east-1b"
        }

}

variable "ami" {
  type    = string
  default = "ami-09e67e426f25ce0d7"
}


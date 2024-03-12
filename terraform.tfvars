vpc_cidr = "10.0.0.0/16"
subnet = {
  "pub_sub1" = {
    cidr = "10.0.1.0/24"
    az = "us-east-1b"
  }
  "pub_sub2" = {
    cidr = "10.0.2.0/24"
    az = "us-east-1d"
  }
  "pri_sub1" = {
    cidr = "10.0.3.0/24"
    az = "us-east-1b"
  }
  "pri_sub2" = {
    cidr = "10.0.4.0/24"
    az = "us-east-1d"
  }
}
imageID = "ami-07d9b9ddc6cd8dd30"
instance_type = "t2.micro"
keypair = "terraform"
public_key = "terraform.pub"
script_file = "script.sh"
desired_capacity = 2
minimum_capacity = 2
maximum_capacity = 4
scaling-adjustment = 1
cooldown = 300
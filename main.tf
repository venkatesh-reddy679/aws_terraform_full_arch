terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}


#creating a vpc
resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc_cidr
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc1.id
}

resource "aws_internet_gateway_attachment" "ig_vpc" {
  internet_gateway_id = aws_internet_gateway.internet_gateway.id
  vpc_id = aws_vpc.vpc1.id
}

# creating 2 public and 2 private subnets
resource "aws_subnet" "subnet" {
  for_each = var.subnet # for-each loop iterates over each key-value pair in the input map
  vpc_id = aws_vpc.vpc1.id
  cidr_block = each.value.cidr
  availability_zone =each.value.az
  map_public_ip_on_launch = startswith(each.key,"pub") ? true:false # if condition is true, value to the "map_public_ip_on_lunch" is true else fasle
  tags = {
    Name=each.key
  }
}

# creating a route table to associate to the public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = aws_vpc.vpc1.cidr_block
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  
}
# attaching the route table to the public subnets
resource "aws_route_table_association" "rt_pub_sub" {
  for_each = {for name,subnet in aws_subnet.subnet : name => subnet if startswith(name,"pub")}
  route_table_id = aws_route_table.public_rt.id
  subnet_id = each.value.id
}

#creating elastic ip's for 2 natgateways
resource "aws_eip" "eip" {
  count=2
  tags = {
    Name="eip-${count.index}"
  }
}

#creating 2 nat gateways in 2 public subnets, and assigning 2 eips to 2 nat gateways 
resource "aws_nat_gateway" "nat_gateway" {
  count=2
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = ((values({for x,y in resource.aws_subnet.subnet : x => y if startswith(x,"pub")}))[count.index]).id
  tags = {
    Name = "nat-${count.index}"
  }

  depends_on = [aws_internet_gateway.internet_gateway]

}

# creating a private route table
resource "aws_route_table" "private-rt" {
  count=2
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }
}

# attaching the route table to the private subnets
resource "aws_route_table_association" "rt_pri_sub" {
  for_each = {for name,subnet in aws_subnet.subnet : name => subnet if startswith(name,"pri")}
  route_table_id = aws_route_table.private-rt[endswith(each.key,"1") ? 0:1].id
  subnet_id = each.value.id
}

#creating a security group for launch template
resource "aws_security_group" "sg01" {
  name        = "sg01"
  description = "Allow ssh and http inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc1.id
  tags = {
    Name = "terraform_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
#uploading a manually created key-pair to aws
resource "aws_key_pair" "keys" {
  key_name = var.keypair
  public_key = file(var.public_key)
}

#creating an ALB
resource "aws_lb" "alb" {
  name               = "test-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg01.id]
  subnets            = [for x,y in aws_subnet.subnet: y.id if startswith(x,"pub")]

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "tg-1" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc1.id
  health_check {
    enabled = true
    interval = 60
    timeout = 5
    healthy_threshold = 5
    unhealthy_threshold = 5
  }
  depends_on = [ aws_lb.alb ]
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-1.arn
  }
  depends_on = [ aws_lb_target_group.tg-1 ]
}

# creating a launch template to be used with auto scaling group
resource "aws_launch_template" "launch_template" {
  name = "terraform_LT"
  image_id = var.imageID
  instance_type = var.instance_type
  key_name = var.keypair
  user_data = base64encode(file(var.script_file))
  vpc_security_group_ids = [aws_security_group.sg01.id]
  depends_on = [ aws_lb_listener.front_end ]
}


resource "aws_autoscaling_group" "asg1" {
  name = "asg1"
  vpc_zone_identifier =  [ for x , y in aws_subnet.subnet :  y.id if startswith(x,"pri")]
  desired_capacity   = var.desired_capacity
  max_size           = var.maximum_capacity
  min_size           = var.minimum_capacity
  health_check_grace_period = 300
  health_check_type = "EC2" #  or ELB
  target_group_arns = [aws_lb_target_group.tg-1.arn]
  launch_template{
    id = aws_launch_template.launch_template.id
  }
  depends_on = [ aws_launch_template.launch_template ]
}


resource "aws_autoscaling_policy" "asg_policy" {
  autoscaling_group_name = aws_autoscaling_group.asg1.name
  name                   = "asg_policy"
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value = 50.0

    disable_scale_in = false
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
  depends_on = [ aws_autoscaling_group.asg1 ]
}

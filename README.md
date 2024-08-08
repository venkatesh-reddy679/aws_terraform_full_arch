![image](https://github.com/venkatesh-reddy679/aws_terraform/assets/60383183/19fe0269-9602-4ed9-bb17-05cba27242a8)

Note: to generate the ssh keypair, use 'ssh-keygen -t rsa' command

This Terraform configuration deploys a highly available architecture on AWS cloud 

**VPC and Subnets**:
1. Creates a VPC.
2. Configures 2 public subnets and 2 private subnets.
   
**Internet Connectivity**:

Attached an Internet Gateway to the VPC.
Created a route table with a route to use the Internet Gateway as the next hop for internet-bound traffic.
Associated this route table with the 2 public subnets.
Private Subnet Connectivity:

Deployed 2 NAT Gateways in the 2 public subnets.
Created 2 route tables, each with a route to use the respective NAT Gateway as the next hop for internet-bound traffic.
Associated these route tables with the respective private subnets.
Load Balancing:

Deployed a Network Load Balancer (NLB) in the 2 public subnets.
Created a target group for the instances.
Configured the NLB listener to forward traffic received on port 80 to the instances in the target group.
Auto Scaling:

Created a Launch Template to define the instance configuration.
Created an Auto Scaling Group (ASG) using this Launch Template, selecting both private subnets for instance deployment.
Implemented a target tracking policy to manage auto-scaling rules based on the desired metric.


**Note**: 
1. to generate the ssh keypair, use 'ssh-keygen -t rsa' command.
2. generated the ACCESS_KEY and SECRET_ACCESS_KEY for an IAM user and used AWS CLI (**aws configure**) command to authenticate the terminal with AWS cloud to do terraform deployment.

This Terraform configuration deploys a highly available architecture on AWS cloud 

![image](https://github.com/venkatesh-reddy679/aws_terraform/assets/60383183/19fe0269-9602-4ed9-bb17-05cba27242a8)

**VPC and Subnets**:
1. Creates a VPC.
2. Configures 2 public subnets and 2 private subnets.
   
**Internet Connectivity**:
1. Attaches an Internet Gateway to the VPC.
2. Creates a route table with a route to use the Internet Gateway as the next hop for internet-bound traffic.
3. Associates this route table with the 2 public subnets.
   
**Private Subnet Connectivity**:
1. Deploys 2 NAT Gateways in the 2 public subnets.
2. Creates 2 route tables, each with a route to use the respective NAT Gateway as the next hop for internet-bound traffic.
3. Associates these route tables with the respective private subnets.
   
**Load Balancing**:
1. Deploys a Network Load Balancer (NLB) instances in the 2 public subnets.
2. Creates a target group for the instances. This instance target group will be empty initially and contains instances when used with autoscaling group
3. Configures the NLB listener to forward traffic received on port 80 to port 80 of autoscaling group instances in target group that servers the application.
   
**Auto Scaling**:
1. Creates a Launch Template to define the instance configuration like AMI, instance-type, user-data, security groupps, etc.
2. Creates an Auto Scaling Group (ASG) using this Launch Template, selecting both private subnets for instance deployment.
3. Implements a target tracking policy to manage auto-scaling rules based on the desired metric. For this scenario, we use AverageCPUUtilization metrics to scale up and down the instances.


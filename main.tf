provider "aws" {
  region     = "us-east-1"
}



resource "aws_instance" "servers" {
  ami = "ami-04505e74c0741db8d"
  count = "3"
  instance_type = "t2.micro"
  key_name = "gautham"
  tags = {
    Name = "auto-servers"
  }
}

resource "aws_security_group" "servers_sg" {
  name = "servers security group"
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "elb_sg" {
  name = "elb security group"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_launch_configuration" "as_conf" {
  name          = "web_config"
  image_id      = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
}

resource "aws_placement_group" "servers_asg" {
  name     = "demo"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "servers_asg" {
  name = "auto scaling"
  availability_zones = ["us-east-1a"]
  min_size = 2
  max_size = 3
  load_balancers = ["${aws_lb.servers_lb.name}"]
  launch_configuration = aws_launch_configuration.as_conf.name
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "terraform-asg"
    propagate_at_launch = true
  }
}

# resource "aws_subnet" "public" {
#   vpc_id            = "vpc-08bbb6436aafc9a2d"
#   availability_zone = "us-east-1a"
#   cidr_block = "172.31.0.0/16"
# }

resource "aws_lb" "servers_lb" {
    name = "test-elb"
    internal = false
    load_balancer_type = "application"
    subnets = ["subnet-022a9245eca7f6c77", "subnet-0120f05e601a7b7b3"]
    security_groups = [aws_security_group.elb_sg.id]
}
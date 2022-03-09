terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.3.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = "XXXXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXXXXXXXXX"
}

resource "aws_vpc" "main" {
  cidr_block       = var.cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.tags
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.tags
  }
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = var.tags
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true  
  tags = {
    Name = var.tags
  }
}

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = var.tags
  }
}

resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = var.tags
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.tags
  }
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.tags
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "my_sg" {
  name        = "my_sg"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH into VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "key_tf" {
  key_name = "key_tf"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDXgCRW6PY//P4MML7C+JWlbdOKeQF/QXJRe9qgiW8lEBzGRxbbYq0+ez/80cfDi4HxNvNOqXoVopzRHMIaaddjnsVL/MVik4q0MTTlnsYugU5Z/PB1i78CfQYxuxwB+Y5yzLxVx/jqwvk0zJJfI9PV7JvWxme0CmtWGjz7pQBrlqXtRYvEYrzPkyWXjU6qjGdyNrDZrf5RQckiGeLtc5+JUV6WoHqxznFfyOj1BczDvcOCUpu6AkFwl+WmHGU7hLwDjsVjRMRj/uM0DQI5PZ0mxbe7jZiH7SlwRM1V0sGdCXqWLrBYz77GywXa8XR2QGZOgkP2of8jNOX8CY8+PPDz ec2-user@ip-172-31-80-75.ec2.internal"
}

resource "aws_security_group" "elb-sg" {
  name = "terraform-sample-elb-sg"
  vpc_id      = aws_vpc.main.id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = var.elb_port
    to_port     = var.elb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "myelb" {
  name               = "terraform-elb"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
  security_groups    = [aws_security_group.elb-sg.id]
  #subnets            = ["${aws_subnet.public1.id}"]

  listener {
    lb_port           = var.elb_port
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  tags = {
    Name = var.tags
  }
}

resource "aws_lb_target_group" "example-tg" {
   name     = "example-tg"
   target_type = "alb"
   port     = 80
   protocol = "HTTP"
   vpc_id   = aws_vpc.main.id
}


resource "aws_autoscaling_group" "asg_1" {
  name                      = "asg_1"
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  load_balancers            = [aws_elb.myelb.name]
  desired_capacity          = 1
  launch_configuration      = aws_launch_configuration.as_conf.name
  vpc_zone_identifier       = [aws_subnet.private1.id]
  initial_lifecycle_hook {
    name                 = "foobar"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

    notification_metadata = <<EOF
      {
        "foo": "bar"
      }
    EOF
  }
  tags = [ {
      key                 = "Name"
      value               = "${var.tags}"
      propagate_at_launch = true
    }
  ]
}

resource "aws_autoscaling_group" "asg_2" {
  name                      = "asg_2"
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  load_balancers            = [aws_elb.myelb.name]
  desired_capacity          = 1
  launch_configuration      = aws_launch_configuration.as_conf.name
  vpc_zone_identifier       = [aws_subnet.private2.id]
  initial_lifecycle_hook {
    name                 = "foobar"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

    notification_metadata = <<EOF
      {
        "foo": "bar"
      }
    EOF
  }
  tags = [ {
      key                 = "Name"
      value               = "${var.tags}"
      propagate_at_launch = true
    }
  ]
}

resource "aws_autoscaling_attachment" "asg_attachment_1" {
  autoscaling_group_name = aws_autoscaling_group.asg_1.id
  alb_target_group_arn   = aws_lb_target_group.example-tg.arn
}

resource "aws_autoscaling_attachment" "asg_attachment_2" {
  autoscaling_group_name = aws_autoscaling_group.asg_2.id
  alb_target_group_arn   = aws_lb_target_group.example-tg.arn
}

resource "aws_launch_configuration" "as_conf" {
    image_id = "ami-04505e74c0741db8d"
    key_name = "key_tf"
    instance_type = var.instance_type
    security_groups = [aws_security_group.my_sg.id]
    user_data = <<-EOF
  #!/bin/sh
  sudo apt-get update
  sudo apt-get install -y apache2
  sudo systemctl status apache2
  sudo systemctl start apache2
  sudo systemctl enable apache2
  echo "Hello GFT, Terraform challenge is done" | sudo tee /var/www/html/index.html
  EOF

  lifecycle {
    create_before_destroy = true
  }
    
} 

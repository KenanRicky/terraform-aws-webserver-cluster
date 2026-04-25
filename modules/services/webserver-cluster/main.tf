# Security Group for the web servers
resource "aws_security_group" "instance" {
  name        = "${var.cluster_name}-instance-sg"
  description = "Security group for web server instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-instance-sg"
  }
}

# Security Group for the load balancer
resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}

# Launch Template
resource "aws_launch_template" "example" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Hello from ${var.cluster_name}" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF
  )

  vpc_security_group_ids = [aws_security_group.instance.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "example" {
  name               = "${var.cluster_name}-asg"
  vpc_zone_identifier = var.subnet_ids
  desired_capacity   = var.min_size
  max_size           = var.max_size
  min_size           = var.min_size

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

# Application Load Balancer
resource "aws_lb" "example" {
  name               = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name = "${var.cluster_name}-alb"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

# Target Group
resource "aws_lb_target_group" "example" {
  name     = "${var.cluster_name}-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    port                = var.server_port
  }

  tags = {
    Name = "${var.cluster_name}-tg"
  }
}

# Attach ASG to Target Group
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.example.id
  lb_target_group_arn    = aws_lb_target_group.example.arn
}

# AMI data source
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
data "template_file" "user_data" {
  template =<<EOF
#!/bin/bash

# Update all packages
sudo yum update -y
sudo yum install -y ecs-init
sudo service docker start
sudo start ecs

# Adding cluster name in ecs config
echo ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config
cat /etc/ecs/ecs.config | grep "ECS_CLUSTER"
EOF
}

resource "aws_iam_role" "ecs_ec2_instance_role" {
  name = "ecs_ec2_instance_role"
  path = "/ecs/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ecs_ec2_instance" {
  name = "ecs_ec2_instance_profile"
  role = aws_iam_role.ecs_ec2_instance_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_role" {
  role = aws_iam_role.ecs_ec2_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_cloudwatch_role" {
  role = aws_iam_role.ecs_ec2_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

# You can have multiple ECS clusters in the same account with different resources.
# Therefore all resources created here have the name containing the name of the:
# environment, cluster name en the instance_group name.
# That is also the reason why ecs_instances is a seperate module and not everything is created here.
resource "aws_security_group" "ec2_instance" {
  name        = "sg_ec2_instance"
  vpc_id      = aws_vpc.main.id
}

# We separate the rules from the aws_security_group because then we can manipulate the
# aws_security_group outside of this module
resource "aws_security_group_rule" "outbound_internet_access" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_instance.id
}

# Default disk size for Docker is 22 gig, see http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
resource "aws_launch_configuration" "launch" {
  name_prefix          = "ecs_ec2_"
  image_id             = data.aws_ami.amazon_linux_ecs.image_id
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.ec2_instance.id]
  user_data            = data.template_file.user_data.rendered
  iam_instance_profile = aws_iam_instance_profile.ecs_ec2_instance.arn

  lifecycle {
    create_before_destroy = true
  }
}

# Instances are scaled across availability zones http://docs.aws.amazon.com/autoscaling/latest/userguide/auto-scaling-benefits.html 
resource "aws_autoscaling_group" "asg" {
  name_prefix          = "asg_"
  max_size             = 1
  min_size             = 1
  desired_capacity     = 1
  force_delete         = true
  launch_configuration = aws_launch_configuration.launch.id
  vpc_zone_identifier  = aws_subnet.private.*.id
  protect_from_scale_in = true
}

resource "aws_ecs_capacity_provider" "provider" {
  name = aws_autoscaling_group.asg.name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

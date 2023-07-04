## EC2 IAM ROLE and Instance Profile
resource "aws_iam_role" "ec2" {
  name = "${local.prefix}-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"  
  ]
  inline_policy {
    name = "dynamo"
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "ListAndDescribe",
                "Effect": "Allow",
                "Action": [
                    "dynamodb:List*",
                    "dynamodb:DescribeReservedCapacity*",
                    "dynamodb:DescribeLimits",
                    "dynamodb:DescribeTimeToLive"
                ],
                "Resource": "*"
            },
            {
                "Sid": "SpecificTable",
                "Effect": "Allow",
                "Action": [
                    "dynamodb:BatchGet*",
                    "dynamodb:DescribeStream",
                    "dynamodb:DescribeTable",
                    "dynamodb:Get*",
                    "dynamodb:Query",
                    "dynamodb:Scan",
                    "dynamodb:BatchWrite*",
                    "dynamodb:CreateTable",
                    "dynamodb:Delete*",
                    "dynamodb:Update*",
                    "dynamodb:PutItem"
                ],
                "Resource": aws_dynamodb_table.this.arn
            }
        ]
    })
  }

  tags = merge({
          Name = "${local.prefix}-ec2"
      }, var.tags)
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.prefix}-ec2"
  role = aws_iam_role.ec2.name
}

## EC2 ASG + Template
resource "aws_launch_template" "this" {
  name_prefix   = "${local.prefix}-ec2"
  image_id      = local.ami_id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }
  key_name = var.ec2_key_pair_name
  vpc_security_group_ids = [aws_security_group.ec2.id]

  dynamic tag_specifications {
    for_each = local.tag_spec_resources
    content {
      resource_type = tag_specifications.value

      tags = merge({
            Name = "${local.prefix}-ec2"
        }, var.tags)
    } 
  }

  user_data = base64encode(local.user_data)

  tags = merge({
          Name = "${local.prefix}-ec2"
      }, var.tags)
}

resource "aws_autoscaling_group" "this" {
  # availability_zones = local.azs
  desired_capacity   = var.desired_instance_capacity
  max_size           = 2
  min_size           = 0

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # target_group_arns = module.alb.target_group_arns
  vpc_zone_identifier = module.vpc.public_subnets

  dynamic tag {
    for_each = var.tags

    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
}
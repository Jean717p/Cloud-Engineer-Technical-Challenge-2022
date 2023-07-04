### VPC and subnets

module "vpc" {
    # https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/README.md
    source = "terraform-aws-modules/vpc/aws"

    name = "${local.prefix}-vpc"
    cidr = "10.0.0.0/16"

    azs             = local.azs
    public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]

    #   enable_ipv6 = true
    create_vpc = true
    create_igw = true
    create_database_subnet_group = false
    create_elasticache_subnet_group = false
    create_redshift_subnet_group = false
    enable_nat_gateway = false
    enable_vpn_gateway = false

    public_subnet_tags = {
        Name = "${local.prefix}-public"
    }

    tags = var.tags

    vpc_tags = merge({
        Name = "${local.prefix}-vpc"
    }, var.tags)
}

### Security group

resource "aws_security_group" "alb" {
    name        = "${local.prefix}-alb"
    description = "Allow alb inbound traffic"
    vpc_id      = module.vpc.vpc_id

    ingress {
      description      = "Http from Internet"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    tags = merge({
      Name = "${local.prefix}-alb"
    }, var.tags)
}


resource "aws_security_group" "ec2" {
    name        = "${local.prefix}-ec2"
    description = "Allow ec2 inbound traffic from alb"
    vpc_id      = module.vpc.vpc_id

    ingress {
      description      = "Http from alb"
      from_port        = var.app_port
      to_port          = var.app_port
      protocol         = "tcp"
      security_groups  = [aws_security_group.alb.id]
    }

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    tags = merge({
      Name = "${local.prefix}-ec2"
    }, var.tags)
}


# ALB

module "alb" {
    # https://github.com/terraform-aws-modules/terraform-aws-alb
    source  = "terraform-aws-modules/alb/aws"
    version = "~> 6.0"

    name = "${local.prefix}-alb"

    load_balancer_type = "application"

    vpc_id             = module.vpc.vpc_id
    subnets            = module.vpc.public_subnets
    security_groups    = [aws_security_group.alb.id]

    target_groups = [
      {
        name_prefix      = local.prefix
        backend_protocol = "HTTP"
        backend_port     = var.app_port
        target_type      = "instance"
        deregistration_delay = 30
        health_check     = {
          enabled = true
          path = var.healthcheck_path
        }
      }
    ]

    http_tcp_listeners = [
      {
        port               = 80
        protocol           = "HTTP"
        target_group_index = 0
      }
    ]

    tags = merge({
          Name = "${local.prefix}-alb"
      },var.tags)
}










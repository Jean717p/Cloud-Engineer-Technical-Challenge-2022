## ECS 
resource "aws_iam_role" "task" {
  name = "${local.prefix}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = ["ecs.amazonaws.com","ecs-tasks.amazonaws.com"]
        }
      },
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
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
          Name = "${local.prefix}-task"
      }, var.tags)
}


resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name

  # setting {
  #   name  = "containerInsights"
  #   value = "enabled"
  # }
  tags = merge({
          Name = "${local.prefix}-cluster"
      }, var.tags)
}

resource "aws_ecs_task_definition" "this" {
  family = "${local.prefix}-taskdef"
  container_definitions = jsonencode([
    {
      name      = aws_ecr_repository.this.name
      image     = aws_ecr_repository.this.repository_url
      essential = true
      memory    = 128
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
        }
      ]
      environment = [{
        name = "TC_DYNAMO_TABLE"
        value = aws_dynamodb_table.this.name
      }]

    }
  ])
  network_mode = "host"
  requires_compatibilities = ["EC2"]
  task_role_arn = aws_iam_role.task.arn
  execution_role_arn = aws_iam_role.task.arn
  tags = merge({
          Name = "${local.prefix}-taskdef"
      }, var.tags)
}

resource "aws_ecs_service" "this" {
  name            = "${local.prefix}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  lifecycle {
    ignore_changes = [task_definition] # new versions published by pipeline
  }
  desired_count   = var.desired_tasks

  ordered_placement_strategy {
    type = "spread"
    field = "instanceId"
  }
  deployment_minimum_healthy_percent = 0

  # scheduling_strategy = "DAEMON"

  load_balancer {
    target_group_arn = module.alb.target_group_arns[0]
    container_name   = aws_ecr_repository.this.name
    container_port   = var.app_port
  }

  tags = merge({
          Name = "${local.prefix}-service"
      }, var.tags)
}
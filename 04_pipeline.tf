# Codecommit + Codebuild + ECR + CodePipeline
resource "aws_ecr_repository" "this" {
  name                 = "${local.prefix}-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false  # 
  }
  force_delete = true # Mock easy destroy

  tags = merge({
        Name = "${local.prefix}-ecr"
    }, var.tags)
}


resource "aws_codecommit_repository" "this" {
  repository_name = "${local.prefix}-codecommit"
  description     = "This is the Repository"
  tags = merge({
        Name = "${local.prefix}-codecommit"
    }, var.tags)
}


resource "aws_iam_role" "codepipeline" {
  name = "${local.prefix}-codepipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
  # managed_policy_arns = [""]
  inline_policy {
    name = "codepipeline"
    policy = jsonencode({
    "Statement": [
        {
            "Effect":"Allow",
            "Action": [
                "s3:*Object"
            ],
            "Resource": [
                "arn:aws:s3:::${var.artifact_store}",
                "arn:aws:s3:::${var.artifact_store}/*"
            ]
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "ecs:*",
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ],
    "Version": "2012-10-17"
})
  }

  tags = merge({
          Name = "${local.prefix}-codepipeline"
      }, var.tags)
}


resource "aws_iam_role" "codebuild" {
  name = "${local.prefix}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
  # managed_policy_arns = [""]
  inline_policy {
    name = "codebuild"
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect":"Allow",
        "Action": [
            "s3:*Object*"
        ],
        "Resource": [
            "arn:aws:s3:::${var.artifact_store}",
            "arn:aws:s3:::${var.artifact_store}/*"
        ]
        },
        {
        "Effect": "Allow",
        "Action": [
            "codecommit:*",
            "ecr:*",
            "codebuild:*",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        "Resource": "*"
        }
    ]
    })
  }

  tags = merge({
          Name = "${local.prefix}-codebuild"
      }, var.tags)
}



resource "aws_codebuild_project" "this" {
  name          = "${local.prefix}-codebuild"
  description   = "${local.prefix}-codebuild"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = true

  }

  tags = merge({
          Name = "${local.prefix}-codebuild"
      }, var.tags)
}


resource "aws_codepipeline" "this" {
  name     = "${local.prefix}-codepipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = var.artifact_store
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = aws_codecommit_repository.this.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.this.name
        EnvironmentVariables = jsonencode([
          {
            name  = "IMAGE_REPO_NAME"
            value = aws_ecr_repository.this.name
            type  = "PLAINTEXT"
          },
          {
            name  = "CONTAINER_NAME"
            value = aws_ecr_repository.this.name
            type  = "PLAINTEXT"
          },
          {
            name  = "AWS_ACCOUNT_ID"
            value = data.aws_caller_identity.current.account_id
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.this.name
        ServiceName = aws_ecs_service.this.name
      }
    }
  }
}
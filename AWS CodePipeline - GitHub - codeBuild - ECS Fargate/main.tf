# ECS Task Execution Role for the ECS Task definition
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role_policy.json
}

data "aws_iam_policy_document" "ecs_task_execution_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



# resource "aws_iam_policy" "ecs_policy" {
#   name        = "ecs-policy"
#   description = "Permissions for ECS tasks to access ECR and logs"
  
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchGetImage",
#           "ecr:GetDownloadUrlForLayer",
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_policy_attachment" {
#   policy_arn = aws_iam_policy.ecs_policy.arn
#   role       = aws_iam_role.ecs_task_execution_role.name
# }









# Create a VPC
resource "aws_vpc" "html_app_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "html-app-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "html_app_igw" {
  vpc_id = aws_vpc.html_app_vpc.id
  tags = {
    Name = "html-app-igw"
  }
}

# Create a Subnet
resource "aws_subnet" "html_app_subnet" {
  vpc_id            = aws_vpc.html_app_vpc.id
  cidr_block        = var.subnet_cidr
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "html-app-subnet"
  }
}

# Create a Route Table
resource "aws_route_table" "html_app_route_table" {
  vpc_id = aws_vpc.html_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.html_app_igw.id
  }

  tags = {
    Name = "html-app-route-table"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "html_app_route_table_association" {
  subnet_id      = aws_subnet.html_app_subnet.id
  route_table_id = aws_route_table.html_app_route_table.id
}

# Create a Security Group
resource "aws_security_group" "html_app_sg" {
  vpc_id = aws_vpc.html_app_vpc.id
  name   = "html-app-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "html-app-sg"
  }
}

resource "aws_ecr_repository" "html_app" {
  name = var.ecr_repo_name
}

resource "aws_codebuild_project" "html_app_build" {
  name          = "html-app-build"
  description   = "Build project for simple HTML app"
  build_timeout = 5

  source {
    type            = "GITHUB"
    location        = "https://github.com/${var.github_repository}.git"
    git_clone_depth = 1
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    environment_variable {
      name  = "ECR_REPO_URL"
      value = aws_ecr_repository.html_app.repository_url
    }
  }

  service_role = aws_iam_role.codebuild_role.arn
}


resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy.json
}

data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_codepipeline" "ci_cd_pipeline" {
  name     = "simple-html-app-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner         = var.github_repository_owner
        Repo          = var.github_repository
        Branch        = "main"
        OAuthToken    = var.github_oauth_token
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
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.html_app_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      version          = "1"
      input_artifacts  = ["build_output"]

      configuration = {
        ClusterName     = var.ecs_cluster_name
        ServiceName     = var.ecs_service_name
      }
    }
  }
}

resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "simple-html-app-pipeline-artifacts"
}

resource "aws_ecs_cluster" "html_app_cluster" {
  name = var.ecs_cluster_name
}

resource "aws_ecs_task_definition" "html_app_task" {
  family                   = var.ecs_task_definition_name
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  memory                  = "512"
  cpu                     = "256"

  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn  # Add this line

  container_definitions = jsonencode([{
    name      = "html-app-container"
    image     = "${aws_ecr_repository.html_app.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort     = 80
    }]
  }])
}


resource "aws_ecs_service" "simple_html_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.html_app_cluster.id
  task_definition = aws_ecs_task_definition.html_app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.html_app_subnet.id]
    security_groups  = [aws_security_group.html_app_sg.id]
    assign_public_ip = true
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role_policy.json
}

data "aws_iam_policy_document" "codepipeline_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
  role       = aws_iam_role.codebuild_role.name
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
  role       = aws_iam_role.codepipeline_role.name
}

resource "aws_iam_role_policy_attachment" "codepipeline_s3_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess" 
  role       = aws_iam_role.codepipeline_role.name
}

// codepipeline_role does not have the necessary permissions to perform the codebuild:StartBuild, codebuild:BatchGetBuilds, and codebuild:StopBuild actions.
// Giving the permissions below

# Create a policy document for CodeBuild permissions

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    actions = [
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds",
      "codebuild:StopBuild",
    ]
    resources = [
      "arn:aws:codebuild:${var.aws_region}:${data.aws_caller_identity.current.account_id}:project/html-app-build"
    ]
  }
}

# Create an IAM policy for CodeBuild
resource "aws_iam_policy" "codebuild_policy" {
  name   = "CodeBuildPermissions"
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

# Attach the policy to the codepipeline_role
resource "aws_iam_role_policy_attachment" "codepipeline_codebuild_policy" {
  policy_arn = aws_iam_policy.codebuild_policy.arn
  role       = aws_iam_role.codepipeline_role.name
}

// The codebuild-role does not have the necessary permissions to create log streams in Amazon CloudWatch Logs. 
// permissions required "logs:CreateLogGroup","logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups",
// "logs:DescribeLogStreams"

// so here giving the required permissions

# Create a policy document for CloudWatch Logs permissions
data "aws_iam_policy_document" "codebuild_logs_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "*"
    ]
  }
}

# Create an IAM policy for CloudWatch Logs
resource "aws_iam_policy" "codebuild_logs_policy" {
  name   = "CodeBuildLogsPermissions"
  policy = data.aws_iam_policy_document.codebuild_logs_policy.json
}

# Attach the policy to the codebuild_role
resource "aws_iam_role_policy_attachment" "codebuild_logs_policy_attachment" {
  policy_arn = aws_iam_policy.codebuild_logs_policy.arn
  role       = aws_iam_role.codebuild_role.name
}

// the codebuild-role does not have the necessary permissions s3 permissions "s3:GetObject","s3:ListBucket"

// adding the permissions

# Create a policy document for S3 permissions
data "aws_iam_policy_document" "codebuild_s3_policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::simple-html-app-pipeline-artifacts",
      "arn:aws:s3:::simple-html-app-pipeline-artifacts/*"  # Allow access to all objects in the bucket
    ]
  }
}

# Create an IAM policy for S3 permissions
resource "aws_iam_policy" "codebuild_s3_policy" {
  name   = "CodeBuildS3Permissions"
  policy = data.aws_iam_policy_document.codebuild_s3_policy.json
}

# Attach the policy to the codebuild_role
resource "aws_iam_role_policy_attachment" "codebuild_s3_policy_attachment" {
  policy_arn = aws_iam_policy.codebuild_s3_policy.arn
  role       = aws_iam_role.codebuild_role.name
}

// codeBuild_role do not have the ECR necesssary permissions "ecr:GetAuthorizationToken","ecr:BatchCheckLayerAvailability","ecr:GetDownloadUrlForLayer","ecr:BatchGetImage"

// Create the IAM polic for the ECR permissions
resource "aws_iam_policy" "codebuild_ecr_policy" {
  name   = "CodeBuildECRPermissions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:DescribeRepositories",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the codeBuild_role through the codebuild-ecr_policy
resource "aws_iam_role_policy_attachment" "attach_codebuild_ecr_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_ecr_policy.arn
}


//  codepipeline_role did not have the necessary permissions 
# Attach additional policies to the CodePipeline role
resource "aws_iam_role_policy_attachment" "ecs_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  role       = aws_iam_role.codepipeline_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.codepipeline_role.name
}








# resource "aws_iam_policy" "codepipeline_policy" {
#   name        = "codepipeline-policy"
#   description = "Permissions for CodePipeline to interact with ECS"
  
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ecs:UpdateService",
#           "ecs:DescribeServices",
#           "ecs:ListTasks",
#           "ecs:DescribeTaskDefinition",
#           "ecs:RegisterTaskDefinition"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
#   policy_arn = aws_iam_policy.codepipeline_policy.arn
#   role       = aws_iam_role.codepipeline_role.name
# }
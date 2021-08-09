data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_role" "ecs_service_role" {
  name = "AWSServiceRoleForECS"
}

data "aws_iam_policy_document" "td_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "td_role_policy" {
  statement {
    actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    resources = [
        "*"
    ]
  }
}

data "aws_ecs_task_definition" "icinga" {
  task_definition = "td-${var.env_name}-icinga"
}

data "aws_security_group" "dc_internal" {
  name = local.security_group
}

data "aws_lb_target_group" "tg" {
  name = "tg-${var.env_name}-monitoring"
  depends_on  = [aws_lb_target_group.monitoring_tg]
}

data "aws_route53_zone" "selected" {
  name         = var.hosted_zone
  private_zone = true
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}
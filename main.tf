locals {
  security_group = "sgr-${var.env_name}-dc-internal"
  load_balancer  = {"target_group_arn":"${data.aws_lb_target_group.tg.arn}","container_name":"icinga","container_port":80}
  service_name   = "${var.env_name}-monitoring"
  task_definition_family = "icinga"
}

resource "aws_ecs_cluster" "monitoring_cluster" {
  name = "ecs-${local.service_name}"
  capacity_providers = ["FARGATE"]

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    var.tags,
    map(
      "Name", "ecs-${local.service_name}",
      "environment", var.env_name,
      "application_role", "monitoring",
      "created_by", "terraform"
    )
  )
}

resource "aws_ecs_service" "monitoring_service" {
  name            = "ecs-${local.service_name}-service"
  cluster         = aws_ecs_cluster.monitoring_cluster.id
  task_definition = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/td-${var.env_name}-icinga:${data.aws_ecs_task_definition.icinga.revision}"
  desired_count   = 1
  launch_type = "FARGATE"
  depends_on      = [aws_iam_role_policy.td_role_policy,aws_lb.monitoring_lb]
  tags = merge(
    var.tags,
    map(
      "Name", "ecs-${local.service_name}-service",
      "environment", var.env_name,
      "application_role", "monitoring",
      "created_by", "terraform"
    )
  )

  network_configuration {
    security_groups  = [data.aws_security_group.selected.id]
    subnets          = var.service_subnets
  }


  load_balancer {
    target_group_arn = local.load_balancer.target_group_arn
    container_name   = local.load_balancer.container_name
    container_port   = local.load_balancer.container_port
  }
}

resource "aws_lb_target_group" "monitoring_tg" {
  name        = "tg-${local.service_name}"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  tags = merge(
    var.tags,
    map(
      "Name", "tg-${local.service_name}",
      "environment", var.env_name,
      "application_role", "monitoring",
      "created_by", "terraform"
    )
  )
}

resource "aws_lb" "monitoring_lb" {
  name               = "nlb-${local.service_name}"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.service_subnets
  enable_deletion_protection = var.enable_deletion_protection
  tags = merge(
    var.tags,
    map(
      "Name", "nlb-${local.service_name}",
      "environment", var.env_name,
      "application_role", "monitoring",
      "created_by", "terraform"
    )
  )
}

resource "aws_lb_listener" "monitoring_lb_listener" {
  load_balancer_arn = aws_lb.monitoring_lb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.monitoring_tg.arn
  }
}

resource "aws_iam_role" "task_execution_role" {
  name               = "${local.service_name}-role"
  assume_role_policy = data.aws_iam_policy_document.td_assume_role_policy.json
}

resource "aws_iam_role_policy" "td_role_policy" {
  name   = "task_execution_policy"
  role   = aws_iam_role.task_execution_role.id
  policy = data.aws_iam_policy_document.td_role_policy.json
}

resource "aws_route53_record" "monitoring_service_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "new_monitoring"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.monitoring_lb.dns_name]
}

resource "random_password" "password" {
  length   = 14
  special  = false
  upper    = false
}

resource "aws_ssm_parameter" "random_password" {
  name        = "db_password_monitoring"
  description = "Monitoring DB password"
  type        = "SecureString"
  value       = random_password.password.result
}

resource "aws_ssm_parameter" "db_username" {
  name        = "db_username_monitoring"
  description = "Monitoring DB username"
  type        = "String"
  value       = "admin"
}

resource "aws_db_subnet_group" "default" {
  name       = "netgr-${local.service_name}"
  subnet_ids = var.db_subnets
  tags = merge(
    var.tags,
    map(
      "Name", "netgr-${local.service_name}",
      "environment", var.env_name,
      "application_role", "monitoring",
      "created_by", "terraform"
    )
  )
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  identifier           = "db-${local.service_name}"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  name                 = "monitoring"
  username             = "admin"
  password               = random_password.password.result
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [data.aws_security_group.selected.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
  deletion_protection = var.enable_deletion_protection
  backup_retention_period = var.backup_retention_period
  tags = merge(
    var.tags,
    map(
      "Name", "${local.service_name}",
      "environment", var.env_name,
      "application_role", "monitoring",
      "created_by", "terraform"
    )
  )
}

resource "aws_route53_record" "monitoring_db_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "monitoring-db"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_db_instance.default.address]
}

resource "aws_ecs_task_definition" "service_td" {
  count = var.task_definition_already_exists ? 0 : 1
  family                   = "td-${var.env_name}-${local.task_definition_family}"
  container_definitions    = templatefile("${path.module}/templates/icinga.json.tpl",{ ENV_NAME = var.env_name, SHORT_ENV_NAME = var.short_env_name }) 
  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }
  lifecycle {
    ignore_changes = all
   }
}
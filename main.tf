locals {
  security_group = "sgr-${var.env_name}-dc-internal"
  load_balancer  = {"target_group_arn":"${data.aws_lb_target_group.tg.arn}","container_name":"icinga","container_port":80}
  service_name   = "${var.env_name}-monitoring"
}

resource "aws_ecs_cluster" "monitoring_cluster" {
  name = "ecs-${local.service_name}"
  capacity_providers = ["FARGATE"]

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "monitoring_service" {
  name            = "ecs-${local.service_name}-service"
  cluster         = aws_ecs_cluster.monitoring_cluster.id
  task_definition = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/td-${var.env_name}-icinga:${data.aws_ecs_task_definition.icinga.revision}"
  desired_count   = 1
  launch_type = "FARGATE"
  depends_on      = [aws_iam_role_policy.td_role_policy,aws_lb.monitoring_lb]

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
}

resource "aws_lb" "monitoring_lb" {
  name               = "nlb-${local.service_name}"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.service_subnets
  enable_deletion_protection = false

  tags = {
    Environment = "${var.env_name}"
  }
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
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  identifier           = local.service_name
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
}

resource "aws_route53_record" "monitoring_db_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "monitoring-db"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_db_instance.default.address]
}
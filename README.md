# terraform-aws-logging-service
Toluna [Terraform module](https://registry.terraform.io/modules/toluna-terraform/logging-service/aws/latest), which creates Logstash service on ECS Fargate.

## Usage
```module "monitoring_service"{
  source = "toluna-terraform/monitoring-service/aws"
  version = "~>0.0.1"
  env_name = local.main.env_name
  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.private_subnet_ids
  hosted_zone = "___.tolunainsights-internal.com"
}```

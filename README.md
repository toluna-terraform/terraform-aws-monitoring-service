# terraform-aws-monitoring-service
Toluna [Terraform module](https://registry.terraform.io/modules/toluna-terraform/monitoring-service/aws/latest), which creates Icinga service on ECS Fargate.

## Usage
```
module "monitoring_service"{
  source = "toluna-terraform/monitoring-service/aws"
  short_env_name = local.main.short_env_name
  version = "~>0.0.2"
  env_name = local.main.env_name
  vpc_id = module.vpc.vpc_id
  service_subnets = module.vpc.private_subnet_ids
  db_subnets = module.vpc.private_subnet_management_ids
  hosted_zone = "${short_env_name}.tolunainsights-internal.com" // e.g. "qac.tolunainsights-internal.com"
  tags     = local.tags
  task_definition_already_exists = true // change to false if the TD (icinga) is not exist.
  
}
```

## Production
If you Apply this module on Production environment, please set:
```
enable_deletion_protection = true
backup_retention_period = 7
```

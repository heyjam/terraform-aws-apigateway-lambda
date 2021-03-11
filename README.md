# terraform-aws-apigateway-lambda

## Variables

- sample tfvars : dev.tfvars.sample

| Variable               |                    desc                   |         default        |
|------------------------|:-----------------------------------------:|:----------------------:|
| region                 |                 aws region                |     ap-northeast-2     |
| project                |     api gw uri path = /v1/{project}/pm    |            -           |
| tags                   |       { developer-number  = 1101388}      |            -           |
| lambda_zip_filename    |                  filename                 |     lambda_function    |
| lambda_function_name   |               function name               |         pm-page        |
| apigateway_name        |              api gateway name             |        pm-apigw        |
| apigateway_desc        |          api gateway description          | pm page open/close api |
| pm_nlb_name            |              생성할 NLB name              |                        |
| pm_targetgroup_80      |      PM open 할때 사용할 target group     |          tg-pm         |
| service_lb_name        |         현재 서비스 중인 nlb name         |                        |
| service_tagetgroup_80  | 현재 서비스 중인 nlb 의 target group name |                        |
| service_tagetgroup_443 | 현재 서비스 중인 nlb 의 target group name |                        |



## How to run

```bash

terraform init
terraform plan -var-file dev.tfvars
terraform apply -var-file dev.tfvars

```

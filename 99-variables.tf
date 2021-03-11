variable "region" {
  description = "생성될 리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "vpc_id" {
  description = "VPC where the cluster and workers will be deployed."
  type        = string
}

variable "subnets" {
  description = "A list of subnets to place the EKS cluster and workers within."
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

variable "lambda_function_name" {
  description = "A lambda function name"
  default     = "pm-page"
}

variable "apigateway_name" {
  description = "A api gateway name"
  default = "pm-apigw"  
}

variable "apigateway_desc" {
  description = "A api gateway description"
  default = "pm page open/close api"
}

variable "project" {
  description = "A project name. Important - api-gateway url "
  default = "tour"
}

variable "lambda_zip_filename" {
  description = "A temp zip file name that template/lambda_code files"
  default     = ""
}


############## tg nlb tg ########
variable "pm_nlb_name" {
  description = "pm nlb name"
  default = "nlb-pm"
}

variable "pm_targetgroup_80" {
  description = "prod ticket nlb target group name"
  type = string
  default = "tg-pm"
}

variable "service_lb_name" {
  default = "testnlb"
}
variable "service_tagetgroup_80" {
  default = "testtg"
}
variable "service_tagetgroup_443" {
  default = "testtg443"
}
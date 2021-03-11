
output "region" {
  description = "AWS region."
  value       = var.region
}

output "api_url" {
  value = "${aws_api_gateway_deployment.pm.invoke_url}/${var.project}/pm"
}


############## tg nlb tg ########

# output "pm_nlb_tg_output" {
#   value = aws_lb_target_group.pm_nlb_target_group
# }


# output "pm_nlb_output" {
#   value = aws_lb.pm_nlb
# }

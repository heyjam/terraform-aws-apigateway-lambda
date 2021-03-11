
# Create a new load balancer
resource "aws_lb" "pm_nlb" {
  name = var.pm_nlb_name

  enable_cross_zone_load_balancing = "true"
  enable_deletion_protection       = "false"
  internal                         = "true"
  ip_address_type                  = "ipv4"
  load_balancer_type               = "network"

  subnets = var.subnets
  tags = var.tags
}

resource "aws_lb_target_group" "pm_nlb_target_group_to_idc_pmpage" {
  health_check {
    enabled             = "true"
    healthy_threshold   = "2"
    interval            = "10"
    matcher             = "200-399"
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "6"
    unhealthy_threshold = "2"
  }

  name              = "${var.pm_nlb_name}-${var.pm_targetgroup_80}-to-pmpage"

  port              = "80"
  protocol          = "TCP"
  proxy_protocol_v2 = "false"
  tags              = var.tags
  target_type       = "ip"
  vpc_id            = var.vpc_id
  deregistration_delay = "60"
}


# listener
resource "aws_lb_listener" "pm_nlb_listener" {
  default_action {
    order            = "1"
    # target_group_arn = var.dev_target_group_arn
    target_group_arn = aws_lb_target_group.pm_nlb_target_group_to_idc_pmpage.arn
    type             = "forward"
  }
  # load_balancer_arn = var.dev_load_balancer_id
  load_balancer_arn = aws_lb.pm_nlb.id
  port              = "80"
  protocol          = "TCP"
}

# target group
resource "aws_lb_target_group" "service_target_group_to_pm_nlb" {
  health_check {
    enabled             = "true"
    healthy_threshold   = "2"
    interval            = "10"
    matcher             = "200-399"
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "6"
    unhealthy_threshold = "2"
  }

  name              = var.pm_targetgroup_80

  port              = "80"
  protocol          = "TCP"
  proxy_protocol_v2 = "false"
  tags              = var.tags
  target_type       = "ip"
  vpc_id            = var.vpc_id
  deregistration_delay = "60"
}



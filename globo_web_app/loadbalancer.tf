## aws_elb_service_account
data "aws_elb_service_account" "root" {}

## aws_lb
resource "aws_lb" "nginx" {
  name               = "${local.name_prefix}-globo-web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets

  access_logs {
    bucket  = module.web_app_s3.web_bucket.id
    prefix  = "alb-logs"
    enabled = true
  }

  enable_deletion_protection = false

  tags = local.common_tags
}

## aws_lb_target_group
resource "aws_lb_target_group" "nginx" {
  name     = "${local.name_prefix}-nginx-alb-tg"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  tags = local.common_tags
}

## aws_lb_listener
resource "aws_lb_listener" "nginx" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = var.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nginx-lb-listener"
  })
}

## aws_lb_target_group_attachment
resource "aws_lb_target_group_attachment" "nginx" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.nginx.arn
  target_id        = aws_instance.nginx[count.index].id
  port             = var.port
}

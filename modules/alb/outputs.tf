output "alb_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.this.arn
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "listener_arn" {
  description = "ARN of the load balancer listener"
  value       = aws_lb_listener.this.arn
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

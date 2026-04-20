# OUTPUT CODE

output "alb_dns_name" {
  value       = aws_lb.webserver.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.webserver_asg.name
  description = "The name of the Auto Scaling Group"
}

output "alb_arn" {
  value       = aws_lb.webserver.arn
  description = "ARN of the load balancer"
}

output "target_group_arn" {
  value       = aws_lb_target_group.webserver.arn
  description = "ARN of the target group"
}

output "launch_template_id" {
  value       = aws_launch_template.webserver.id
  description = "ID of the launch template"
}

output "security_group_ids" {
  value = {
    alb      = aws_security_group.alb.id
    instance = aws_security_group.instance.id
  }
  description = "Security group IDs created by the module"
}
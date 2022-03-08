output "vpc_id" {
  description = "ID of project VPC"
  value       = aws_vpc.main.id
}

output "lb_url" {
  description = "URL of load balancer"
  value       = aws_elb.myelb.arn
}

output "elb_dns_name" {
  value       = aws_elb.myelb.dns_name
  description = "The domain name of the load balancer"
}
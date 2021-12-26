output "frontend_url" {
  value = "http://${aws_lb.front_end.dns_name}"
}

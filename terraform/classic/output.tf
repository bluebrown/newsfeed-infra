output "frontend_dns" {
  value = aws_lb.front_end.dns_name
}

output "statics_bucket_dns" {
  value = aws_s3_bucket.statics.bucket_domain_name
}

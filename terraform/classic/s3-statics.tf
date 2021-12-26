resource "aws_s3_account_public_access_block" "allow_public" {
  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket" "statics" {
  depends_on    = [aws_s3_account_public_access_block.allow_public]
  bucket        = "statics.newsfeed.classic"
  force_destroy = true

  tags = {
    Name = "${module.vpc.name}-statics"
  }

  acl = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["http://${aws_lb.front_end.dns_name}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

}

resource "aws_s3_bucket_object" "file" {
  for_each    = fileset(var.statics_path, "**")
  bucket      = aws_s3_bucket.statics.id
  key         = each.key
  source      = "${var.statics_path}/${each.key}"
  source_hash = filemd5("${var.statics_path}/${each.key}")
  acl         = "public-read"
  // extra hack because s3 cant detect mime type css properly
  content_type = length(regexall("^.*\\.css$", each.key)) > 0 ? "text/css" : null
}

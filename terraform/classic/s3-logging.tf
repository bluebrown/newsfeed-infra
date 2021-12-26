resource "aws_s3_bucket" "logs" {
  bucket = "com.thoughtworks.logs"

  tags = {
    Name = "${module.vpc.name}-lb-logs"
  }

  acl           = "private"
  force_destroy = true

}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "allow-elb-logs",
    "Statement": [
        {
            "Sid": "RegionRootArn",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${data.aws_elb_service_account.main.arn}"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.logs.arn}/*"
        },
        {
            "Sid": "AWSLogDeliveryWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.logs.arn}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "AWSLogDeliveryAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.logs.arn}"
        }
    ]
}
  POLICY
}

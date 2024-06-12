locals {
  mime_types = {
    "css"  = "text/css"
    "scss" = "text/css"
    "html" = "text/html"
    "js"   = "application/javascript"
    "jpg"  = "mage/jpeg"
    "txt"  = "text/plain"
    "svg"  = "image/svg+xml"
  }
}

provider "aws" {
    region = "us-east-1"
    shared_credentials_files = ["C:/Users/Chirag Singh/.aws/credentials"]
}

resource "aws_s3_bucket" "resume" {
  bucket = "cloud-resume-static-website-chirag"

  tags = {
    Name        = "Cloud Resume"
  }
}

# resource "aws_s3_bucket_acl" "example" {
#   bucket = aws_s3_bucket.resume.id
#   acl    = "private"
# }

resource "aws_s3_bucket" "log_bucket" {
  bucket = "cloud-resume-static-website-chirag-logging"
}

# resource "aws_s3_bucket_acl" "log_bucket_acl" {
#   bucket = aws_s3_bucket.log_bucket.id
#   acl    = "log-delivery-write"
# }

resource "aws_s3_bucket_logging" "logging-setting" {
  bucket = aws_s3_bucket.resume.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_public_access_block" "public-access-setting" {
  bucket = aws_s3_bucket.resume.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "versioning-setting" {
  bucket = aws_s3_bucket.resume.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "static-website-setting" {
  bucket = aws_s3_bucket.resume.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.resume.id
  policy =  <<EOT
            {
                "Id": "Policy1718138962834",
                "Version": "2012-10-17",
                "Statement": [
                    {
                    "Sid": "Stmt1718138958620",
                    "Action": [
                        "s3:GetObject"
                    ],
                    "Effect": "Allow",
                    "Resource": "${aws_s3_bucket.resume.arn}/*",
                    "Principal": "*"
                    }
                ]
            }
            EOT
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.resume.id
  for_each = fileset("./Resume", "**")
  key = each.value
  source = "Resume/${each.value}"
  source_hash = filemd5("Resume/${each.value}")
#   acl = "public-read" # Use "public-read" if you want the files to be publicly accessible
  content_type = lookup(tomap(local.mime_types), element(split(".", each.key), length(split(".", each.key)) - 1), "text/plain")
}

output "cloud-resume-endpoint" {
    value = aws_s3_bucket_website_configuration.static-website-setting.website_endpoint
}




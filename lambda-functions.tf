# Define IAM Role for LAmbda
resource "aws_iam_role" "lambda_role" {
 name   = "terraform_aws_lambda_role"
 assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM policy for logging from a lambda
resource "aws_iam_policy" "lambda" {
  name         = "aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Define DynamoDB Access Policy
resource "aws_iam_policy" "dynamodb-policy" {
  name        = "dynamodb_full_access"
  path        = "/"
  description = "Provide full access to DynamoDB"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1718254342777",
      "Action": [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:GetRecords",
        "dynamodb:ListTables",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:UpdateTable"
      ],
      "Effect": "Allow",
      "Resource": "${aws_dynamodb_table.cloud-resume-visitor-count-table.arn}"
    }
  ]
})
}

# Lambda Policy Attachment on the role.
resource "aws_iam_role_policy_attachment" "attach_lambda_policy_to_iam_role" {
  role        = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.lambda.arn
}

#DynamoDB Policy Attachment on the role.
resource "aws_iam_role_policy_attachment" "attach_dynamodb_policy_to_iam_role" {
  role        = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.dynamodb-policy.arn
}

# Generates an archive from content, a file, or a directory of files.
data "archive_file" "zip_the_python_code" {
 type        = "zip"
 source_dir  = "${path.module}/python/"
 output_path = "${path.module}/python/lambda_function.zip"
}

# Create a lambda function
resource "aws_lambda_function" "terraform_lambda_func" {
 filename                       = "${path.module}/python/lambda_function.zip"
 function_name                  = "track-visitor-count"
 role                           = aws_iam_role.lambda_role.arn
 handler                        = "lambda_function.lambda_handler"
 runtime                        = "python3.8"
 depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_to_iam_role, aws_iam_role_policy_attachment.attach_dynamodb_policy_to_iam_role]
}

# Trigger permissions for S3
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.log_bucket.arn
}

# Map Lambda Function to trigger from S3
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.log_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.terraform_lambda_func.arn
    events              = ["s3:ObjectCreated:*"]
  }
    depends_on = [aws_lambda_permission.allow_bucket]
}
resource "aws_dynamodb_table" "cloud-resume-visitor-count-table" {
  name           = "resume-visitor-count"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "ID"

  attribute {
    name = "ID"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-1"
  }
}

resource "aws_dynamodb_table_item" "initial-database" {
  table_name = aws_dynamodb_table.cloud-resume-visitor-count-table.name
  hash_key   = aws_dynamodb_table.cloud-resume-visitor-count-table.hash_key

  item = <<ITEM
  {
    "ID": {"S": "1"},
    "VisitorCount": {"N": "0"}
  }
  ITEM
}


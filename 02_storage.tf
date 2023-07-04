# DynamoDB

resource "aws_dynamodb_table" "this" {
  name           = "${local.prefix}-candidates"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "CandidateName"

  attribute {
    name = "CandidateName"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  lifecycle {
    ignore_changes = [ttl] #it fails when it tries to set again timetoexist to false
  }

  tags = merge({
          Name = "${local.prefix}-candidates"
      }, var.tags)
}

resource "aws_dynamodb_table" "shorturl_lookup" {
  name           = "ShortURL"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Key"

  attribute {
    name = "Key"
    type = "S"
  }
//
//  attribute {
//    name = "URL"
//    type = "S"
//  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  tags = {
    Name        = "shorturl-table-1"
    Environment = "production"
  }

  lifecycle {
    ignore_changes = ["ttl"]
  }
}
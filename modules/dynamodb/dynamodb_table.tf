resource "aws_dynamodb_table" "this" {
  name                        = var.table_name
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "game_id"
  deletion_protection_enabled = var.deletion_protection

  attribute {
    name = "game_id"
    type = "S"
  }

  tags = {
    Name = var.table_name
  }
}

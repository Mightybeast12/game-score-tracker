terraform {
  backend "s3" {
    bucket               = "terraform-state-09fc6"
    key                  = "terraform.tfstate"
    region               = "eu-west-1"
    dynamodb_table       = "terraform-locks-09fc6"
    encrypt              = true
    workspace_key_prefix = "env"
  }
}

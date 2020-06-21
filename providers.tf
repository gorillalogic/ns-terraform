provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "gorilla-noise-alert-terraform-dev"

  allowed_account_ids = [
    var.aws_account_id
  ]
}

provider "archive" {}

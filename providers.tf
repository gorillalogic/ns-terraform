provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "gorilla-noise-alert-terraform-dev"

  allowed_account_ids = [
    "002631123367"
  ]
}

provider "archive" {}

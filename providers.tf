provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "leonardo"
  //profile                 = "gorilla"

  allowed_account_ids = [
    "961622453478", // leonardo cordero's account
    "002631123367"
  ]
}

provider "archive" {}

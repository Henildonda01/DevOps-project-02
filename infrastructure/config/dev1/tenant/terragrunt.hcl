locals {
  region = "us-east-1"
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket       = "tf-state-bucket-889900"
    key          = "dev1/tenant/terraform.tfstate"
    region       = local.region
    encrypt      = true
    use_lockfile = true
  }
}

terraform {
  source = "../../../module/tenant"
}

inputs = {
  region    = local.region
  env       = "dev1"
  key_name  = "chat-app"
}

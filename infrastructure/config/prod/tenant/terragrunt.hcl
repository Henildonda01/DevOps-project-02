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
    bucket       = "tf-state-bucket-889977"
    key          = "prod/tenant/terraform.tfstate"
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
  env       = "prod"
  key_name  = "chat-app"
  subnet_id = "subnet-04fafdc468370ae5b"
}

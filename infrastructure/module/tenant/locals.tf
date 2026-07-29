locals {
  name = "chat-app-${var.env}"
  common_tags = {
    Project     = "chat-app"
    Environment = var.env
  }
}

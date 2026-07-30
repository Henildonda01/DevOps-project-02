resource "tls_private_key" "chat_app" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "chat_app" {
  key_name   = var.key_name
  public_key = tls_private_key.chat_app.public_key_openssh

  tags = local.common_tags
}

resource "aws_security_group" "chat_app" {
  name        = "${local.name}-sg"
  description = "Security group for chat application"

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_http_cidr]
  }

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-sg"
  })
}

module "chat_app" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name = local.name

  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.chat_app.id]

  create_iam_instance_profile = false
  monitoring                  = false

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y docker.io docker-compose-v2
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu
  EOF

  tags = local.common_tags
}

resource "aws_eip" "chat_app" {
  domain   = "vpc"
  instance = module.chat_app.id

  tags = local.common_tags
}

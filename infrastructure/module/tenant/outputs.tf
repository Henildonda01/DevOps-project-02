output "instance_id" {
  description = "EC2 instance ID"
  value       = module.chat_app.id
}

output "public_ip" {
  description = "Elastic IP address of the EC2 instance"
  value       = aws_eip.chat_app.public_ip
}

output "eip_id" {
  description = "Elastic IP ID"
  value       = aws_eip.chat_app.id
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.chat_app.public_dns
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.chat_app.id
}

output "private_key" {
  description = "Private key for SSH access. Save this immediately!"
  value       = tls_private_key.chat_app.private_key_pem
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.chat_app.public_ip}"
}

output "app_url" {
  description = "URL to access the chat application"
  value       = "http://${aws_eip.chat_app.public_ip}"
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.chat_app.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.chat_app.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.chat_app.public_dns
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.chat_app.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.chat_app.public_ip}"
}

output "app_url" {
  description = "URL to access the chat application"
  value       = "http://${aws_instance.chat_app.public_ip}"
}

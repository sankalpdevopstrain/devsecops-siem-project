# ============================================================
# DevSecOps Platform — Outputs
# ============================================================

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.devsecops_ec2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.devsecops_ec2.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ~/.ssh/devsecops-key.pem ubuntu@${aws_instance.devsecops_ec2.public_ip}"
}

output "siem_dashboard" {
  description = "Your local SIEM dashboard"
  value       = "http://localhost:8081"
}

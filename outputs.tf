output "ec2_public_ip" {
  value       = aws_instance.dynatrace_ec2.public_ip
  description = "Public IP of the EC2 instance"
}

output "dynatrace_monitoring_role_arn" {
  value       = aws_iam_role.dynatrace_activegate_monitoring.arn
  description = "ARN of the Dynatrace monitoring IAM role (use in Dynatrace AWS connection)"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Copy this ARN and set it as GitHub secret AWS_ROLE_TO_ASSUME"
}

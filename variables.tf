variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default = "us-east-1"
}

variable "ec2_instance_type" {
  type        = string
  default     = "t3a.medium"  # Minimum for ActiveGate: 2 vCPU, 4GB RAM
  description = "EC2 instance type"
}

#variable "ec2_key_pair_name" {
#  type        = string
#  description = "Existing EC2 key pair name for SSH"
#  default     = "dyna"
#}

variable "dynatrace_env_url" {
  type        = string
  description = "Dynatrace environment URL (e.g., https://<env-id>.live.dynatrace.com)"
  default     = "https://hmn81417.live.dynatrace.com"
}

variable "dynatrace_oneagent_token" {
  type        = string
  sensitive   = true
  description = "Dynatrace PaaS token for OneAgent installation"
}

variable "dynatrace_activegate_token" {
  type        = string
  sensitive   = true
  description = "Dynatrace token for ActiveGate installation"
}

variable "dynatrace_monitoring_role_name" {
  type        = string
  default     = "DynatraceAWSMonitoringRole"
  description = "IAM role name for Dynatrace AWS monitoring"
}

variable "dynatrace_monitoring_policy_name" {
  type        = string
  default     = "DynatraceAWSMonitoringPolicy"
  description = "IAM policy name for Dynatrace AWS monitoring"
}

variable "github_repo_owner" {
  type        = string
  description = "GitHub repository owner (username or org)"
  default = "shubham-automation"
}

variable "github_repo_name" {
  type        = string
  description = "GitHub repository name"
  default = "dynatrace-tf"
}

variable "github_actions_role_name" {
  type        = string
  default     = "GitHubActionsTerraformRole"
  description = "IAM role name for GitHub Actions OIDC"
}

variable "create_github_oidc_provider" {
  type        = bool
  default     = true
  description = "Whether to create the GitHub Actions OIDC provider in this AWS account (usually only once)"
}

variable "github_oidc_thumbprint" {
  type        = string
  default     = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"  # Current GitHub thumbprint as of 2026
  description = "Thumbprint of token.actions.githubusercontent.com"
}

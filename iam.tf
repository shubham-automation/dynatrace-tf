# IAM Policy for Dynatrace AWS Monitoring
resource "aws_iam_policy" "dynatrace_aws_monitoring" {
  name        = var.dynatrace_monitoring_policy_name
  description = "Permissions for Dynatrace ActiveGate to monitor AWS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeReservedInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes",
          "iam:GetUser",
          "iam:ListAccountAliases",
          "iam:ListRoles",
          "organizations:DescribeAccount",
          "organizations:DescribeOrganization",
          "organizations:ListAccounts",
          "organizations:ListChildren",
          "organizations:ListOrganizationalUnitsForParent",
          "organizations:ListParents",
          "tag:GetResources",
          "tag:GetTagKeys",
          "tag:GetTagValues"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for Dynatrace Monitoring (assumable by EC2)
resource "aws_iam_role" "dynatrace_activegate_monitoring" {
  name = var.dynatrace_monitoring_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynatrace_monitoring_attach" {
  role       = aws_iam_role.dynatrace_activegate_monitoring.name
  policy_arn = aws_iam_policy.dynatrace_aws_monitoring.arn
}

resource "aws_iam_instance_profile" "dynatrace_activegate_profile" {
  name = "${var.dynatrace_monitoring_role_name}-profile"
  role = aws_iam_role.dynatrace_activegate_monitoring.name
}

# ────────────────────────────────────────────────────────────────────────────────
# GitHub Actions OIDC Provider (created only if create_github_oidc_provider = true)
# Usually created once per AWS account — safe to manage here if it's not already present
# ────────────────────────────────────────────────────────────────────────────────

resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.create_github_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.github_oidc_thumbprint]

  tags = {
    Name        = "GitHubActionsOIDCProvider"
    ManagedBy   = "Terraform"
    Environment = "ci-cd"
  }
}

# Use the ARN from the resource if created, otherwise fallback (but we expect it to be created)
locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github_actions[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# Optional: data source to get current account ID (used in local if needed)
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "github_actions" {
  name = var.github_actions_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Federated = local.github_oidc_provider_arn
        }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo_owner}/${var.github_repo_name}:*"
            # Optional: tighten further, e.g.:
            # "token.actions.githubusercontent.com:sub" = [
            #   "repo:${var.github_repo_owner}/${var.github_repo_name}:ref:refs/heads/main",
            #   "repo:${var.github_repo_owner}/${var.github_repo_name}:environment:production"
            # ]
          }
        }
      }
    ]
  })

  tags = {
    Name      = var.github_actions_role_name
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"  # Use least-privilege in prod (e.g., custom policy with EC2/IAM access)
}

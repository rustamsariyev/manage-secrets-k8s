# https://github.com/terraform-aws-modules/terraform-aws-iam/blob/master/modules/iam-assumable-role-with-oidc/outputs.tf
output "iam_role_name" {
  description = "Name of IAM role"
  value       = module.irsa.iam_role_name
}

output "iam_role_arn" {
  description = "ARN of IAM role"
  value       = module.irsa.iam_role_arn
}

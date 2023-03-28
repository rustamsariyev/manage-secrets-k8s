variable "chart_version" {
  description = "Vault Helm Chart version"
  type        = string
  default     = ""
}

variable "kms_region" {
  description = "AWS KMS region"
  type        = string
  default     = ""
}

variable "eks_cluster_id" {
  description = "EKS cluster name"
  type        = string
  default     = ""
}

variable "service_account_name" {
  description = "Service name usually reflected pod name and included to IAM Role name"
  type        = string
  default     = ""
}

variable "namespace" {
  description = "EKS cluster namespace"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to IAM role resources"
  type        = map(string)
  default     = {}
}

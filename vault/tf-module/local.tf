locals {
  tags = merge(var.tags, {
    TfModuleName = "manage-secrets-k8s/vault/tf-module"
  })
}
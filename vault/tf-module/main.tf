data "aws_eks_cluster" "this" {
  name = var.eks_cluster_id
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_id]
      command     = "aws"
    }
  }
}

data "aws_iam_policy_document" "vault" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [
      aws_kms_key.vault.arn
    ]
  }
}

resource "aws_iam_policy" "vault" {
  name   = "${var.eks_cluster_id}-vault-unseal-policy"
  policy = data.aws_iam_policy_document.vault.json
  tags   = local.tags
}

resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10
  tags                    = local.tags
}

module "irsa" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  create_role                   = true
  version                       = "~> 4"
  role_name                     = "${var.eks_cluster_id}-vault-unseal-role"
  provider_url                  = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.vault.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
  tags                          = local.tags
}

resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  depends_on = [
    helm_release.consul
  ]

  values = [
    <<EOT
global:
  enabled: true
server:
  serviceAccount:
    create: true
    name: vault-sa
    annotations:
      eks.amazonaws.com/role-arn: ${module.irsa.iam_role_arn}
  ha:
    enabled: true
    replicas: 3
    config: |
      ui = true

      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      service_registration "kubernetes" {}
      seal "awskms" {
        region     = "${var.kms_region}"
        kms_key_id = "${aws_kms_key.vault.id}"
      }
      
      storage "consul" {
        path = "vault"
        address = "consul-consul-server.consul.svc.cluster.local:8500"
      }
  service:
    enabled: true

  dataStorage:
    enabled: true
    size: 10Gi
    storageClass: null
    accessMode: ReadWriteOnce

  ui:
    enabled: true
EOT
  ]
}

resource "helm_release" "consul" {
  name             = "consul"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "consul"
  version          = "1.1.0"
  namespace        = "consul"
  create_namespace = true
}

# IRSA role for the CloudWatch Exporter (SA: monitoring/cloudwatch-exporter)
module "cloudwatch_exporter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.59.0"

  role_name = "${var.cluster_name}-cloudwatch-exporter"

  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["monitoring:cloudwatch-exporter"]
    }
  }
}

# Minimal permissions: read CloudWatch metrics
data "aws_iam_policy_document" "cwe_policy" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cwe" {
  name   = "${var.cluster_name}-cloudwatch-exporter"
  policy = data.aws_iam_policy_document.cwe_policy.json
}

resource "aws_iam_role_policy_attachment" "cwe_attach" {
  role       = module.cloudwatch_exporter_irsa.iam_role_name
  policy_arn = aws_iam_policy.cwe.arn
}

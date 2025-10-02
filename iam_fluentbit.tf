data "aws_iam_policy_document" "fluentbit_cw" {
  statement {
    actions = [
      "logs:CreateLogGroup", "logs:CreateLogStream", "logs:DescribeLogStreams",
      "logs:PutLogEvents", "logs:PutRetentionPolicy"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "fluentbit_cw" {
  name   = "${var.cluster_name}-fluentbit-cloudwatch"
  policy = data.aws_iam_policy_document.fluentbit_cw.json
}

module "fluentbit_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.59.0"

  role_name = "${var.cluster_name}-fluent-bit"
  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:fluent-bit"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "fluentbit_attach" {
  role       = module.fluentbit_irsa.iam_role_name
  policy_arn = aws_iam_policy.fluentbit_cw.arn
}

output "fluentbit_irsa_role_arn" {
  value = module.fluentbit_irsa.iam_role_arn
}

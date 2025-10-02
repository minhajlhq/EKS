# --- GitHub OIDC provider (one per AWS account) ---
# Get the SHA-1 thumbprint for token.actions.githubusercontent.com and paste below.
# See: openssl command at the bottom of this snippet.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["7560d6f40fa55195f740ee2b1b7c0b4836cbe103"]
}

# --- Trust policy: allow ONLY your repo's main branch to assume the role ---
data "aws_iam_policy_document" "gha_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # Lock to your repo + branch
      values = ["repo:minhajlhq/EKS:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "gha_ecr" {
  name               = "${var.cluster_name}-gha-ecr"
  assume_role_policy = data.aws_iam_policy_document.gha_trust.json
}

# --- Least-privilege: push to your specific ECR repo ---
data "aws_iam_policy_document" "gha_ecr_policy" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [aws_ecr_repository.app.arn]
  }
}

resource "aws_iam_policy" "gha_ecr" {
  name   = "${var.cluster_name}-gha-ecr-policy"
  policy = data.aws_iam_policy_document.gha_ecr_policy.json
}

resource "aws_iam_role_policy_attachment" "gha_attach" {
  role       = aws_iam_role.gha_ecr.name
  policy_arn = aws_iam_policy.gha_ecr.arn
}

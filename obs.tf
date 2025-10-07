resource "kubernetes_namespace" "monitoring" {
  metadata { name = "monitoring" }
}

# kube-prometheus-stack
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "62.7.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [yamlencode({
    grafana = {
      adminPassword            = "admin123"
      defaultDashboardsEnabled = true
      service                  = { type = "ClusterIP" }
      additionalDataSources = [
        {
          name      = "Tempo"
          type      = "tempo"
          access    = "proxy"
          url       = "http://tempo.monitoring:3100"
          isDefault = false
        }
      ]
    }
    prometheus = {
      service = { type = "ClusterIP" }
      prometheusSpec = {
        retention     = "7d"
        retentionSize = "10GiB"
        resources     = { requests = { cpu = "250m", memory = "1Gi" } }
      }
    }
    alertmanager = { service = { type = "ClusterIP" } }
  })]
}


# aws-for-fluent-bit (IRSA -> CloudWatch Logs)
resource "helm_release" "aws_for_fluent_bit" {
  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = "0.1.32"
  namespace  = "kube-system"

  values = [yamlencode({
    serviceAccount = {
      create = true
      name   = "fluent-bit"
      annotations = {
        "eks.amazonaws.com/role-arn" = module.fluentbit_irsa.iam_role_arn
      }
    }
    cloudWatch = {
      enabled          = true
      region           = var.region
      logGroupName     = "/eks/${var.cluster_name}/applications"
      autoCreateGroup  = true
      logRetentionDays = 7
    }
  })]
}

# prometheus-cloudwatch-exporter (scrapes ALB metrics into Prometheus)
resource "helm_release" "cloudwatch_exporter" {
  name       = "cloudwatch-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-cloudwatch-exporter"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [yamlencode({
    serviceAccount = {
      create = true
      name   = "cloudwatch-exporter"
      annotations = {
        "eks.amazonaws.com/role-arn" = module.cloudwatch_exporter_irsa.iam_role_arn
      }
    }

    serviceMonitor = {
  enabled  = true
  interval = "60s"
  labels = {
    release = helm_release.kube_prometheus_stack.name
  }
}

    # IMPORTANT: pass config as a STRING, not a map
    config = <<-YAML
    region: us-east-1
    period_seconds: 60
    range_seconds: 600
    delay_seconds: 120
    metrics:
      - aws_namespace: AWS/ApplicationELB
        aws_dimension_select:
          LoadBalancer: []
        aws_metric_name: RequestCount
        aws_statistics: [ Sum ]

      - aws_namespace: AWS/ApplicationELB
        aws_dimension_select:
          LoadBalancer: []
        aws_metric_name: TargetResponseTime
        aws_statistics: [ Average, p90, p99 ]

      - aws_namespace: AWS/ApplicationELB
        aws_dimension_select:
          LoadBalancer: []
        aws_metric_name: HTTPCode_Target_5XX_Count
        aws_statistics: [ Sum ]
  YAML
  })]

  depends_on = [
    helm_release.kube_prometheus_stack,
    aws_iam_role_policy_attachment.cwe_attach
  ]
}

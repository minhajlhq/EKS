resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6" # Keep it pinned to stable

  values = [yamlencode({
    server = {
      extraArgs = ["--insecure"]
      service = {
        type              = "ClusterIP"
        servicePortHttp   = 80
        servicePortHttps  = 443
      }
    }
  })]
}

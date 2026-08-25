resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.3.3"
  namespace        = "argocd"
  create_namespace = true

  depends_on = [module.eks]

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
        extraArgs = ["--insecure"]

        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }

      controller = {
        resources = {
          requests = {
            cpu    = "250m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "1000m"
            memory = "1024Mi"
          }
        }
      }

      repoServer = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "256Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
    })
  ]
}

resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.5"
  namespace  = "argocd"

  depends_on = [helm_release.argocd]

  values = [
    yamlencode({
      applications = {
        root-app = {
          namespace = "argocd"
          project   = "default"
          source = {
            repoURL        = "https://github.com/tjrohweder/lab.git"
            targetRevision = "HEAD"
            path           = "kubernetes/apps"
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "argocd"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
          }
        }
      }
    })
  ]
}

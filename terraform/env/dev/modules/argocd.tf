resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.3.3"
  namespace        = "argocd"
  upgrade_install  = true
  create_namespace = true

  depends_on = [module.eks]

  values = [
    local_file.argocd_values.content
  ]
}

resource "helm_release" "argocd_apps" {
  name            = "argocd-apps"
  repository      = "https://argoproj.github.io/argo-helm"
  chart           = "argocd-apps"
  version         = "2.0.5"
  namespace       = "argocd"
  upgrade_install = true

  depends_on = [helm_release.argocd]

  values = [
    file("${path.module}/argocd/argocd-apps-values.yaml")
  ]
}

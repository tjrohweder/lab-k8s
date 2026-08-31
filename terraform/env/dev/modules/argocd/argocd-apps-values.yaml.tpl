applications:
  root-app:
    namespace: argocd
    project: default
    source:
      repoURL: https://github.com/${github_user}/lab-k8s.git
      targetRevision: HEAD
      path: kubernetes/apps
    destination:
      server: https://kubernetes.default.svc
      namespace: argocd
    syncPolicy:
      automated:
        prune: true
        selfHeal: true

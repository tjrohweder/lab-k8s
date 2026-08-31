settings:
  clusterName: "${cluster_name}"

serviceAccount:
  create: true
  name: karpenter
  annotations:
    eks.amazonaws.com/role-arn: "${karpenter_iam_role_arn}"

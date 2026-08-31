apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: rds-secret-provider
  namespace: dagster
spec:
  provider: aws
  secretObjects:
    - secretName: dagster-postgresql-secret
      type: Opaque
      data:
        - objectName: postgresql-password
          key: postgresql-password
  parameters:
    objects: |
      - objectName: "${rds_secret_arn}"
        objectType: "secretsmanager"
        jmesPath:
            - path: "password"
              objectAlias: "postgresql-password"

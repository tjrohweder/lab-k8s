global:
  postgresqlSecretName: "dagster-postgresql-secret"

generatePostgresqlPasswordSecret: false

serviceAccount:
  create: true
  name: "dagster"
  annotations:
    eks.amazonaws.com/role-arn: "${dagster_iam_role_arn}"

ingress:
  enabled: true
  ingressClassName: "alb"
  annotations:
    alb.ingress.kubernetes.io/group.name: "lab-public-alb"
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: "${acm_certificate_arn}"
    alb.ingress.kubernetes.io/auth-type: cognito
    alb.ingress.kubernetes.io/auth-session-timeout: '3600'
    alb.ingress.kubernetes.io/auth-session-cookie: 'AWSELBAuthSessionCookie'
    alb.ingress.kubernetes.io/auth-on-unauthenticated-request: authenticate
    alb.ingress.kubernetes.io/auth-idp-cognito: '{"UserPoolArn":"${cognito_user_pool_arn}","UserPoolClientId":"${cognito_client_id}","UserPoolDomain":"${cognito_domain}"}'

  dagsterWebserver:
    host: "${domain_name}"
    path: "/"
    pathType: Prefix

postgresql:
  enabled: false
  postgresqlHost: "${rds_endpoint}"
  postgresqlUsername: "db_admin"
  postgresqlDatabase: "main"
  postgresqlPort: 5432
  postgresqlPasswordSecret: "dagster-postgresql-secret"

computeLogManager:
  type: S3ComputeLogManager
  config:
    s3ComputeLogManager:
      bucket: "${s3_bucket_name}"
      prefix: "logs/"

dagsterWebserver:
  podSecurityContext:
    fsGroup: 1000
  env:
    - name: DAGSTER_S3_BUCKET
      value: "${s3_bucket_name}"
    - name: AWS_REGION
      value: "${aws_region}"
    - name: AWS_DEFAULT_REGION
      value: "${aws_region}"
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "rds-secret-provider"
  volumeMounts:
    - name: secrets-store-inline
      mountPath: "/mnt/secrets-store"
      readOnly: true

dagsterDaemon:
  enabled: true
  podSecurityContext:
    fsGroup: 1000
  runCoordinator:
    enabled: true
    type: QueuedRunCoordinator
    config:
      queuedRunCoordinator:
        maxConcurrentRuns: 10
  env:
    - name: DAGSTER_S3_BUCKET
      value: "${s3_bucket_name}"
    - name: AWS_REGION
      value: "${aws_region}"
    - name: AWS_DEFAULT_REGION
      value: "${aws_region}"
    - name: SNS_ALERTS_TOPIC_ARN
      value: "${sns_topic_arn}"
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "rds-secret-provider"
  volumeMounts:
    - name: secrets-store-inline
      mountPath: "/mnt/secrets-store"
      readOnly: true

runLauncher:
  type: K8sRunLauncher
  config:
    k8sRunLauncher:
      envVars:
        - "DAGSTER_S3_BUCKET=${s3_bucket_name}"
        - "AWS_REGION=${aws_region}"
        - "AWS_DEFAULT_REGION=${aws_region}"
      runK8sConfig:
        podSpecConfig:
          serviceAccountName: "dagster"
          securityContext:
            fsGroup: 1000
          nodeSelector:
            karpenter.k8s.aws/instance-cpu-manufacturer: amd
          tolerations:
            - key: workload
              operator: Equal
              value: dagster
              effect: NoSchedule
          initContainers:
            - name: wait-for-dns
              image: debian:bullseye-slim
              command:
                - 'sh'
                - '-c'
                - 'apt-get update && apt-get install -y dnsutils && until nslookup ${rds_endpoint}; do echo "Waiting for connectivity"; sleep 2; done'

dagster-user-deployments:
  enabled: true
  serviceAccount:
    create: false
    name: "dagster"
  deployments:
    - name: "dummy-pipeline"
      serviceAccountName: "dagster"
      podSecurityContext:
        fsGroup: 1000
      image:
        repository: "${ecr_repository_url}"
        tag: "latest"
        pullPolicy: Always
      dagsterApiGrpcArgs:
        - "--python-file"
        - "/opt/dagster/app/repo.py"
      port: 3030
      env:
        - name: AWS_REGION
          value: "${aws_region}"
        - name: AWS_DEFAULT_REGION
          value: "${aws_region}"
        - name: SNS_ALERTS_TOPIC_ARN
          value: "${sns_topic_arn}"

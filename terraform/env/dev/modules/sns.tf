resource "aws_sns_topic" "dagster_alerts" {
  name              = "dagster-alerts-${var.project.name}"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "dagster_email_alert" {
  topic_arn = aws_sns_topic.dagster_alerts.arn
  protocol  = var.sns.protocol
  endpoint  = var.sns.endpoint
}

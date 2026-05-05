# =============================================================================
# Outputs
# =============================================================================

output "datasync_hub_role_arn" {
  description = "ARN of the DataSync service role in the hub account."
  value       = aws_iam_role.datasync_hub.arn
}

output "source_location_arn" {
  description = "ARN of the DataSync source location (hub S3 bucket)."
  value       = aws_datasync_location_s3.source.arn
}

output "task_arns" {
  description = "Map of spoke name to DataSync task ARN."
  value       = { for k, v in aws_datasync_task.spoke : k => v.arn }
}

output "destination_location_arns" {
  description = "Map of spoke name to DataSync destination location ARN."
  value       = { for k, v in aws_datasync_location_s3.destination : k => v.arn }
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for DataSync failure notifications."
  value       = aws_sns_topic.datasync_failures.arn
}

output "sns_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the SNS topic."
  value       = aws_kms_key.sns.arn
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard."
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.datasync.dashboard_name}"
}

output "spoke_bucket_policies" {
  description = "JSON bucket policies to apply to each spoke's destination bucket."
  value       = { for k, v in data.aws_iam_policy_document.spoke_bucket_policy : k => v.json }
}

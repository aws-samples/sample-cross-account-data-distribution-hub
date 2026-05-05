# =============================================================================
# Spoke Bucket Policies
#
# These policies must be applied to each spoke's destination S3 bucket to
# grant the hub account's DataSync role write access.
#
# IMPORTANT: This file generates the policy documents. Applying them to the
# spoke buckets requires either:
#   (a) A provider alias per spoke with assume_role (shown in spoke_providers.tf.example)
#   (b) Manual application via the AWS console or CLI in each spoke account
#   (c) A separate Terraform workspace per spoke account
#
# The policies below are output as JSON for reference and can be applied
# using the approach that best fits your organization.
# =============================================================================

# Generate the bucket policy document for each spoke
data "aws_iam_policy_document" "spoke_bucket_policy" {
  for_each = var.spokes

  # Allow the hub DataSync role to write to the destination bucket
  statement {
    sid    = "AllowDataSyncHubWrite"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.datasync_hub.arn]
    }

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [each.value.bucket_arn]
  }

  statement {
    sid    = "AllowDataSyncHubObjectWrite"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.datasync_hub.arn]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    resources = ["${each.value.bucket_arn}/*"]
  }
}

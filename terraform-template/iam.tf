# =============================================================================
# IAM — Hub-side DataSync service role
# =============================================================================

# This role is assumed by the DataSync service in the hub account.
# It needs read access to the source bucket and write access to each
# spoke destination bucket (granted via the spoke bucket policies).

resource "aws_iam_role" "datasync_hub" {
  name = "${var.project_name}-datasync-hub-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.hub.account_id
          }
        }
      }
    ]
  })

  tags = {
    Component = "iam"
  }
}

# Read access to the source bucket
resource "aws_iam_role_policy" "datasync_source_access" {
  name = "${var.project_name}-source-bucket-access"
  role = aws_iam_role.datasync_hub.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = var.source_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "${var.source_bucket_arn}/*"
      }
    ]
  })
}

# Write access to each spoke destination bucket
resource "aws_iam_role_policy" "datasync_destination_access" {
  for_each = var.spokes

  name = "${var.project_name}-dest-${each.key}"
  role = aws_iam_role.datasync_hub.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = each.value.bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:GetObject",
          "s3:GetObjectTagging"
        ]
        Resource = "${each.value.bucket_arn}/*"
      }
    ]
  })
}

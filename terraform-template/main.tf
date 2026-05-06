# =============================================================================
# Automated Cross-Account Data Distribution Hub
# AWS DataSync Enhanced Mode — Hub Account Resources
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "my-hub-terraform-state"
  #   key            = "datasync-hub/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# -----------------------------------------------------------------------------
# Hub account provider (default)
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.hub_region

  default_tags {
    tags = var.default_tags
  }
}

# -----------------------------------------------------------------------------
# Data sources
# -----------------------------------------------------------------------------
data "aws_caller_identity" "hub" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# KMS key for SNS topic encryption
# -----------------------------------------------------------------------------
resource "aws_kms_key" "sns" {
  description             = "KMS key for encrypting DataSync failure notifications SNS topic"
  deletion_window_in_days = 14
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowRootAccountFullAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.hub.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowEventBridgeToPublishEncrypted"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Component = "alerting"
  }
}

resource "aws_kms_alias" "sns" {
  name          = "alias/${var.project_name}-sns"
  target_key_id = aws_kms_key.sns.key_id
}

# -----------------------------------------------------------------------------
# SNS Topic for failure notifications
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "datasync_failures" {
  name              = "${var.project_name}-datasync-failures"
  kms_master_key_id = aws_kms_key.sns.arn

  tags = {
    Component = "alerting"
  }
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.alert_email_addresses)

  topic_arn = aws_sns_topic.datasync_failures.arn
  protocol  = "email"
  endpoint  = each.value
}

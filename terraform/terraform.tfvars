# =============================================================================
# Automated Cross-Account Data Distribution Hub — Live Configuration
# =============================================================================

project_name = "data-distribution-hub"
hub_region   = "us-east-1"

source_bucket_arn          = "arn:aws:s3:::my-central-data-lake"
source_bucket_subdirectory = "/"

alert_email_addresses = []

default_tags = {
  ManagedBy   = "terraform"
  Project     = "data-distribution-hub"
  Environment = "demo"
}

# -----------------------------------------------------------------------------
# Spoke configurations
# -----------------------------------------------------------------------------
spokes = {
  dev = {
    account_id = "521223133677"
    bucket_arn = "arn:aws:s3:::data-distribution-dev-521223133677"
    role_arn   = "arn:aws:iam::521223133677:role/TerraformProvisioningRole"
    schedule   = "cron(0 */6 * * ? *)"
  }
}

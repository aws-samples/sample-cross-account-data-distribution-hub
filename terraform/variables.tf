# =============================================================================
# Variables
# =============================================================================

variable "project_name" {
  description = "Name prefix for all resources created by this module."
  type        = string
  default     = "data-distribution-hub"
}

variable "hub_region" {
  description = "AWS Region for the hub account resources."
  type        = string
  default     = "us-east-1"
}

variable "source_bucket_arn" {
  description = "ARN of the source S3 bucket in the hub account."
  type        = string
}

variable "source_bucket_subdirectory" {
  description = "Subdirectory (prefix) in the source bucket to use as the root for transfers. Must start and end with '/'."
  type        = string
  default     = "/"
}

variable "alert_email_addresses" {
  description = "List of email addresses to receive SNS notifications on DataSync task failures."
  type        = list(string)
  default     = []
}

variable "default_tags" {
  description = "Default tags applied to all resources."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "data-distribution-hub"
  }
}

# -----------------------------------------------------------------------------
# Spoke configurations
# -----------------------------------------------------------------------------
variable "spokes" {
  description = <<-EOT
    Map of spoke account configurations. Each key is a logical name for the spoke.

    Required attributes:
      - account_id:  AWS account ID of the spoke
      - bucket_arn:  ARN of the destination S3 bucket in the spoke account
      - role_arn:    ARN of the Terraform provisioning role in the spoke account
                     (used by the spoke provider to create IAM resources)

    Optional attributes:
      - schedule:          Cron expression for task scheduling (default: every 6 hours)
      - bandwidth_limit:   Bytes per second limit (-1 = unlimited, default: -1)
      - include_patterns:  Pipe-delimited include filter (e.g., "/datasets/*")
      - exclude_patterns:  Pipe-delimited exclude filter (e.g., "/tmp/*|/logs/*")
      - subdirectory:      Destination bucket subdirectory (default: "/")
      - storage_class:     S3 storage class for destination (default: "STANDARD")
  EOT

  type = map(object({
    account_id       = string
    bucket_arn       = string
    role_arn         = string
    schedule         = optional(string, "cron(0 */6 * * ? *)")
    bandwidth_limit  = optional(number, -1)
    include_patterns = optional(string, null)
    exclude_patterns = optional(string, null)
    subdirectory     = optional(string, "/")
    storage_class    = optional(string, "STANDARD")
  }))
}

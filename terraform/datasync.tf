# =============================================================================
# DataSync — Source location, destination locations, and tasks
# =============================================================================

# Source location (shared across all spoke tasks)
resource "aws_datasync_location_s3" "source" {
  s3_bucket_arn = var.source_bucket_arn
  subdirectory  = var.source_bucket_subdirectory

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_hub.arn
  }

  tags = {
    Component = "datasync"
    Role      = "source"
  }
}

# Destination location — one per spoke
resource "aws_datasync_location_s3" "destination" {
  for_each = var.spokes

  s3_bucket_arn    = each.value.bucket_arn
  subdirectory     = each.value.subdirectory
  s3_storage_class = each.value.storage_class

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_hub.arn
  }

  tags = {
    Component    = "datasync"
    Role         = "destination"
    SpokeAccount = each.value.account_id
    SpokeName    = each.key
  }
}

# DataSync task — one per spoke, Enhanced mode
resource "aws_datasync_task" "spoke" {
  for_each = var.spokes

  name                     = "${var.project_name}-to-${each.key}"
  source_location_arn      = aws_datasync_location_s3.source.arn
  destination_location_arn = aws_datasync_location_s3.destination[each.key].arn
  task_mode                = "ENHANCED"

  options {
    verify_mode       = "ONLY_FILES_TRANSFERRED"
    overwrite_mode    = "ALWAYS"
    transfer_mode     = "CHANGED"
    bytes_per_second  = each.value.bandwidth_limit
    gid               = "NONE"
    uid               = "NONE"
    posix_permissions = "NONE"
    object_tags       = "PRESERVE"
  }

  schedule {
    schedule_expression = each.value.schedule
  }

  # Include filters (optional)
  dynamic "includes" {
    for_each = each.value.include_patterns != null ? [each.value.include_patterns] : []
    content {
      filter_type = "SIMPLE_PATTERN"
      value       = includes.value
    }
  }

  # Exclude filters (optional)
  dynamic "excludes" {
    for_each = each.value.exclude_patterns != null ? [each.value.exclude_patterns] : []
    content {
      filter_type = "SIMPLE_PATTERN"
      value       = excludes.value
    }
  }

  tags = {
    Component    = "datasync"
    SpokeAccount = each.value.account_id
    SpokeName    = each.key
  }
}

# =============================================================================
# CloudWatch — Alarms and Dashboard
# =============================================================================

# CloudWatch Event Rule to detect DataSync task failures and send to SNS
resource "aws_cloudwatch_event_rule" "datasync_failure" {
  name        = "${var.project_name}-datasync-task-failure"
  description = "Captures DataSync task execution failures across all spoke tasks"

  event_pattern = jsonencode({
    source      = ["aws.datasync"]
    detail-type = ["DataSync Task Execution State Change"]
    detail = {
      State = ["ERROR"]
    }
  })

  tags = {
    Component = "monitoring"
  }
}

resource "aws_cloudwatch_event_target" "datasync_failure_sns" {
  rule      = aws_cloudwatch_event_rule.datasync_failure.name
  target_id = "send-to-sns"
  arn       = aws_sns_topic.datasync_failures.arn
}

# Allow EventBridge to publish to the SNS topic
resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn = aws_sns_topic.datasync_failures.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEventBridgePublish"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.datasync_failures.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.datasync_failure.arn
          }
        }
      }
    ]
  })
}

# CloudWatch Dashboard — single pane of glass for all spoke transfers
resource "aws_cloudwatch_dashboard" "datasync" {
  dashboard_name = "${var.project_name}-datasync-overview"

  dashboard_body = jsonencode({
    widgets = concat(
      # Header widget
      [
        {
          type   = "text"
          x      = 0
          y      = 0
          width  = 24
          height = 1
          properties = {
            markdown = "# DataSync Cross-Account Distribution Hub\nMonitoring dashboard for all spoke transfer tasks."
          }
        }
      ],
      # Per-spoke task status widgets
      [
        for idx, spoke_key in keys(var.spokes) : {
          type   = "metric"
          x      = (idx % 3) * 8
          y      = 1 + floor(idx / 3) * 6
          width  = 8
          height = 6
          properties = {
            title   = "Spoke: ${spoke_key} (${var.spokes[spoke_key].account_id})"
            region  = data.aws_region.current.name
            view    = "timeSeries"
            stacked = false
            metrics = [
              ["AWS/DataSync", "BytesTransferred", "TaskId", split("/", aws_datasync_task.spoke[spoke_key].arn)[1]],
              ["AWS/DataSync", "FilesTransferred", "TaskId", split("/", aws_datasync_task.spoke[spoke_key].arn)[1]]
            ]
            period = 3600
            stat   = "Sum"
          }
        }
      ]
    )
  })
}

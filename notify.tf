resource "aws_sns_topic" "aws_nuke_notify" {
  content_based_deduplication = false
  display_name                = "${var.project_name}-teste"
  fifo_topic                  = false
  name                        = "${var.project_name}-teste"
}

resource "aws_sns_topic_subscription" "users_notified" {
  for_each  = toset(var.emails_notification)
  topic_arn = aws_sns_topic.aws_nuke_notify.arn
  protocol  = "email"
  endpoint  = each.key
}


resource "aws_iam_policy" "sns_policy_rule" {
  name        = "sns_policy"
  description = "SNS policy"
  policy = templatefile("files/templates/aws_iam_policy.sns_policy_rule.policy.json.tftpl",
    {
      resource_arn = aws_sns_topic.aws_nuke_notify.arn
  })
}

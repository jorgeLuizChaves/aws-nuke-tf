resource "aws_sns_topic" "aws_nuke_notify" {
  content_based_deduplication = false
  display_name                = "${var.project_name}-teste"
  fifo_topic                  = false
  name                        = "${var.project_name}-teste"
}



resource "aws_iam_policy" "sns_policy_rule" {
  name        = "sns_policy"
  description = "SNS policy"
  policy      = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "SNS:GetTopicAttributes",
        "SNS:SetTopicAttributes",
        "SNS:AddPermission",
        "SNS:RemovePermission",
        "SNS:DeleteTopic",
        "SNS:Subscribe",
        "SNS:ListSubscriptionsByTopic",
        "SNS:Publish"
      ],
      "Effect": "Allow",
      "Resource": "${aws_sns_topic.aws_nuke_notify.arn}"
    }
  ]
}
EOT
}

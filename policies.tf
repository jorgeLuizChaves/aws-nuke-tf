
resource "aws_iam_policy" "nuke_account_cleanser" {
  description = "Managed policy for nuke account cleansing"
  name        = "NukeAccountCleanser"
  path        = "/"
  policy      = file("files/templates/nuke_account_cleanser_policy.json")
  tags        = {}
  tags_all    = {}
}

resource "aws_iam_policy" "sns_publish_policy" {
  name = "SNSPublishPolicy"
  policy = templatefile("templates/aws_iam_policy_sns_publish_policy.json.tftpl", {
    resource_arn = aws_sns_topic.aws_nuke_notify.arn
    }
  )
}

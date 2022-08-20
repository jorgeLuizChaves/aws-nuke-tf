
resource "aws_iam_policy" "nuke_account_cleanser" {
  description = "Managed policy for nuke account cleansing"
  name        = "NukeAccountCleanser"
  path        = "/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "access-analyzer:*",
            "autoscaling:*",
            "aws-portal:*",
            "budgets:*",
            "cloudtrail:*",
            "cloudwatch:*",
            "config:*",
            "ec2:*",
            "ec2messages:*",
            "elasticloadbalancing:*",
            "eks:*",
            "elasticache:*",
            "events:*",
            "firehose:*",
            "guardduty:*",
            "iam:*",
            "inspector:*",
            "kinesis:*",
            "kms:*",
            "lambda:*",
            "logs:*",
            "organizations:*",
            "pricing:*",
            "s3:*",
            "secretsmanager:*",
            "securityhub:*",
            "sns:*",
            "sqs:*",
            "ssm:*",
            "ssmmessages:*",
            "sts:*",
            "support:*",
            "tag:*",
            "trustedadvisor:*",
            "waf-regional:*",
            "wafv2:*",
            "cloudformation:*",
          ]
          Effect   = "Allow"
          Resource = "*"
          Sid      = "WhitelistedServices"
        },
      ]
      Version = "2012-10-17"
    }
  )
  #   policy_id = "ANPA4ZOGVR7BBCU4GZYQI"
  tags     = {}
  tags_all = {}
}

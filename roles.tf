data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role_policy" "assume_nuke_policy" {
  name   = "AssumeNukePolicy"
  role   = aws_iam_role.nuke_code_build_project_role.id
  policy = templatefile("files/templates/aws_iam_role_policy.assume_nuke_policy.policy.json.tftpl", { resource_arn = aws_iam_role.nuke_auto_account_cleanser.arn })
}

resource "aws_iam_role_policy" "nuke_code_build_logs_policy" {
  name = "NukeCodeBuildLogsPolicy"
  role = aws_iam_role.nuke_code_build_project_role.id

  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
            "logs:FilterLogEvents",
          ]
          Effect = "Allow"
          Resource = [
            # maybe use data
            "arn:aws:logs:${var.region}:${local.account_id}:log-group:${var.project_name}",
            "arn:aws:logs:${var.region}:${local.account_id}:log-group:${var.project_name}:*",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy" "nuke_list_ou_accounts" {
  name = "NukeListOUAccounts"
  role = aws_iam_role.nuke_code_build_project_role.id

  policy = jsonencode(
    {
      Statement = [
        {
          Action   = "organizations:ListAccountsForParent"
          Effect   = "Allow"
          Resource = "*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy" "s3_bucket_read_only" {
  name = "S3BucketReadOnly"
  role = aws_iam_role.nuke_code_build_project_role.id

  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "s3:Get*",
            "s3:List*",
          ]
          Effect = "Allow"
          Resource = [

            "${aws_s3_bucket.aws_nuke_config.arn}",
            "${aws_s3_bucket.aws_nuke_config.arn}/*",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_policy" "sns_publish_policy" {
  name = "SNSPublishPolicy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "sns:ListTagsForResource",
            "sns:ListSubscriptionsByTopic",
            "sns:GetTopicAttributes",
            "sns:Publish",
          ],
          "Effect" : "Allow",
          "Resource" : "${aws_sns_topic.aws_nuke_notify.arn}"
        }
      ]
    }
  )
}

resource "aws_iam_role" "nuke_code_build_project_role" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "codebuild.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  name = "NukeCodeBuildProjectRole"
  path = "/"
}

# EventBridgeNukeSchedule-abcjorge2022
# aws_iam_role.event_bridge_nuke_schedule2:

resource "aws_iam_role_policy" "event_bridge_nuke_state_machine_execution_policy" {
  name = "EventBridgeNukeStateMachineExecutionPolicy"
  role = aws_iam_role.event_bridge_nuke_schedule.id
  policy = jsonencode(
    {
      Statement = [
        {
          Action = "states:StartExecution"
          Effect = "Allow"
          # Resource = aws_sfn_state_machine.nuke_account_cleanser_codebuild_state_machine.arn
          Resource = "arn:aws:states:${var.region}:${local.account_id}:stateMachine:nuke-account-cleanser-codebuild-state-machine"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role" "event_bridge_nuke_schedule" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "events.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  managed_policy_arns   = []
  max_session_duration  = 3600
  name                  = "EventBridgeNukeSchedule"
  path                  = "/"
  tags                  = {}
  tags_all              = {}
}

resource "aws_iam_role_policy" "nuke_account_cleanser_codebuild_state_machine_policy" {
  name = "nuke-account-cleanser-codebuild-state-machine-policy"
  role = aws_iam_role.nuke_account_cleanser_codebuild_state_machine_role.id
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "codebuild:StartBuild",
            "codebuild:StartBuild",
            "codebuild:StopBuild",
            "codebuild:StartBuildBatch",
            "codebuild:StopBuildBatch",
            "codebuild:RetryBuild",
            "codebuild:RetryBuildBatch",
            "codebuild:BatchGet*",
            "codebuild:GetResourcePolicy",
            "codebuild:DescribeTestCases",
            "codebuild:DescribeCodeCoverages",
            "codebuild:List*",
          ]
          Effect = "Allow"
          Resource = [
            aws_codebuild_project.aws_nuke_cleanser.arn
          ]
        },
        {
          Action = [
            "events:PutTargets",
            "events:PutRule",
            "events:DescribeRule",
          ]
          Effect = "Allow"
          # Resource = aws_cloudwatch_event_rule.event_bridge_nuke_schedule.arn
          Resource = "arn:aws:events:${var.region}:${local.account_id}:rule/StepFunctionsGetEventForCodeBuildStartBuildRule"
        },
        {
          Action = [
            "sns:Publish",
          ]
          Effect = "Allow"
          Resource = [
            aws_sns_topic.aws_nuke_notify.arn
          ]
        },
        {
          Action = [
            "states:DescribeStateMachine",
            "states:ListExecutions",
            "states:StartExecution",
            "states:StopExecution",
            "states:DescribeExecution",
          ]
          Effect = "Allow"
          Resource = [
            # aws_sfn_state_machine.nuke_account_cleanser_codebuild_state_machine.arn
            "arn:aws:states:${var.region}:${local.account_id}:stateMachine:nuke-account-cleanser-codebuild-state-machine",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role" "nuke_account_cleanser_codebuild_state_machine_role" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "states.us-west-2.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  managed_policy_arns   = []
  max_session_duration  = 3600
  name                  = "nuke-account-cleanser-codebuild-state-machine-role"
  path                  = "/"
  tags                  = {}
  tags_all              = {}
}

# aws_iam_role.nuke_auto_account_cleanser:
# 
resource "aws_iam_role" "nuke_auto_account_cleanser" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            AWS = aws_iam_role.nuke_code_build_project_role.arn
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  description           = "Nuke Auto account cleanser role for Dev/Sandbox accounts"
  force_detach_policies = false
  max_session_duration  = 7200
  name                  = "nuke-auto-account-cleanser"
  path                  = "/"
  tags = {
    "description" = "PrivilegedReadWrite:auto-account-cleanser-role"
    "owner"       = "OpsAdmin"
    "privileged"  = "true"
  }
  tags_all = {
    "description" = "PrivilegedReadWrite:auto-account-cleanser-role"
    "owner"       = "OpsAdmin"
    "privileged"  = "true"
  }
}

resource "aws_iam_policy_attachment" "nuke_auto_account_cleanser" {
  name       = "nuke-auto-account-cleanser-attachment"
  roles      = [aws_iam_role.nuke_auto_account_cleanser.name]
  policy_arn = aws_iam_policy.nuke_account_cleanser.arn
}

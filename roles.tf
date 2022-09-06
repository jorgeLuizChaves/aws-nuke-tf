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

  policy = templatefile("templates/NukeCodeBuildLogsPolicy.json.tftpl",
    {
      region       = var.region,
      account_id   = local.account_id,
      project_name = var.project_name
    }
  )
}

resource "aws_iam_role_policy" "nuke_list_ou_accounts" {
  name   = "NukeListOUAccounts"
  role   = aws_iam_role.nuke_code_build_project_role.id
  policy = file("files/NukeListOUAccounts.json")
}

resource "aws_iam_role_policy" "s3_bucket_read_only" {
  name = "S3BucketReadOnly"
  role = aws_iam_role.nuke_code_build_project_role.id

  policy = templatefile("templates/S3BucketReadOnly.json.tftpl", {
      bucket_arn = aws_s3_bucket.aws_nuke_config.arn
  })
}

resource "aws_iam_role" "nuke_code_build_project_role" {
  assume_role_policy = file("files/NukeCodeBuildProjectRole.json")
  name = "NukeCodeBuildProjectRole"
  path = "/"
}

# EventBridgeNukeSchedule-abcjorge2022
# aws_iam_role.event_bridge_nuke_schedule2:

resource "aws_iam_role_policy" "event_bridge_nuke_state_machine_execution_policy" {
  name = "EventBridgeNukeStateMachineExecutionPolicy"
  role = aws_iam_role.event_bridge_nuke_schedule.id
  policy = templatefile("templates/EventBridgeNukeStateMachineExecutionPolicy.json.tftpl", {
    region = var.region,
    account_id = local.account_id
  }
  )
}

resource "aws_iam_role" "event_bridge_nuke_schedule" {
  assume_role_policy = file("files/EventBridgeNukeSchedule.json")
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
  policy = templatefile("templates/nukeAccountCleanserCodebuildStateMachinePolicy.json.tftpl", {
    code_build_arn = aws_codebuild_project.aws_nuke_cleanser.arn,
    sns_arn = aws_sns_topic.aws_nuke_notify.arn,
    region = var.region,
    account_id = local.account_id
  }

  )
}

resource "aws_iam_role" "nuke_account_cleanser_codebuild_state_machine_role" {
  assume_role_policy = file("files/nukeAccountCleanserCodebuildStateMachineRole.json")
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
  assume_role_policy = templatefile("templates/nukeAutoAccountCleanser.json.tftpl", {
    principal_arn = aws_iam_role.nuke_code_build_project_role.arn
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

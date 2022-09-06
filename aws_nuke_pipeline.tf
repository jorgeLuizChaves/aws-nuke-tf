# aws_sfn_state_machine.nuke-account-cleanser-codebuild-state-machine:
resource "aws_sfn_state_machine" "nuke_account_cleanser_codebuild_state_machine" {
  depends_on = [
    aws_iam_role_policy.event_bridge_nuke_state_machine_execution_policy
  ]
  definition = templatefile("files/templates/aws_sfn_state_machine.nuke_account_cleanser_codebuild_state_machine.json.tftpl",
    {
      project_name = aws_codebuild_project.aws_nuke_cleanser.name,
      topic_arn    = aws_sns_topic.aws_nuke_notify.arn
  })
  name     = "nuke-account-cleanser-codebuild-state-machine"
  role_arn = aws_iam_role.nuke_account_cleanser_codebuild_state_machine_role.arn
  tags     = {}
  tags_all = {}
  type     = "STANDARD"

  logging_configuration {
    include_execution_data = false
    level                  = "OFF"
  }

  tracing_configuration {
    enabled = false
  }
}

# CODE BUILD PROJECT
# aws_codebuild_project.aws_nuke_cleanser:
resource "aws_codebuild_project" "aws_nuke_cleanser" {
  badge_enabled          = false
  build_timeout          = 120
  concurrent_build_limit = 1
  description            = "Builds a container to run AWS-Nuke for all accounts within the specified account/regions"
  encryption_key         = "arn:aws:kms:${var.region}:${local.account_id}:alias/aws/s3"
  name                   = var.project_name
  project_visibility     = "PRIVATE"
  queued_timeout         = 480
  service_role           = aws_iam_role.nuke_code_build_project_role.arn
  tags                   = {}
  tags_all               = {}

  artifacts {
    encryption_disabled    = false
    override_artifact_name = false
    type                   = "NO_ARTIFACTS"
  }

  cache {
    modes = []
    type  = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/docker:18.09.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"

    dynamic environment_variable {
      for_each = local.env_vars
      content {
        name  = environment_variable.value["name"]
        type  = environment_variable.value["type"]
        value = environment_variable.value["value"]
      }

    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = var.project_name
      status     = "ENABLED"
    }
  }

  source {
    buildspec           = file("files/templates/aws_codebuild_project_aws_nuke_cleanser.yaml")
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "NO_SOURCE"
  }
}

resource "aws_cloudwatch_event_rule" "event_bridge_nuke_schedule" {
  description         = "Scheduled Event for running AWS Nuke on the target accounts within the specified regions"
  event_bus_name      = "default"
  is_enabled          = true
  name                = "EventBridgeNukeSchedule"
  role_arn            = aws_iam_role.event_bridge_nuke_schedule.arn
  schedule_expression = "cron(${var.aws_nuke_cron})"
  tags                = {}
  tags_all            = {}
}

resource "aws_cloudwatch_event_target" "stop_instances" {
  target_id = "AWSNukeCleaner"
  arn       = aws_sfn_state_machine.nuke_account_cleanser_codebuild_state_machine.arn
  rule      = aws_cloudwatch_event_rule.event_bridge_nuke_schedule.name
  role_arn  = aws_iam_role.event_bridge_nuke_schedule.arn
  input = jsonencode(
    {
      InputPayLoad = {
        nuke_config_bucket   = "${aws_s3_bucket.aws_nuke_config.bucket}"
        nuke_dry_run         = "${var.nuke_dry_run}"
        nuke_version         = var.nuke_aws_version
        region_list          = var.regions_to_nuke
        sns_notification_arn = aws_sns_topic.aws_nuke_notify.arn
      }
    }
  )
}

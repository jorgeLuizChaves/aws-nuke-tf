# aws_sfn_state_machine.nuke-account-cleanser-codebuild-state-machine:
resource "aws_sfn_state_machine" "nuke_account_cleanser_codebuild_state_machine" {
  depends_on = [
    aws_iam_role_policy.event_bridge_nuke_state_machine_execution_policy
  ]
  definition = jsonencode(
    {
      Comment = "AWS Nuke Account Cleanser for multi-region single account clean up using SFN Map state parallel invocation of CodeBuild project."
      StartAt = "StartNukeCodeBuildForEachRegion"
      States = {
        "Clean Output and Notify" = {
          End = true
          Parameters = {
            "Message.$" = "$.InputPayLoad"
            Subject     = "State Machine for Nuke Account Cleanser succeeded"
            TopicArn    = aws_sns_topic.aws_nuke_notify.arn
          }
          Resource = "arn:aws:states:::sns:publish"
          Type     = "Task"
        }
        StartNukeCodeBuildForEachRegion = {
          ItemsPath = "$.InputPayLoad.region_list"
          Iterator = {
            StartAt = "Trigger Nuke CodeBuild Job"
            States = {
              "Check Nuke CodeBuild Job Status" = {
                Choices = [
                  {
                    Next         = "Nuke Success"
                    StringEquals = "SUCCEEDED"
                    Variable     = "$.AccountCleanserRegionOutput.NukeBuildOutput.BuildStatus"
                  },
                  {
                    Next         = "Nuke Failed"
                    StringEquals = "FAILED"
                    Variable     = "$.AccountCleanserRegionOutput.NukeBuildOutput.BuildStatus"
                  },
                ]
                Default = "Nuke Failed"
                Type    = "Choice"
              }
              "Nuke Failed" = {
                Type = "Fail"
              }
              "Nuke Success" = {
                Type = "Succeed"
              }
              "Trigger Nuke CodeBuild Job" = {
                Catch = [
                  {
                    ErrorEquals = [
                      "States.TaskFailed",
                    ]
                    Next = "Nuke Failed"
                  },
                ]
                Next = "Check Nuke CodeBuild Job Status"
                Parameters = {
                  EnvironmentVariablesOverride = [
                    {
                      Name      = "NukeTargetRegion"
                      Type      = "PLAINTEXT"
                      "Value.$" = "$.region_id"
                    },
                    {
                      Name      = "AWS_NukeDryRun"
                      Type      = "PLAINTEXT"
                      "Value.$" = "$.nuke_dry_run"
                    },
                    {
                      Name      = "AWS_NukeVersion"
                      Type      = "PLAINTEXT"
                      "Value.$" = "$.nuke_version"
                    },
                    {
                      Name      = "NukeS3Bucket"
                      Type      = "PLAINTEXT"
                      "Value.$" = "$.nuke_config_bucket"
                    },
                    {
                      Name      = "Publish_TopicArn"
                      Type      = "PLAINTEXT"
                      "Value.$" = "$.sns_notification_arn"
                    },
                  ]
                  ProjectName = aws_codebuild_project.aws_nuke_cleanser.name
                }
                Resource   = "arn:aws:states:::codebuild:startBuild.sync"
                ResultPath = "$.AccountCleanserRegionOutput"
                ResultSelector = {
                  "NukeBuildOutput.$" = "$.Build"
                }
                Retry = [
                  {
                    BackoffRate = 1
                    ErrorEquals = [
                      "States.TaskFailed",
                    ]
                    IntervalSeconds = 1
                    MaxAttempts     = 1
                  },
                ]
                Type = "Task"
              }
            }
          }
          MaxConcurrency = 0
          Next           = "Clean Output and Notify"
          Parameters = {
            "nuke_config_bucket.$"   = "$.InputPayLoad.nuke_config_bucket"
            "nuke_dry_run.$"         = "$.InputPayLoad.nuke_dry_run"
            "nuke_version.$"         = "$.InputPayLoad.nuke_version"
            "region_id.$"            = "$$.Map.Item.Value"
            "sns_notification_arn.$" = "$.InputPayLoad.sns_notification_arn"
          }
          ResultPath = null
          Type       = "Map"
        }
      }
    }
  )
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
  encryption_key         = "arn:aws:kms:${var.region}:${local.account_di}:alias/aws/s3"
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

    environment_variable {
      name  = "AWS_NukeDryRun"
      type  = "PLAINTEXT"
      value = "true"
    }
    environment_variable {
      name  = "AWS_NukeVersion"
      type  = "PLAINTEXT"
      value = "2.15.0"
    }
    environment_variable {
      name  = "Publish_TopicArn"
      type  = "PLAINTEXT"
      value = aws_sns_topic.aws_nuke_notify.arn
    }
    environment_variable {
      name  = "NukeS3Bucket"
      type  = "PLAINTEXT"
      value = aws_s3_bucket.aws_nuke_config.bucket
    }
    environment_variable {
      name  = "NukeAssumeRoleArn"
      type  = "PLAINTEXT"
      value = aws_iam_role.nuke_auto_account_cleanser.arn
    }
    environment_variable {
      name  = "NukeCodeBuildProjectName"
      type  = "PLAINTEXT"
      value = var.project_name
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = var.project_name
      status     = "ENABLED"
    }
  }

  source {
    buildspec           = <<-EOT
            version: 0.2
            phases:
              install:
                on-failure: ABORT
                commands:
                  - export AWS_NUKE_VERSION=$AWS_NukeVersion
                  - apt-get install -y wget
                  - apt-get install jq
                  - wget https://github.com/rebuy-de/aws-nuke/releases/download/v$AWS_NUKE_VERSION/aws-nuke-v$AWS_NUKE_VERSION-linux-amd64.tar.gz --no-check-certificate
                  - tar xvf aws-nuke-v$AWS_NUKE_VERSION-linux-amd64.tar.gz
                  - chmod +x aws-nuke-v$AWS_NUKE_VERSION-linux-amd64
                  - mv aws-nuke-v$AWS_NUKE_VERSION-linux-amd64 /usr/local/bin/aws-nuke
                  - aws-nuke version
                  - echo "Setting aws cli profile with config file for role assumption using metadata"
                  - aws configure set profile.nuke.role_arn $${NukeAssumeRoleArn}
                  - aws configure set profile.nuke.credential_source "EcsContainer"
                  - export AWS_PROFILE=nuke
                  - export AWS_DEFAULT_PROFILE=nuke
                  - export AWS_SDK_LOAD_CONFIG=1
              build:
                on-failure: CONTINUE
                commands:
                  - echo "Getting seed config file from S3";
                  - aws s3 cp s3://$NukeS3Bucket/nuke_generic_config.yaml .
                  - echo "Updating the TARGET_REGION in the generic config from the parameter"
                  - sed -i "s/TARGET_REGION/$NukeTargetRegion/g" nuke_generic_config.yaml
                  - echo "Getting filter/exclusion python script from S3";
                  - aws s3 cp s3://$NukeS3Bucket/nuke_config_update.py .
                  - echo "Getting 12-digit ID of this account"
                  - account_id=$(aws sts get-caller-identity |jq -r ".Account");
                  - echo "Running Config filter/update script";
                  - python3 nuke_config_update.py --account $account_id --region "$NukeTargetRegion";
                  - echo "Configured nuke_config.yaml";
                  - echo "Running Nuke on Account";
                  - |
                    if [ "$AWS_NukeDryRun" = "true" ]; then
                      for file in $(ls nuke_config_$NukeTargetRegion*) ; do aws-nuke -c $file --force --profile nuke |tee -a aws-nuke.log; done
                    elif [ "$AWS_NukeDryRun" = "false" ]; then
                      for file in $(ls nuke_config_$NukeTargetRegion*) ; do aws-nuke -c $file --force --no-dry-run --profile nuke |tee -a aws-nuke.log; done
                    else
                      echo "Couldn't determine Dryrun flag...exiting"
                      exit 1
                    fi
                  - nuke_pid=$!;
                  - wait $nuke_pid;
                  - echo "Completed Nuke Process for account"
              post_build:
                commands:
                  - echo $CODEBUILD_BUILD_SUCCEEDING
                  - echo "Get current timestamp for reports naming.."
                  - BLD_START_TIME=$(date -d @$(($CODEBUILD_START_TIME/1000)))
                  - CURR_TIME_UTC=$(date -u)
                  - |
                    {
                            echo "  Account Cleansing Process Failed;"
                            echo    ""
                            
                            echo "  ----------------------------------------------------------------"
                            echo "  Summary of the process:"
                            echo "  ----------------------------------------------------------------"
                            echo "  DryRunMode                   : $AWS_NukeDryRun"
                            echo "  Account ID                   : $(aws sts get-caller-identity | jq -r .Account)"
                            echo "  Target Region                : $NukeTargetRegion"
                            echo "  Build State                  : $([ "$${CODEBUILD_BUILD_SUCCEEDING}" = "1" ] && echo "JOB SUCCEEDED" || echo "JOB FAILED")"
                            echo "  Build ID                     : $${CODEBUILD_BUILD_ID}"
                            echo "  CodeBuild Project Name       : $NukeCodeBuildProjectName"
                            echo "  Process Start Time           : $${BLD_START_TIME}"
                            echo "  Process End Time             : $${CURR_TIME_UTC}"
                            echo "  Log Stream Path              : $NukeCodeBuildProjectName/$${CODEBUILD_LOG_PATH}"
                            echo "  ----------------------------------------------------------------"
                            echo "  ################# Removed the following resources #################"
                            echo    ""
                    } >> fail_email_template.txt
                  - | 
                    if [ "$CODEBUILD_BUILD_SUCCEEDING" = "0" ]; then 
                      echo "Couldn't process Nuke Cleanser Exiting";
                      aws sns publish --topic-arn $Publish_TopicArn --message file://fail_email_template.txt --subject "Nuke Account Cleanser Failed"
                      exit 1;
                    fi
                  - sleep 10
                  - echo "Getting CW Logs event start and stop time"
                  - aws logs describe-log-streams --log-group-name $NukeCodeBuildProjectName --order-by LastEventTime --descending --max-items 1 > $account_id_logstreams.json;
                  - LOG_EVENT_END_TIME=$(cat $account_id_logstreams.json |jq -r .logStreams[].lastIngestionTime);
                  - LOG_EVENT_START_TIME=$(cat $account_id_logstreams.json |jq -r .logStreams[].firstEventTimestamp);
                  - LOG_STREAM_NAME=$(cat $account_id_logstreams.json |jq -r .logStreams[].logStreamName);
                  - echo $LOG_EVENT_END_TIME
                  - echo $LOG_EVENT_START_TIME
                  - echo $LOG_STREAM_NAME
                  - BLD_END_TIME=$(date -d @$(($LOG_EVENT_END_TIME/1000)))
                  - | 
                    if [ -z "$${LOG_STREAM_NAME}" ]; then
                      echo "Couldn't filter log events as params are null or empty";
                      exit 0;
                    else
                      aws logs filter-log-events --log-group-name $NukeCodeBuildProjectName --start-time $LOG_EVENT_START_TIME --end-time $LOG_EVENT_END_TIME --log-stream-names $LOG_STREAM_NAME --filter-pattern "removed" --no-interleaved | jq -r .events[].message > log_output.txt;
                    fi
                  - |
                    if [ -r log_output.txt ]; then
                      content=$(cat log_output.txt)
                      echo $content
                    elif [ -f "log_output.txt" ]; then
                      echo "The file log_output.txt exists but is not readable to the script."
                    else
                      echo "The file log_output.txt does not exist."
                    fi
                  - echo "Publishing Log Ouput to SNS:"
                  - sub="Nuke Account Cleanser Succeeded"
                  - |
                    {
                            echo "  Account Cleansing Process Completed;"
                            echo    ""
                            
                            echo "  ------------------------------------------------------------------"
                            echo "  Summary of the process:"
                            echo "  ------------------------------------------------------------------"
                            echo "  DryRunMode                   : $AWS_NukeDryRun"
                            echo "  Account ID                   : $(aws sts get-caller-identity | jq -r .Account)"
                            echo "  Target Region                : $NukeTargetRegion"
                            echo "  Build State                  : $([ "$${CODEBUILD_BUILD_SUCCEEDING}" = "1" ] && echo "JOB SUCCEEDED" || echo "JOB FAILED")"
                            echo "  Build ID                     : $${CODEBUILD_BUILD_ID}"
                            echo "  CodeBuild Project Name       : $NukeCodeBuildProjectName"
                            echo "  Process Start Time           : $${BLD_START_TIME}"
                            echo "  Process End Time             : $${BLD_END_TIME}"
                            echo "  Log Stream Path              : $NukeCodeBuildProjectName/$${CODEBUILD_LOG_PATH}"
                            echo "  ------------------------------------------------------------------"
                            echo "  ################ Removed the following resources #################"
                            echo    ""
                    } >> email_template.txt
            
                  - cat log_output.txt >> email_template.txt
                  - aws sns publish --topic-arn $Publish_TopicArn --message file://email_template.txt --subject "$sub"
                  - echo "Resources Nukeable:"
                  - cat aws-nuke.log | grep -F "Scan complete:"
                  - echo "Total number of Resources Removed:"
                  - cat aws-nuke.log | grep -c " - removed" || echo "Nothing removed yet"
                  - echo "List of Resources Deleted today:"
                  - cat aws-nuke.log | grep -F " - removed" || echo "Nothing deleted yet"
        EOT
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "NO_SOURCE"
  }
}


# event bridge 
# aws_cloudwatch_event_rule.event_bridge_nuke_schedule:
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

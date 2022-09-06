terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.26.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  env_vars = [
     {
      name  = "AWS_NukeDryRun"
      type  = "PLAINTEXT"
      value = "true"
    },
     {
      name  = "AWS_NukeVersion"
      type  = "PLAINTEXT"
      value = "2.15.0"
    },
     {
      name  = "Publish_TopicArn"
      type  = "PLAINTEXT"
      value = aws_sns_topic.aws_nuke_notify.arn
    },
     {
      name  = "NukeS3Bucket"
      type  = "PLAINTEXT"
      value = aws_s3_bucket.aws_nuke_config.bucket
    },
     {
      name  = "NukeAssumeRoleArn"
      type  = "PLAINTEXT"
      value = aws_iam_role.nuke_auto_account_cleanser.arn
    },
     {
      name  = "NukeCodeBuildProjectName"
      type  = "PLAINTEXT"
      value = var.project_name
    }
  ]
}

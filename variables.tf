variable "project_name" {
  type        = string
  description = "code build project name"
}

variable "region" {
  type        = string
  default     = "us-west-2"
  description = "codebuild deploy region"
}

variable "aws_nuke_cron" {
  type        = string
  description = "cron to run aws nuke"
}

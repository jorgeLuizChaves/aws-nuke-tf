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

variable "emails_notification" {
  type        = list(string)
  description = "emails that will be notified by AWS when resources are deleted"
  default     = ["default@email.com"]
}

variable "regions_to_nuke" {
  type        = list(string)
  description = "regions that will have assets deleted"
}

variable "nuke_aws_version" {
  type        = string
  description = "nuke version to use"
  default     = "2.15.0"
}

variable "nuke_dry_run" {
  type        = string
  description = "dry run"
  default     = "false"

}

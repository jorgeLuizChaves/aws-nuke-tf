resource "random_integer" "num" {
  min = 1
  max = 50000
}

# BUCKET
resource "aws_s3_bucket" "aws_nuke_config" {
  bucket = "${var.project_name}-${random_integer.num.result}"

  tags = {
    DoNotNuke = true
    owner     = "DevOps"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.aws_nuke_config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "nuke_bucket_policy" {
  bucket = aws_s3_bucket.aws_nuke_config.id
  policy = templatefile("files/templates/aws_s3_bucket_policy.nuke_bucket_policy.policy.json.tftpl",
    {
      resource_arn = aws_s3_bucket.aws_nuke_config.arn
  })
}

resource "aws_s3_object" "nuke_config_update" {
  bucket = aws_s3_bucket.aws_nuke_config.id
  source = "config/nuke_config_update.py"
  key    = "nuke_config_update.py"
}

resource "aws_s3_object" "nuke_generic_config" {
  bucket = aws_s3_bucket.aws_nuke_config.id
  source = "config/nuke_generic_config.yaml"
  key    = "nuke_generic_config.yaml"
}

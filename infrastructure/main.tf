# Copyright (c) 2025, Assessment: SolutionsEngineer-candidate-larry

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source = "hashicorp/archive"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  backend "s3" {
    bucket = "swiftline-tfstate-candidate-larry" # Must match the bucket created
    key    = "swiftline/terraform.tfstate"
    region = "ca-central-1" # Must match the region where the bucket is created
  }
}

provider "aws" {
  region = var.region_code
  
  default_tags {
    tags = {
      Assessment = var.tag_value
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# 0. VARIABLES
# ==============================================================================
variable "dynamodb_table_name" {
  type    = string
  default = "SwiftLineOrdersLarry"
}

variable "region_code" {
  type    = string
  default = "us-east-1"
}

variable "tag_value" {
  type    = string
  default = "SolutionsEngineer-candidate-larry"
}

variable "lambda_function_name" {
  type = string
  default = "SwiftLineOrderCheckLarry"
}

variable "cloudformation_stack_name" {
  type = string
  default = "SwiftLineLexStackLarry"
}

# ==============================================================================
# 1. DYNAMODB TABLE & DATA
# ==============================================================================
resource "aws_dynamodb_table" "orders" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "trackingId"

  attribute {
    name = "trackingId"
    type = "S"
  }
}

# Insert Sample Data (Assessment Requirement)
resource "aws_dynamodb_table_item" "sample_order" {
  table_name = aws_dynamodb_table.orders.name
  hash_key   = aws_dynamodb_table.orders.hash_key
  item = file("${path.module}/../data/dynamodb_item.json")
}

# ==============================================================================
# 2. LAMBDA FUNCTION
# ==============================================================================
# Zip the python file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/lambda_function.py"
  output_path = "${path.module}/../backend/lambda_function.zip"
}

# Explicit Log Group (Controls retention and ensures tagging)
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.chatbot_logic.function_name}"
  retention_in_days = 7
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "swiftline_lambda_role_larry"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# IAM Policy (Logs + DynamoDB Read)
resource "aws_iam_role_policy" "lambda_policy" {
  name = "swiftline_lambda_policy_larry"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:GetItem", "dynamodb:Query"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.orders.arn
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "chatbot_logic" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
  timeout          = 10

  # Lambda to enable X-Ray tracing
  tracing_config {
    mode = "Active"
  }
}

# IAM Role for X-Ray
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# ==============================================================================
# 3. AMAZON LEX V2 BOT
# ==============================================================================
# IAM Role for Lex Service
resource "aws_iam_role" "lex_role" {
  name = "swiftline_lex_role_larry"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lexv2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lex_policy_attach" {
  role       = aws_iam_role.lex_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonLexFullAccess"
}

resource "aws_cloudformation_stack" "lex_bot" {
  name = var.cloudformation_stack_name

  # We pass the Lambda ARN and Role ARN into the CF template
  parameters = {
    LambdaArn  = aws_lambda_function.chatbot_logic.arn
    LexRoleArn = aws_iam_role.lex_role.arn
    AssessmentTag = var.tag_value
  }

  template_body = file("${path.module}/lex_bot_template.yaml")

  tags = {
    Assessment = var.tag_value
  }
}

# Allow Lex to Invoke Lambda
resource "aws_lambda_permission" "lex_invoke" {
  statement_id  = "AllowLexV2Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatbot_logic.function_name
  principal     = "lex.amazonaws.com"
  # We construct the Source ARN manually because we need the generic Alias ARN structure
  source_arn    = "arn:aws:lex:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:bot-alias/${aws_cloudformation_stack.lex_bot.outputs["BotId"]}/${aws_cloudformation_stack.lex_bot.outputs["BotAliasId"]}"
}

resource "aws_lambda_permission" "lex_invoke_test" {
  statement_id  = "AllowLexV2InvokeTest"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatbot_logic.function_name
  principal     = "lex.amazonaws.com"
  
  # Note the hardcoded "TSTALIASID" at the end. This is required for the Console Test button.
  source_arn    = "arn:aws:lex:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:bot-alias/${aws_cloudformation_stack.lex_bot.outputs["BotId"]}/TSTALIASID"
}

# ==============================================================================
# 4. FRONTEND (S3)
# ==============================================================================
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "frontend" {
  bucket = "swiftline-chatbot-ui-${random_id.bucket_suffix.hex}-larry"
}

resource "aws_s3_bucket_website_configuration" "frontend_config" {
  bucket = aws_s3_bucket.frontend.id
  index_document { suffix = "index.html" }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.frontend.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

resource "aws_s3_object" "html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  source       = "${path.module}/../frontend/index.html"
  content_type = "text/html"
}

# ==============================================================================
# 6. CLOUDFRONT (CDN for HTTPS)
# ==============================================================================
# Cache Policy (Managed-CachingOptimized)
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "frontend_cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # Use only North America/Europe (Cheapest)

  # origin: points to the S3 Website Endpoint (HTTP)
  origin {
    domain_name = aws_s3_bucket_website_configuration.frontend_config.website_endpoint
    origin_id   = "S3-SwiftLine-Frontend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # S3 Website only speaks HTTP
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-SwiftLine-Frontend"

    viewer_protocol_policy = "redirect-to-https" # The Magic Line: Forces HTTPS
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # Generates a free dxxxx.cloudfront.net cert
  }
}

# ==============================================================================
# 5. OUTPUTS
# ==============================================================================
output "https_url" {
  value = "https://${aws_cloudfront_distribution.frontend_cdn.domain_name}"
}

output "bot_id" {
  value = aws_cloudformation_stack.lex_bot.outputs["BotId"]
}

output "bot_alias_id" {
  value = aws_cloudformation_stack.lex_bot.outputs["BotAliasId"]
}
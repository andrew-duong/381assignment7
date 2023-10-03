terraform {
  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"

    }
  }
}
# specify the provider region
provider "aws" {
  region     = "us-east-1"
}

locals {
  function_delete = "delete-note-30139573"
  function_save = "save-note-30139573"
  function_get = "get-notes-30139573"
  handler_delete  = "main.delete_handler"
  handler_save  = "main.save_handler"
  handler_get  = "main.get_handler"
  artifact_get = "artifact_get.zip"
  artifact_save = "artifact_save.zip"
  artifact_delete = "artifact_delete.zip"
}

resource "aws_iam_role" "lambda_get" {
  name               = "iam-for-lambda-${local.function_get}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_save" {
  name               = "iam-for-lambda-${local.function_save}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_delete" {
  name               = "iam-for-lambda-${local.function_delete}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "lambda_get" {
  type = "zip"
  # this file (main.py) needs to exist in the same folder as this 
  # Terraform configuration file
  source_dir = "C:/Users/fresh/OneDrive/Desktop/Coding/ENSF381/proj7/assignment-07-lotion-plus-andrew-and-joseph/functions/get-notes"
  output_path = "artifact_get.zip"
}

data "archive_file" "lambda_save" {
  type = "zip"
  # this file (main.py) needs to exist in the same folder as this 
  # Terraform configuration file
  source_dir = "C:/Users/fresh/OneDrive/Desktop/Coding/ENSF381/proj7/assignment-07-lotion-plus-andrew-and-joseph/functions/save-note"
  output_path = "artifact_save.zip"
}

data "archive_file" "lambda_delete" {
  type = "zip"
  # this file (main.py) needs to exist in the same folder as this 
  # Terraform configuration file
  source_dir = "C:/Users/fresh/OneDrive/Desktop/Coding/ENSF381/proj7/assignment-07-lotion-plus-andrew-and-joseph/functions/delete-note"
  output_path = "artifact_delete.zip"
}

resource "aws_iam_policy" "logs_get" {
  name        = "lambda-logging-${local.function_get}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:GetItem",
        "dynamodb:Query"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.dynamo.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "logs_save" {
  name        = "lambda-logging-${local.function_save}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:PutItem"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.dynamo.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "logs_delete" {
  name        = "lambda-logging-${local.function_delete}"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "dynamodb:DeleteItem"
      ],
      "Resource": ["arn:aws:logs:*:*:*", "${aws_dynamodb_table.dynamo.arn}"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda_get" {
  role             = aws_iam_role.lambda_get.arn
  function_name    = local.function_get
  handler          = local.handler_get
  filename         = local.artifact_get
  source_code_hash = data.archive_file.lambda_get.output_base64sha256
  runtime = "python3.9"
}

resource "aws_lambda_function" "lambda_save" {
  role             = aws_iam_role.lambda_save.arn
  function_name    = local.function_save
  handler          = local.handler_save
  filename         = local.artifact_save
  source_code_hash = data.archive_file.lambda_save.output_base64sha256
  runtime = "python3.9"
}
resource "aws_lambda_function" "lambda_delete" {
  role             = aws_iam_role.lambda_delete.arn
  function_name    = local.function_delete
  handler          = local.handler_delete
  filename         = local.artifact_delete
  source_code_hash = data.archive_file.lambda_delete.output_base64sha256
  runtime = "python3.9"
}

resource "aws_iam_role_policy_attachment" "lambda_logs_delete" {
  role       = aws_iam_role.lambda_delete.name
  policy_arn = aws_iam_policy.logs_delete.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs_save" {
  role       = aws_iam_role.lambda_save.name
  policy_arn = aws_iam_policy.logs_save.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs_get" {
  role       = aws_iam_role.lambda_get.name
  policy_arn = aws_iam_policy.logs_get.arn
}

resource "aws_lambda_function_url" "url_delete" {
  function_name      = aws_lambda_function.lambda_delete.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["DELETE"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

resource "aws_lambda_function_url" "url_save" {
  function_name      = aws_lambda_function.lambda_save.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

resource "aws_lambda_function_url" "url_get" {
  function_name      = aws_lambda_function.lambda_get.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
  }
}

resource "aws_dynamodb_table" "dynamo" {
  name         = "lotion-30145210"
  billing_mode = "PROVISIONED"

  read_capacity = 1
  write_capacity = 1

  hash_key = "email"
  range_key = "id"

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "id"
    type = "S"
  }

}

output "lambda_url_delete" {
  value = aws_lambda_function_url.url_delete.function_url
}

output "lambda_url_save" {
  value = aws_lambda_function_url.url_save.function_url
}

output "lambda_url_get" {
  value = aws_lambda_function_url.url_get.function_url
}

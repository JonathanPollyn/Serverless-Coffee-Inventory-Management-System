locals {
  table_name = aws_dynamodb_table.inventory.name
}

data "archive_file" "get_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/get_items"
  output_path = "${path.module}/build/get_items.zip"
}

resource "aws_lambda_function" "get_items" {
  function_name    = "${var.project_name}-get"
  runtime          = "python3.12"
  handler          = "app.handler"
  role             = aws_iam_role.lambda_exec.arn
  filename         = data.archive_file.get_zip.output_path
  source_code_hash = data.archive_file.get_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.inventory.name
    }
  }
}

# ===================================================
# POST resources
# ===================================================
data "archive_file" "post_file" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/create_item"
  output_path = "${path.module}/build/create_item.zip"
}

resource "aws_lambda_function" "create_item" {
  function_name    = "${var.project_name}-post"
  runtime          = "python3.12"
  handler          = "app.handler"
  role             = aws_iam_role.lambda_exec.arn
  filename         = data.archive_file.post_file.output_path
  source_code_hash = data.archive_file.post_file.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.inventory.name
    }
  }
}

# ========================================================
# Update Lambda
# ========================================================

data "archive_file" "put_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/update_item"
  output_path = "${path.module}/build/update_item.zip"
}

resource "aws_lambda_function" "update_item" {
  function_name    = "${var.project_name}-put"
  runtime          = "python3.12"
  handler          = "app.handler"
  role             = aws_iam_role.lambda_exec.arn
  filename         = data.archive_file.put_zip.output_path
  source_code_hash = data.archive_file.put_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.inventory.name
    }
  }
}

# ========================================================
# delete Lambda
# ========================================================
data "archive_file" "delete_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/delete_item"
  output_path = "${path.module}/build/delete_item.zip"
}

resource "aws_lambda_function" "delete_item" {
  function_name    = "${var.project_name}-delete"
  runtime          = "python3.12"
  handler          = "app.handler"
  role             = aws_iam_role.lambda_exec.arn
  filename         = data.archive_file.delete_zip.output_path
  source_code_hash = data.archive_file.delete_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.inventory.name
    }
  }
}
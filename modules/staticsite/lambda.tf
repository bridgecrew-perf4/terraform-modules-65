resource "aws_iam_role" "execution_role" {
  name = "${var.base_name}_ledge_role"
  tags = {
    Project   = var.base_name
    ManagedBy = "terraform"
  }
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_lambda_function" "orsp" {
  provider         = aws.us_east_1
  function_name    = "${var.base_name}_orsp"
  role             = aws_iam_role.execution_role.arn
  runtime          = "nodejs12.x"
  handler          = "index.handler"
  filename         = data.archive_file.orsp.output_path
  source_code_hash = data.archive_file.orsp.output_base64sha256
  memory_size      = 128
  timeout          = 3
  publish          = true
  tags = {
    Project   = var.base_name
    ManagedBy = "terraform"
  }
}

data "archive_file" "orsp" {
  type        = "zip"
  output_path = "${path.module}/origin-response/orsp.zip"
  source {
    filename = "index.js"
    content  = templatefile("${path.module}/origin-response/index.js.tpl", { csp = var.content_security_policy })
  }
}

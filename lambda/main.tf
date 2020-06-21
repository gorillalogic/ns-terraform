resource "aws_lambda_function" "lambda" {
  filename      = data.archive_file.zip_lambda.output_path
  function_name = "${var.name}_${var.handler}"
  role          = var.role
  handler       = "${var.name}.${var.handler}"
  runtime       = var.runtime
  tags = var.default_tags
}

data "archive_file" "zip_lambda" {
  type        = "zip"
  output_path = "${var.name}.zip"
  source_dir = "src/${var.name}/"

  depends_on = [null_resource.pip]
}

# Prepare Lambda package (https://github.com/hashicorp/terraform/issues/8344#issuecomment-345807204)
resource "null_resource" "pip" {
  triggers = {
    main         = base64sha256(file("src/${var.name}/${var.name}.py"))
    requirements = base64sha256(file("src/${var.name}/requirements.txt"))
  }

  provisioner "local-exec" {
    command = "pip3 install -r src/${var.name}/requirements.txt -t src/${var.name}/"
  }
}
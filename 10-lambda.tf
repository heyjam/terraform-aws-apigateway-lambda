
data "template_file" "pm_template" {
    template = file("${path.module}/template/lambda_code/pm.py")
}

resource "local_file" "pm_file" {
    content = data.template_file.pm_template.rendered
    filename = "${path.module}/template/lambda_code/pm.py"
  
}

data "archive_file" "pm_zip" {
  type    = "zip"
  output_path = "${path.module}/${local.zipfile}"
  source_dir = "${path.module}/template/lambda_code"

  ### https://github.com/hashicorp/terraform-provider-archive/pull/55
  # excludes = [ 
  #   "${path.module}/template/lambda_code/venv",
  #   "${path.module}/template/lambda_code/.idea",
  #  ]
  
  depends_on = [
    local_file.pm_file,
  ]
}

resource "null_resource" "delete_zip" {

    provisioner "local-exec" {
        working_dir = path.module
        command = "rm -f ${local.zipfile}"
    
    }

    triggers = {
      lambda_pm = aws_lambda_function.pm.id
      output_file = data.archive_file.pm_zip.id
    }  
}

data "aws_lb" "selected" {
  name = var.service_lb_name
}

data "aws_lb_listener" "selected80" {
  load_balancer_arn = data.aws_lb.selected.arn
  port              = 80
}
data "aws_lb_target_group" "selected80tg" {
  name = var.service_tagetgroup_80
}

data "aws_lb_listener" "selected443" {
  load_balancer_arn = data.aws_lb.selected.arn
  port              = 443
}
data "aws_lb_target_group" "selected443tg" {
  name = var.service_tagetgroup_443
}


resource "aws_lambda_function" "pm" {
    function_name = var.lambda_function_name
    role = aws_iam_role.lambda_exec.arn

    filename = "${path.module}/${local.zipfile}"
    source_code_hash = data.archive_file.pm_zip.output_base64sha256
    handler = "pm.lambda_handler"
    runtime = "python3.8"

    environment {
      variables = {
        listener_arns = "${data.aws_lb_listener.selected80.arn},${data.aws_lb_listener.selected443.arn}"
        target_group_arn_pm = aws_lb_target_group.service_target_group_to_pm_nlb.arn,
        target_group_arn_service = "${data.aws_lb_target_group.selected80tg.arn},${data.aws_lb_target_group.selected443tg.arn}"
      }
    }

    tags = merge(
      var.tags,
      {
        "Name"  = var.lambda_function_name
      },
    )

}

resource "aws_iam_role" "lambda_exec" {
   name = "lambda_exec"

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

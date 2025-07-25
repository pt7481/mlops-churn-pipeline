resource "aws_ecr_repository" "prefect" {
  name                 = "${var.project_id}-prefect"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "null_resource" "write_repo_name_to_github_action_yml" {
  provisioner "local-exec" {
    command = <<EOT
      set -e

      WORKFLOW_FILE="../.github/workflows/deploy-prefect.yml"

      ## --- Update deploy-prefect.yml env block ---
      if grep -q "ECR_REPO_NAME:" "$WORKFLOW_FILE"; then
        sed -i.bak "s|ECR_REPO_NAME:.*|ECR_REPO_NAME: ${aws_ecr_repository.prefect.name}|" "$WORKFLOW_FILE"

        echo "✅ File updated:"
        echo "  deploy-prefect.yml -> ECR_REPO_NAME=${aws_ecr_repository.prefect.name}"
      else
        echo "❗ WARNING: ECR_REPO_NAME not found in $WORKFLOW_FILE"
      fi
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [aws_ecr_repository.prefect]
}

####### ECR Repository for S3-to-Prefect Lambda Docker Image #######

resource "aws_ecr_repository" "s3_to_prefect_lambda" {
  name                 = "${var.project_id}-s3-to-prefect-lambda"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "null_resource" "build_and_push_s3_to_prefect_lambda_image" {
    triggers = {
        docker_file = md5(file("../code/s3_to_prefect_lambda/Dockerfile"))
    }

    provisioner "local-exec" {
        command = <<EOT
            set -e

            echo "Using static tag while component not being actively developed..."
            IMAGE_TAG=latest

            echo "Logging in to ECR..."
            aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.s3_to_prefect_lambda.repository_url}

            echo "Building Docker image with tag $IMAGE_TAG..."
            DOCKER_BUILDKIT=0 docker build -t ${aws_ecr_repository.s3_to_prefect_lambda.repository_url}:$IMAGE_TAG ../code/s3_to_prefect_lambda/

            echo "Pushing image to ECR with tag $IMAGE_TAG..."
            docker push ${aws_ecr_repository.s3_to_prefect_lambda.repository_url}:$IMAGE_TAG

            echo "$IMAGE_TAG" > ${path.module}/s3_to_prefect_lambda_image_tag.txt
        EOT
    }

    depends_on = [aws_ecr_repository.s3_to_prefect_lambda]
}

data "local_file" "s3_to_prefect_lambda_image_tag" {
  filename = "${path.module}/s3_to_prefect_lambda_image_tag.txt"
  depends_on = [null_resource.build_and_push_s3_to_prefect_lambda_image]
}

####### ECR Repository for Grafana Custom Lambda Docker Image #######

resource "aws_ecr_repository" "grafana" {
  name                 = "${var.project_id}-grafana"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "null_resource" "build_and_push_grafana_image" {
    triggers = {
        docker_file = md5(file("../code/grafana/Dockerfile"))
    }

    provisioner "local-exec" {
        command = <<EOT
            set -e

            echo "Using static tag while component not being actively developed..."
            IMAGE_TAG=latest

            echo "Logging in to ECR..."
            aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.grafana.repository_url}

            echo "Building Docker image with tag $IMAGE_TAG..."
            DOCKER_BUILDKIT=0 docker build -t ${aws_ecr_repository.grafana.repository_url}:$IMAGE_TAG ../code/grafana/

            echo "Pushing image to ECR with tag $IMAGE_TAG..."
            docker push ${aws_ecr_repository.grafana.repository_url}:$IMAGE_TAG

            echo "$IMAGE_TAG" > ${path.module}/grafana_image_tag.txt
        EOT
    }

    depends_on = [aws_ecr_repository.grafana]
}

data "local_file" "grafana_image_tag" {
  filename = "${path.module}/grafana_image_tag.txt"
  depends_on = [null_resource.build_and_push_grafana_image]
}

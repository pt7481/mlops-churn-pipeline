output "s3_to_prefect_lambda_image_uri" {
    value = "${aws_ecr_repository.s3_to_prefect_lambda.repository_url}:${chomp(data.local_file.s3_to_prefect_lambda_image_tag.content)}"
}

output "grafana_image_uri" {
    value = "${aws_ecr_repository.grafana.repository_url}:${chomp(data.local_file.grafana_image_tag.content)}"
}

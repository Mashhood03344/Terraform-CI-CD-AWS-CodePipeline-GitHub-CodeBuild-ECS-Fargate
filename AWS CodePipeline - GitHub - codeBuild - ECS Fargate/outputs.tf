output "ecr_repository_url" {
  value = aws_ecr_repository.html_app.repository_url
}

output "codepipeline_id" {
  value = aws_codepipeline.ci_cd_pipeline.id
}

output "ecs_service_name" {
  value = aws_ecs_service.simple_html_service.name
}


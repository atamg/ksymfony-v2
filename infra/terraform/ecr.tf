resource "aws_ecr_repository" "app" {
  name = var.project_name
  image_scanning_configuration { scan_on_push = true }
  image_tag_mutability         = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "cleanup" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 5
        description  = "Keep last 5 of everything"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = { type = "expire" }
      }
    ]
  })
}


output "ecr_repo"            { value = aws_ecr_repository.app.name }
output "ecr_repository_url"  { value = aws_ecr_repository.app.repository_url }

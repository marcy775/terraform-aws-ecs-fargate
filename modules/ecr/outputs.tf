output "ecr_repository_url" {
  value = aws_ecr_repository.tf_ecr.repository_url
}

output "adot_repository_url" {
  value = aws_ecr_repository.adot_repo.repository_url
}
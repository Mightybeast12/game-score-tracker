resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  force_delete         = var.force_delete
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = var.repository_name
  }
}
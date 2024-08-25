resource "aws_ecr_repository" "EKS-ecr" {
  name = "service"
    tags = {
        Name = "service"
    } 
}
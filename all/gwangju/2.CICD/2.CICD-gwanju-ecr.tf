resource "aws_ecr_repository" "CICD-ecr" {
  name = "gwangju-repo"
    tags = {
        Name = "gwangju-repo"
    } 
}
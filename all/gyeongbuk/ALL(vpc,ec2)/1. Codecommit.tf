resource "aws_codecommit_repository" "gyeongbuk-commit" {
    repository_name = "wsi-commit"

    default_branch = "main"
    
    lifecycle {
        ignore_changes = [default_branch]
    }
}
output "commit" {
    value = aws_codecommit_repository.gyeongbuk-commit.repository_name
}
output "commit_arn" {
    value = aws_codecommit_repository.gyeongbuk-commit.arn
}
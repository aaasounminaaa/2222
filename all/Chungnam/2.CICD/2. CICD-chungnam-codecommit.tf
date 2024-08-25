resource "aws_codecommit_repository" "chungnam-test" {
  repository_name = "wsc2024-cci"
    default_branch = "master"
    lifecycle {
        ignore_changes = [default_branch]
    }
  description     = "This is the Sample App Repository"
}
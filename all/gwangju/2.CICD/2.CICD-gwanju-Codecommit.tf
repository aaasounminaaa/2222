resource "aws_codecommit_repository" "gwangju-test" {
    repository_name = "gwangju-application-repo"

    default_branch = "main"
    
    lifecycle {
        ignore_changes = [default_branch]
    }
    tags = {
      Name = "gwangju-application-repo"
    } 
}

output "code_commit" {
  value = aws_codecommit_repository.gwangju-test.clone_url_http
}

# resource "null_resource" "upload_file" {
#   provisioner "local-exec" {
#     command = <<EOT
#       $repositoryName = "${aws_codecommit_repository.gwangju-test.repository_name}"
#       $branchName     = "${aws_codecommit_repository.gwangju-test.default_branch}"

#       $fileNames = Get-ChildItem -Path ./gwangju/src -File | Select-Object -ExpandProperty Name

#       foreach ($fileName in $fileNames) {
#         try {
#           $branchInfo = aws codecommit get-branch --repository-name $repositoryName --branch-name $branchName
#           $commitId = ($branchInfo | ConvertFrom-Json).branch.commitId
#         } catch {
#           Write-Warning "Branch does not exist or no commit ID found: $branchName"
#           $commitId = $null
#         }

#         $filePath = (Resolve-Path "./gwangju/src/$fileName").Path
#         $content = Get-Content -Path $filePath -Raw
#         Set-Content -Path $filePath -Value $content -Encoding UTF8

#         if ($commitId) {
#           try {
#             aws codecommit put-file --repository-name $repositoryName --branch-name $branchName --parent-commit-id $commitId --commit-message "day2" --file-content fileb://$filePath --file-path "/$fileName"
#           } catch {
#             Write-Error "Failed to put file with parent commit ID: $fileName"
#             exit 1
#           }
#         } else {
#           try {
#             aws codecommit put-file --repository-name $repositoryName --branch-name $branchName --commit-message "day2" --file-content fileb://$filePath --file-path "/$fileName"
#           } catch {
#             Write-Error "Failed to put file without parent commit ID: $fileName"
#             exit 1
#           }
#         }
#       }
#     EOT
#     interpreter = ["PowerShell", "-Command"]
#   }
#   depends_on = [ aws_codecommit_repository.gwangju-test ]
# }
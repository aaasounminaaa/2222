data "aws_instance" "daejeon-gover" {
  instance_id = aws_instance.daejeon-gover.id
}

resource "aws_cloudwatch_log_group" "daejeon-cw_log_group" {
  name = "/ec2/deny/port"

  tags = {
    Name = "/ec2/deny/port"
  }
}

resource "aws_cloudwatch_log_stream" "daejeon-cw_log_stream" {
  name = "deny-${data.aws_instance.daejeon-gover.id}"
  log_group_name = aws_cloudwatch_log_group.daejeon-cw_log_group.name
}
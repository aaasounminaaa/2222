resource "aws_config_config_rule" "daejeon-config" {
  name                = "wsi-config-port"
  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.daejeon-lambda.arn
    source_detail {
      event_source    = "aws.config"
      message_type    = "ConfigurationItemChangeNotification"
    }
  }
  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
    compliance_resource_id = aws_security_group.daejeon-gover.id
  }
  # depends_on = [
  #   aws_config_configuration_recorder.daejeon-config,
  #   aws_config_configuration_recorder_status.daejeon-config_status,
  #   aws_lambda_permission.daejeon-config
  # ]
}
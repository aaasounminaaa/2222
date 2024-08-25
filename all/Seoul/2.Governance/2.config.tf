resource "aws_config_config_rule" "seoul-config" {
  name                = "wsi-seoul-port"
  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.seoul-governance-lambda.arn
    source_detail {
      event_source    = "aws.config"
      message_type    = "ConfigurationItemChangeNotification"
    }
  }
  # scope {
  #   compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  # }
  # depends_on = [
  #   aws_config_configuration_recorder.seoul-config,
  #   aws_config_configuration_recorder_status.seoul-config_status,
  #   aws_lambda_permission.seoul-governance-permission
  # ]
}
variable "gyeongbuk-domain" {
  default = "wsi-opensearch"
}

data "aws_region" "gyeongbuk-current" {}

data "aws_caller_identity" "gyeongbuk-current" {}

data "aws_iam_policy_document" "gyeongbuk-opensearch" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["es:*"]
    resources = ["arn:aws:es:${data.aws_region.gyeongbuk-current.name}:${data.aws_caller_identity.gyeongbuk-current.account_id}:domain/${var.gyeongbuk-domain}/*"]
  }
}

resource "aws_opensearch_domain" "gyeongbuk-opensearch" {
  domain_name    = var.gyeongbuk-domain
  engine_version = "OpenSearch_2.13"

  cluster_config {
    instance_type           = "r5.large.search"
    instance_count          = 2
    dedicated_master_enabled = true
    dedicated_master_type   = "r5.large.search"
    dedicated_master_count  = 3
    zone_awareness_enabled  = true
    zone_awareness_config {
      availability_zone_count = 2 
    }
  }

  ebs_options {
    ebs_enabled  = true
    volume_size  = 10
    volume_type  = "gp3"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = "Password01!"
    }
  }

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  node_to_node_encryption {
    enabled = true
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = data.aws_iam_policy_document.gyeongbuk-opensearch.json

  tags = {
    Name = "wsi-opensearch"
  }
  lifecycle {
    ignore_changes = []
  }
}
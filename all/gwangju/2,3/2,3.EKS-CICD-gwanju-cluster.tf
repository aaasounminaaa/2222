locals {
  instance_type = "t3.large"
  cluster_name = "gwangju-eks-cluster"
}

data "aws_caller_identity" "current" {}

resource "aws_eks_cluster" "gwangju-skills" {
  name     = "${local.cluster_name}"
  version = "1.29"
  role_arn = aws_iam_role.gwangju-cluster.arn #"${var.cluster_role}"
  vpc_config {
    subnet_ids = [
      aws_subnet.gwangju-private_a.id, aws_subnet.gwangju-private_b.id,
      aws_subnet.gwangju-public_a.id, aws_subnet.gwangju-public_b.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids = [ aws_security_group.gwangju-control-plane.id ]
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.gwangju-cluster-default,
    aws_iam_role_policy_attachment.gwangju-vpc-resource-controller,
  ]
}

resource "aws_eks_access_entry" "gwangju-bastion-allow" { #EKS 클러스터에 대한 액세스 항목 구성
  cluster_name  = aws_eks_cluster.gwangju-skills.name
  principal_arn = "${var.admin_role_arn}"
  type          = "STANDARD"
  # depends_on = [
  #   aws_iam_role.EKS-bastion
  # ]
}

resource "aws_eks_access_policy_association" "gwangju-root-allow" { #EKS 클러스터에 대한 액세스 항목 정책 연결
  cluster_name  = aws_eks_cluster.gwangju-skills.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.gwangju-bastion-allow.principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [ aws_eks_access_entry.gwangju-bastion-allow ]
}

resource "aws_eks_access_policy_association" "gwangju-root-allow-AmazonEKSAdminPolicy" { #EKS 클러스터에 대한 액세스 항목 정책 연결
  cluster_name  = aws_eks_cluster.gwangju-skills.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_eks_access_entry.gwangju-bastion-allow.principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [ aws_eks_access_entry.gwangju-bastion-allow ]
}

resource "aws_eks_access_entry" "gwangju-console-allow" {
  cluster_name  = aws_eks_cluster.gwangju-skills.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  type          = "STANDARD"

  depends_on = [ aws_eks_access_policy_association.gwangju-root-allow ]
}

resource "aws_eks_access_policy_association" "gwangju-console-allow" {
  cluster_name  = aws_eks_cluster.gwangju-skills.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.gwangju-console-allow.principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [ aws_eks_access_entry.gwangju-console-allow ]
}

resource "aws_eks_access_policy_association" "gwangju-console-allow-AmazonEKSAdminPolicy" { #EKS 클러스터에 대한 액세스 항목 정책 연결
  cluster_name  = aws_eks_cluster.gwangju-skills.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_eks_access_entry.gwangju-console-allow.principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [ aws_eks_access_entry.gwangju-console-allow ]
}

resource "aws_eks_addon" "gwangju-kube-proxy" {
  cluster_name = aws_eks_cluster.gwangju-skills.name
  addon_name   = "kube-proxy"
  addon_version = "v1.29.3-eksbuild.5"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "gwangju-coredns" {
  cluster_name = aws_eks_cluster.gwangju-skills.name
  addon_name   = "coredns"
  addon_version = "v1.11.1-eksbuild.4"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [ aws_eks_node_group.gwangju ]
}

resource "aws_eks_addon" "gwangju-vpc-cni" {
  cluster_name = aws_eks_cluster.gwangju-skills.name
  addon_name   = "vpc-cni"
  addon_version = "v1.16.0-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "gwangju-eks-pod-identity-agent" {
  cluster_name = aws_eks_cluster.gwangju-skills.name
  addon_name   = "eks-pod-identity-agent"
  addon_version = "v1.2.0-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"
}

data "tls_certificate" "gwangju-cluster" {
  url = aws_eks_cluster.gwangju-skills.identity[0].oidc[0].issuer
  }

resource "aws_security_group" "gwangju-control-plane" {
  name        = "gwangju-control-plane-sg"
  description = "Allow HTTPS traffic"
  vpc_id      = aws_vpc.gwangju-main.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
    tags = {
        Name = "control-plane-sg"
    }
}

resource "aws_iam_openid_connect_provider" "gwangju-eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.gwangju-cluster.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.gwangju-cluster.url
}

resource "random_string" "gwangju-random_role" {
  length           = 5
  upper   = false
  lower   = false
  numeric  = true
  special = false
}

data "aws_iam_policy_document" "gwangju-cluster" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "gwangju-cluster" {
  name               = "eksClusterRole${random_string.gwangju-random_role.result}"
  assume_role_policy = data.aws_iam_policy_document.gwangju-cluster.json
}

resource "aws_iam_role_policy_attachment" "gwangju-cluster-default" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.gwangju-cluster.name
}

resource "aws_iam_role_policy_attachment" "gwangju-vpc-resource-controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.gwangju-cluster.name
}
locals {
  instance_type = "c5.large"
  cluster_name = "wsi-eks-cluster"
}

data "aws_caller_identity" "daejeon-current" {}

resource "aws_eks_cluster" "daejeon-skills" {
  name     = "${local.cluster_name}"
  version = "1.29"
  role_arn = aws_iam_role.daejeon-cluster.arn #"${var.cluster_role}"
  vpc_config {
    subnet_ids = [
      "${var.private_a}", "${var.private_b}",
      "${var.public_a}", "${var.public_b}"
    ]
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.daejeon-cluster-default,
    aws_iam_role_policy_attachment.daejeon-vpc-resource-controller,
  ]
}

resource "aws_eks_access_entry" "daejeon-bastion-allow" { #EKS 클러스터에 대한 액세스 항목 구성
  cluster_name  = aws_eks_cluster.daejeon-skills.name
  principal_arn = "${var.admin_role_arn}"
  type          = "STANDARD"
  # depends_on = [
  #   aws_iam_role.daejeon-bastion
  # ]
}

resource "aws_eks_access_policy_association" "daejeon-bastion-policy" { #EKS 클러스터에 대한 액세스 항목 정책 연결
  cluster_name  = aws_eks_cluster.daejeon-skills.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.daejeon-bastion-allow.principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [ aws_eks_access_entry.daejeon-bastion-allow ]
}

resource "aws_eks_access_policy_association" "daejeon-root-allow-AmazonEKSAdminPolicy" { #EKS 클러스터에 대한 액세스 항목 정책 연결
  cluster_name  = aws_eks_cluster.daejeon-skills.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_eks_access_entry.daejeon-bastion-allow.principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [ aws_eks_access_entry.daejeon-bastion-allow ]
}

resource "aws_eks_access_entry" "daejeon-console-allow" {
  cluster_name  = aws_eks_cluster.daejeon-skills.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.daejeon-current.account_id}:root"
  type          = "STANDARD"

  depends_on = [ aws_eks_access_policy_association.daejeon-bastion-policy ]
}

resource "aws_eks_access_policy_association" "daejeon-console-allow" {
  cluster_name  = aws_eks_cluster.daejeon-skills.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.daejeon-console-allow.principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [ aws_eks_access_entry.daejeon-console-allow ]
}

resource "aws_eks_access_policy_association" "daejeon-console-allow-AmazonEKSAdminPolicy" { #EKS 클러스터에 대한 액세스 항목 정책 연결
  cluster_name  = aws_eks_cluster.daejeon-skills.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_eks_access_entry.daejeon-console-allow.principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [ aws_eks_access_entry.daejeon-console-allow ]
}

resource "aws_eks_addon" "daejeon-kube-proxy" {
  cluster_name = aws_eks_cluster.daejeon-skills.name
  addon_name   = "kube-proxy"
  addon_version = "v1.29.3-eksbuild.5"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "daejeon-coredns" {
  cluster_name = aws_eks_cluster.daejeon-skills.name
  addon_name   = "coredns"
  addon_version = "v1.11.1-eksbuild.4"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [ aws_eks_node_group.daejeon ]
}

resource "aws_eks_addon" "daejeon-vpc-cni" {
  cluster_name = aws_eks_cluster.daejeon-skills.name
  addon_name   = "vpc-cni"
  addon_version = "v1.16.0-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "daejeon-eks-pod-identity-agent" {
  cluster_name = aws_eks_cluster.daejeon-skills.name
  addon_name   = "eks-pod-identity-agent"
  addon_version = "v1.2.0-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"
}

data "tls_certificate" "daejeon-cluster" {
  url = aws_eks_cluster.daejeon-skills.identity[0].oidc[0].issuer
  }

resource "aws_iam_openid_connect_provider" "daejeon-eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.daejeon-cluster.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.daejeon-cluster.url
}

resource "random_string" "daejeon-random_role" {
  length           = 5
  upper   = false
  lower   = false
  numeric  = true
  special = false
}

data "aws_iam_policy_document" "daejeon-cluster" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "daejeon-cluster" {
  name               = "eksClusterRole${random_string.daejeon-random_role.result}"
  assume_role_policy = data.aws_iam_policy_document.daejeon-cluster.json
}

resource "aws_iam_role_policy_attachment" "daejeon-cluster-default" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.daejeon-cluster.name
}

resource "aws_iam_role_policy_attachment" "daejeon-vpc-resource-controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.daejeon-cluster.name
}
resource "aws_eks_node_group" "daejeon" {
  cluster_name    = aws_eks_cluster.daejeon-skills.name
  node_group_name = "daejeon-logging-ng"
  node_role_arn   = aws_iam_role.daejeon-nodes.arn

  subnet_ids = [
    "${var.private_a}", "${var.private_b}"
  ]
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]
  # resources = [{
  #   "remote_access_security_group_id"=""
  # }]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 10
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    name    = aws_launch_template.daejeon.name
    version = aws_launch_template.daejeon.latest_version
  }

  depends_on = [
    aws_eks_access_policy_association.daejeon-console-allow
  ]
}

resource "aws_iam_role" "daejeon-nodes" {
  name = "AmazonEKSNodeRole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "daejeon-nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.daejeon-nodes.name
}

resource "aws_iam_role_policy_attachment" "daejeon-nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.daejeon-nodes.name
}

resource "aws_iam_role_policy_attachment" "daejeon-nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.daejeon-nodes.name
}

resource "aws_launch_template" "daejeon" {
  name = "daejeon-logging-ng"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "daejeon-logging-ng"
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 30
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
}
# busan_iam 모듈
variable "module_names" {
  description =  "The names of the modules to apply (busan_iam, busan_Governance, busan_CICD)"
  type        = list(string)
  default     = []
}

module "busan_iam" {
  source              = "./busan/1.IAM"
  aws_ami             = data.aws_ami.amazonlinux2023.id
  key_pair            = aws_key_pair.keypair.key_name
  admin_profile_name  = aws_iam_instance_profile.bastion.name
  providers = {
    aws = aws.main
  }
  count = contains(var.module_names, "busan_iam") ? 1 : 0
}

output "busan-wsi-project-user1" {
  value = length([for name in var.module_names : name if name == "busan_iam"]) > 0 ? module.busan_iam[0].user1_PASSWORD : ""
}

output "busan-wsi-project-user2" {
  value = length([for name in var.module_names : name if name == "busan_iam"]) > 0 ? module.busan_iam[0].user2_PASSWORD : ""
}

# busan_Governance 모듈
module "busan_Governance" {
  source              = "./busan/2.Governance"
  aws_ami             = data.aws_ami.amazonlinux2023.id
  key_pair            = aws_key_pair.keypair.key_name
  admin_profile_name  = aws_iam_instance_profile.bastion.name
  default_vpc         = aws_default_vpc.default.id
  default_az1         = aws_default_subnet.default_az1.id
  providers = {
    aws = aws.main
  }
  count = contains(var.module_names, "busan_Governance") ? 1 : 0
}

output "busan-gvn-user" {
  value = length([for name in var.module_names : name if name == "busan_Governance"]) > 0 ? module.busan_Governance[0].user_password : ""
  # value = module.busan_Governance[0].user_password
}

# busan_CICD 모듈
module "busan_CICD" {
  source              = "./busan/3.CICD"
  aws_ami             = data.aws_ami.amazonlinux2023.id
  key_pair            = aws_key_pair.keypair.key_name
  admin_profile_name  = aws_iam_instance_profile.bastion.name
  default_vpc         = aws_default_vpc.default.id
  default_az1         = aws_default_subnet.default_az1.id
  region              = "ap-northeast-2"
  providers = {
    aws = aws.main
  }
  count = contains(var.module_names, "busan_CICD") ? 1 : 0
}
module "chungnam_Governance" {
    source = "./Chungnam/1.Governance"
    aws_ami=data.aws_ami.amazonlinux2023.id
    admin_profile_name = aws_iam_instance_profile.bastion.name
    key_pair = aws_key_pair.keypair.key_name
    lambda_role = aws_iam_role.lambda.arn
    admin_role_arn = aws_iam_role.bastion.arn
    default_vpc = aws_default_vpc.default.id
    default_az1 = aws_default_subnet.default_az1.id
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "chungnam_Governance") ? 1 : 0
}

module "chungnam_CICD" {
    source = "./Chungnam/2.CICD"
    aws_ami=data.aws_ami.amazonlinux2023-us-west.id
    key_pair = aws_key_pair.keypair-us-west.key_name
    admin_profile_name = aws_iam_instance_profile.bastion.name
    lambda_role = aws_iam_role.lambda.arn
    admin_role_arn = aws_iam_role.bastion.arn
    region = "us-west-1"
    providers = {
      aws = aws.us-west-1
    }
  count = contains(var.module_names, "chungnam_CICD") ? 1 : 0
}

module "chungnam_network" {
    source = "./Chungnam/3.network"
    aws_ami=data.aws_ami.amazonlinux2023.id
    admin_profile_name = aws_iam_instance_profile.bastion.name
    key_pair = aws_key_pair.keypair.key_name
    lambda_role = aws_iam_role.lambda.arn
    admin_role_arn = aws_iam_role.bastion.arn
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "chungnam_network") ? 1 : 0
}

module "daejeon_serverless" {
    source = "./Daejeon/1.serverless"
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "daejeon_serverless") ? 1 : 0
}

##Config
module "AWS_config" {
    source = "./AWS_Config"
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "daejeon_Governance") || contains(var.module_names, "seoul_Governance") ? 1 : 0
}

module "daejeon_Governance" {
    source = "./Daejeon/2.Governance"
    aws_ami=data.aws_ami.amazonlinux2023.id
    key_pair = aws_key_pair.keypair.key_name
    admin_profile_name = aws_iam_instance_profile.bastion.name
    admin_role_arn = aws_iam_role.bastion.arn
    lambda_role = aws_iam_role.lambda.arn
    vpc = module.daejeon_vpc[0].aws_vpc
    public_a = module.daejeon_vpc[0].public_a
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "daejeon_Governance") ? 1 : 0
}

module "daejeon_EKS" {
    source = "./Daejeon/3.EKS"
    aws_ami=data.aws_ami.amazonlinux2023.id
    key_pair = aws_key_pair.keypair.key_name
    admin_profile_name = aws_iam_instance_profile.bastion.name
    admin_role_arn = aws_iam_role.bastion.arn
    lambda_role = aws_iam_role.lambda.arn
    vpc = module.daejeon_vpc[0].aws_vpc
    public_a = module.daejeon_vpc[0].public_a
    public_b = module.daejeon_vpc[0].public_b
    private_a = module.daejeon_vpc[0].private_a
    private_b = module.daejeon_vpc[0].private_b
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "daejeon_EKS") ? 1 : 0
}

module "daejeon_vpc" {
  source = "./Daejeon/Daejeon-vpc"
  count = contains(var.module_names, "daejeon_Governance") || contains(var.module_names, "daejeon_EKS") ? 1 : 0
}

module "gwangju_Network" {
    source = "./gwangju/1.network"
    create_region = "ap-northeast-2"
    aws_ami=data.aws_ami.amazonlinux2023.id
    admin_profile_name = aws_iam_instance_profile.bastion.name
    admin_role_arn = aws_iam_role.bastion.arn
    key_pair = aws_key_pair.keypair.key_name
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "gwangju_Network") ? 1 : 0
}

module "gwangju_CICD" {
    source = "./gwangju/2.CICD"
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "gwangju_CICD") ? 1 : 0
}

module "gwangju_EKS" {
    source = "./gwangju/3.EKS"
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "gwangju_EKS") ? 1 : 0
}

module "gwangju_2_3_infra" {
    source = "./gwangju/2,3"
    aws_ami = data.aws_ami.amazonlinux2023.id
    key_pair = aws_key_pair.keypair.key_name
    admin_profile_name =aws_iam_instance_profile.bastion.name
    admin_role_arn = aws_iam_role.bastion.arn
    code_commmit = module.gwangju_CICD[0].code_commit
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "gwangju_CICD") || contains(var.module_names, "gwangju_EKS") ? 1 : 0
}

module "gyeongbuk_CICD" {
    source = "./gyeongbuk/1.CICD"
    vpc = module.gyeongbuk_ALL[0].vpc
    public_a = module.gyeongbuk_ALL[0].public_a
    public_b = module.gyeongbuk_ALL[0].public_b
    private_a = module.gyeongbuk_ALL[0].private_a
    private_b = module.gyeongbuk_ALL[0].private_b
    commit = module.gyeongbuk_ALL[0].commit
    commit_arn = module.gyeongbuk_ALL[0].commit_arn
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "gyeongbuk_CICD") ? 1 : 0
}

module "gyeongbuk_WAF" {
    source = "./gyeongbuk/2.WAF"
    aws_ami =data.aws_ami.amazonlinux2023.id
    key_pair = aws_key_pair.keypair.key_name
    vpc = module.gyeongbuk_ALL[0].vpc
    public_a = module.gyeongbuk_ALL[0].public_a
    public_b = module.gyeongbuk_ALL[0].public_b
    private_a = module.gyeongbuk_ALL[0].private_a
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "gyeongbuk_WAF") ? 1 : 0
}

module "gyeongbuk_Elastic_stack" {
    source = "./gyeongbuk/3.Elastic_stack"
    aws_ami =data.aws_ami.amazonlinux2023.id
    key_pair = aws_key_pair.keypair.key_name
    vpc = module.gyeongbuk_ALL[0].vpc
    private_a = module.gyeongbuk_ALL[0].private_a
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "gyeongbuk_Elastic_stack") ? 1 : 0
}

module "gyeongbuk_ALL" {
    source = "./gyeongbuk/ALL(vpc,ec2)"
    aws_ami =data.aws_ami.amazonlinux2023.id
    key_pair = aws_key_pair.keypair.key_name
    admin_profile_name =aws_iam_instance_profile.bastion.name
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "gyeongbuk_CICD") || contains(var.module_names, "gyeongbuk_WAF") || contains(var.module_names, "gyeongbuk_Elastic_stack")? 1 : 0
}

module "Jeju_Serverless" {
    source = "./Jeju/1.Serverless"
    aws_ami=data.aws_ami.amazonlinux2023.id
    key_pair = aws_key_pair.keypair.key_name
    admin_profile_name = aws_iam_instance_profile.bastion.name
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "Jeju_Serverless") ? 1 : 0
 }

module "Jeju_Governance" {
    source = "./Jeju/2.Governanace"
    aws_ami=data.aws_ami.amazonlinux2023.id
    key_pair = aws_key_pair.keypair.key_name
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "Jeju_Governanace") ? 1 : 0
 }

module "Jeju_secure_networking" {
    source = "./Jeju/3.Secure_networking"
    aws_ami=data.aws_ami.amazonlinux2023.id
    admin_profile_name = aws_iam_instance_profile.bastion.name
    admin_role_arn = aws_iam_role.bastion.arn
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "Jeju_Secure_networking") ? 1 : 0
 }

module "seoul_CDN" {
    source = "./Seoul/1.CDN"
    providers = {
      aws = aws.main
      aws.us-east-1 = aws.us-east-1
    }
  count = contains(var.module_names, "seoul_CDN") ? 1 : 0
}

module "seoul_Governance" {
    source = "./Seoul/2.Governance"
    aws_ami=data.aws_ami.amazonlinux2023.id
    key_pair = aws_key_pair.keypair.key_name
    admin_profile_name = aws_iam_instance_profile.bastion.name
    lambda_role = aws_iam_role.lambda.arn
    vpc = module.seoul_ALL[0].seoul_aws_vpc
    public_a = module.seoul_ALL[0].seoul_public_a
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "seoul_Governance") ? 1 : 0
}

module "seoul_IAM" {
    source = "./Seoul/3.IAM"
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "seoul_IAM") ? 1 : 0
}

module "seoul_ALL" {
    source = "./Seoul/ALL(vpc,ec2)"
    aws_ami = data.aws_ami.amazonlinux2023.id
    key_pair = aws_key_pair.keypair.key_name
    admin_profile_name = aws_iam_instance_profile.bastion.name
    providers = {
      aws = aws.main
    }
  count = contains(var.module_names, "seoul_CDN") || contains(var.module_names, "seoul_Governance") || contains(var.module_names, "seoul_IAM") ? 1 : 0
}

data "aws_ami" "amazonlinux2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*x86*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon's official account ID
}

data "aws_ami" "amazonlinux2023-us-west" {
  provider = aws.us-west-1
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*x86*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon's official account ID
}

### 주의 keypair와 IAM Role이 default profile을 기준으로 생성됨 ###
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

### keypair ###
resource "aws_key_pair" "keypair" {
  key_name = "key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "keypair" {
  content = tls_private_key.rsa.private_key_pem
  filename = "./key.pem"
}

resource "aws_key_pair" "keypair-us-west" {
  provider = aws.us-west-1
  key_name = "us-west"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "keypair-us-west" {
  content = tls_private_key.rsa.private_key_pem
  filename = "./us-west.pem"
}

resource "random_string" "iam_random" {
  length           = 4
  upper   = false
  lower   = true
  numeric  = false
  special = false
}

## IAM
resource "aws_iam_role" "bastion" {
  name = "wsi-role-bastion-${random_string.iam_random.result}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_iam_instance_profile" "bastion" {
  name = "wsi-profile-bastion-${random_string.iam_random.result}"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role" "lambda" {
  name = "lambda-role-${random_string.iam_random.result}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}
terraform {
  cloud {
    organization = "neon-nights"

    workspaces {
      name = "sd4133-infrastructure"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = local.region
}

# provider "kubernetes" {
#   host                   = module.computing.cluster_enpoint
#   cluster_ca_certificate = base64decode(module.computing.cluster_certificate_authority_data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     # This requires the awscli to be installed locally where Terraform is executed
#     args = ["eks", "get-token", "--cluster-name", module.computing.cluster_name]
#   }
# }

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  name   = "sd4133_aws"
  region = "ap-southeast-1"
  arn    = "567929707303"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  ecrs = toset(["backend", "frontend"])

  tags = {
    Example     = local.name
    GithubRepo  = "aragonbn90/sd4133_aws_infrastructure"
    Terraform   = "true"
    Environment = "dev"
  }
}


################################################################################
# Computing Module
################################################################################

module "computing" {
  source = "./modules/eks"
  vpc_id = module.networking.vpc_id
  name   = local.name

  instance_types        = ["t2.medium"]
  capacity_type         = "ON_DEMAND"
  desired_size          = 2
  max_size              = 4
  private_subnets       = module.networking.private_subnets
  intra_subnets         = module.networking.intra_subnets
  tags                  = local.tags
  key_arn               = module.kms.key_arn
  aws_iam_policy_arn    = aws_iam_policy.additional.arn
  aws_security_group_id = aws_security_group.additional.id

}

################################################################################
# Container Registry Module
################################################################################

module "ecr" {
  for_each         = local.ecrs
  source           = "./modules/ecr"
  repository_name  = "${local.name}_${each.value}"
  arn              = local.arn
  keep_last_images = 10
  tags             = local.tags
}


################################################################################
# Networking module
################################################################################

module "networking" {
  source = "./modules/vpc"
  cidr   = local.vpc_cidr
  azs    = local.azs

  name            = local.name
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]
  tags            = local.tags

}

resource "aws_security_group" "additional" {
  name_prefix = "${local.name}-additional"
  vpc_id      = module.networking.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  tags = merge(local.tags, { Name = "${local.name}-additional" })
}

resource "aws_iam_policy" "additional" {
  name = "${local.name}-additional"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

module "kms" {
  source                  = "./modules/kms"
  name                    = local.name
  aws_caller_identity_arn = data.aws_caller_identity.current.arn
  tags                    = local.tags
}

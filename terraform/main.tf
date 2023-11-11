terraform {
  cloud {
    organization = "sd4133"

    workspaces {
      name = "sd4133-aws-infrastructure"
    }

  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  name   = "sd4133-" + var.env
  region = "ap-southeast-1"
  arn    = "567929707303"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  ecrs = toset(["backend", "frontend"])

  tags = {
    github      = "aragonbn90/sd4133_aws_infrastructure"
    terraform   = "true"
    env         = var.env
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


################################################################################
# Networking, security module
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

module "kms" {
  source                  = "./modules/kms"
  prefix                  = "eks"
  name                    = local.name
  aws_caller_identity_arn = data.aws_caller_identity.current.arn
  tags                    = local.tags
}


################################################################################
# Computing Module
################################################################################

module "computing" {
  source = "./modules/eks"
  vpc_id = module.networking.vpc_id
  name   = local.name 

  instance_types        = var.instance_types
  capacity_type         = var.capacity_type
  min_size              = var.min_size
  desired_size          = var.desired_size
  max_size              = var.max_size
  private_subnets       = module.networking.private_subnets
  intra_subnets         = module.networking.intra_subnets
  tags                  = local.tags
  key_arn               = module.kms.key_arn
  create_ebs_csi_driver = true

}

################################################################################
# Container Registry Module
################################################################################

module "ecr" {
  for_each         = local.ecrs
  source           = "./modules/ecr"
  repository_name  = "${local.name}-${each.value}"
  arn              = local.arn
  keep_last_images = 10
  tags             = local.tags
}


module "ecr" {
  source          = "terraform-aws-modules/ecr/aws"
  version         = "1.6.0"
  repository_name = var.repository_name
  # repository_read_write_access_arns = ["arn:aws:iam::${var.arn}:role/terraform"]

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last ${var.keep_last_images} images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = var.keep_last_images
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_force_delete = true

  tags = var.tags
}


# data "aws_caller_identity" "current" {}
# data "aws_partition" "current" {}
# ################################################################################
# # ECR Registry
# ################################################################################

# data "aws_iam_policy_document" "registry" {
#   statement {
#     principals {
#       type        = "AWS"
#       identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
#     }

#     actions = [
#       "ecr:ReplicateImage",
#     ]

#     resources = [
#       module.ecr.repository_arn,
#     ]
#   }
# }

# module "ecr_registry" {
#   source = "terraform-aws-modules/ecr/aws"
#   version = "1.6.0"

#   create_repository = false

#   # Registry Policy
#   create_registry_policy = true
#   registry_policy        = data.aws_iam_policy_document.registry.json

#   # Registry Pull Through Cache Rules
#   registry_pull_through_cache_rules = {
#     pub = {
#       ecr_repository_prefix = "ecr-public"
#       upstream_registry_url = "public.ecr.aws"
#     }
#   }

#   # Registry Scanning Configuration
#   manage_registry_scanning_configuration = true
#   registry_scan_type                     = "ENHANCED"
#   registry_scan_rules = [
#     {
#       scan_frequency = "SCAN_ON_PUSH"
#       filter         = "*"
#       filter_type    = "WILDCARD"
#       }, {
#       scan_frequency = "CONTINUOUS_SCAN"
#       filter         = "example"
#       filter_type    = "WILDCARD"
#     }
#   ]

#   # Registry Replication Configuration
#   create_registry_replication_configuration = true
#   registry_replication_rules = [
#     {
#       destinations = [{
#         region      = "us-west-2"
#         registry_id = data.aws_caller_identity.current.account_id
#         }, {
#         region      = "eu-west-1"
#         registry_id = data.aws_caller_identity.current.account_id
#       }]

#       repository_filters = [{
#         filter      = "prod-microservice"
#         filter_type = "PREFIX_MATCH"
#       }]
#     }
#   ]

#   tags = var.tags
# }

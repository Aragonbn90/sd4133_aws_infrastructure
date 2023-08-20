output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "pulic_subnets" {
  value = module.vpc.public_subnets
}

output "intra_subnets" {
  value = module.vpc.intra_subnets
}

# output "cluster_enpoint" {
#   value = module.vpc.cluster_endpoint_public_access
# }

# output "cluster_certificate_authority_data" {
#   value = module.vpc.cluser
# }


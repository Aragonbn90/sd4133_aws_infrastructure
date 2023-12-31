

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~>19.0"

  cluster_name                   = var.name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      preserve    = true
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = var.create_ebs_csi_driver ? {
      most_recent = true
    } : {}
  }

  # External encryption key
  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = var.key_arn
  }

  iam_role_additional_policies = {
    additional = aws_iam_policy.additional.arn
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.intra_subnets

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
  }

  # Self Managed Node Group(s)
  self_managed_node_group_defaults = (var.eks_type == "self_managed") ? {
    # vpc_security_group_ids = [aws_security_group.additional.id]
    # iam_role_additional_policies = {
    #   additional = aws_iam_policy.additional.arn
    # }

    # instance_refresh = {
    #   strategy = "Rolling"
    #   preferences = {
    #     min_healthy_percentage = 66
    #   }
    # }
  } : {}

  self_managed_node_groups = (var.eks_type == "self_managed") ? {
    # spot = {
    #   instance_type = "m5.large"
    #   instance_market_options = {
    #     market_type = "spot"
    #   }

    #   pre_bootstrap_user_data = <<-EOT
    #     echo "foo"
    #     export FOO=bar
    #   EOT

    #   bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

    #   post_bootstrap_user_data = <<-EOT
    #     cd /tmp
    #     sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    #     sudo systemctl enable amazon-ssm-agent
    #     sudo systemctl start amazon-ssm-agent
    #   EOT
    # }
  } : {}

  # EKS Managed Node Group(s)
  # eks_managed_node_group_defaults = (var.eks_type == "eks_managed") ? ({
  #   ami_type       = "${var.ami_type}"
  #   instance_types = "${var.instance_types}"

  #   attach_cluster_primary_security_group = true
  #   vpc_security_group_ids                = [aws_security_group.additional.id]
  #   iam_role_additional_policies = {
  #     additional               = aws_iam_policy.additional.arn
  #     AmazonEBSCSIDriverPolicy = var.create_ebs_csi_driver ? "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" : null
  #   }
  # }) : ({})
  eks_managed_node_group_defaults = {
    ami_type       = "${var.ami_type}"
    instance_types = "${var.instance_types}"

    attach_cluster_primary_security_group = true
    vpc_security_group_ids                = [aws_security_group.additional.id]
    iam_role_additional_policies = {
      additional               = aws_iam_policy.additional.arn
      AmazonEBSCSIDriverPolicy = var.create_ebs_csi_driver ? "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" : null
    }
  }

  # eks_managed_node_groups = (var.eks_type == "eks_managed") ? {
  eks_managed_node_groups = {
    # blue = {}
    green = {
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      instance_types = var.instance_types
      capacity_type  = var.capacity_type
      # labels = var.labels
      # tains = var.taints

      update_config = {
        max_unavailable_percentage = 33 # or set `max_unavailable`
      }

      tags = var.tags
    }
    # } : {}
  }

  # # Fargate Profile(s)
  fargate_profiles = (var.eks_type == "fargate") ? {
    #   defFault = {
    #     name = "default"
    #     selectors = [
    #       {
    #         namespace = "kube-system"
    #         labels = {
    #           k8s-app = "kube-dns"
    #         }
    #       },
    #       {
    #         namespace = "default"
    #       }
    #     ]

    #     tags = {
    #       Owner = "test"
    #     }

    #     timeouts = {
    #       create = "20m"
    #       delete = "20m"
    #     }
    #   }
  } : {}

  # Create a new cluster where both an identity provider and Fargate profile is created
  # will result in conflicts since only one can take place at a time
  # # OIDC Identity provider
  # cluster_identity_providers = {
  #   sts = {
  #     client_id = "sts.amazonaws.com"
  #   }
  # }

  # aws-auth configmap
  # manage_aws_auth_configmap = true

  # aws_auth_node_iam_role_arns_non_windows = [
  #   module.eks_managed_node_group.iam_role_arn,
  #   # module.self_managed_node_group.iam_role_arn,
  # ]
  # # aws_auth_fargate_profile_pod_execution_role_arns = [
  # #   module.fargate_profile.fargate_profile_pod_execution_role_arn
  # # ]

  # aws_auth_roles = [
  #   {
  #     rolearn  = module.eks_managed_node_group.iam_role_arn
  #     username = "system:node:{{EC2PrivateDNSName}}"
  #     groups = [
  #       "system:bootstrappers",
  #       "system:nodes",
  #     ]
  #   },
  #   # {
  #   #   rolearn  = module.self_managed_node_group.iam_role_arn
  #   #   username = "system:node:{{EC2PrivateDNSName}}"
  #   #   groups = [
  #   #     "system:bootstrappers",
  #   #     "system:nodes",
  #   #   ]
  #   # },
  #   # {
  #   #   rolearn  = module.fargate_profile.fargate_profile_pod_execution_role_arn
  #   #   username = "system:node:{{SessionName}}"
  #   #   groups = [
  #   #     "system:bootstrappers",
  #   #     "system:nodes",
  #   #     "system:node-proxier",
  #   #   ]
  #   # }
  # ]

  # aws_auth_users = [
  #   {
  #     userarn  = "arn:aws:iam::66666666666:user/user1"
  #     username = "user1"
  #     groups   = ["system:masters"]
  #   },
  #   {
  #     userarn  = "arn:aws:iam::66666666666:user/user2"
  #     username = "user2"
  #     groups   = ["system:masters"]
  #   },
  # ]

  # aws_auth_accounts = [
  #   "777777777777",
  #   "888888888888",
  # ]

  tags = var.tags
}

resource "aws_security_group" "additional" {
  name_prefix = "${var.name}-additional"
  vpc_id      = var.vpc_id

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

  tags = merge(var.tags, { Name = "${var.name}-additional" })
}

resource "aws_iam_policy" "additional" {
  name = "${var.name}-ec2-describe"

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

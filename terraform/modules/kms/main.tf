module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  aliases               = ["${var.prefix}/${var.name}"]
  description           = "${var.name} cluster encryption key"
  enable_default_policy = true
  key_owners            = [var.aws_caller_identity_arn]

  tags = var.tags
}

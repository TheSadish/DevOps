module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.0.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]

      min_size     = var.min_capacity
      max_size     = var.max_capacity
      desired_size = var.desired_capacity
    }  
  }

  tags = {
    Environment = "dev"
  }
}

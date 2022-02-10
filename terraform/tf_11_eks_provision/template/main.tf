provider "aws" {
  region = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name                 = "k8s-${var.cluster_name}-vpc"
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24"]
  public_subnets       = ["172.16.3.0/24", "172.16.4.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.24.0"

  cluster_name    = "${var.cluster_name}"
  cluster_version = "1.21"
  subnets         = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id
  write_kubeconfig   = true

  worker_groups = [
    {
        name = "ng-medium"
        instance_type = "t3.medium"
        asg_desired_capacity = 1
        tags = [{
          key                 = "instance-type"
          value               = "on-demand-medium"
          propagate_at_launch = true
        }, {
          key                 = "os-type"
          value               = "linux"
          propagate_at_launch = true
        }]
    },
  ]
}

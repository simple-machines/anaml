data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [
    module.eks.kubernetes_config_map
  ]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [
    module.eks.kubernetes_config_map
  ]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "anaml-eks"
  cluster_version = var.kubernetes_version

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    anaml = {
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3a.large"]
      labels = {
        node_pool = "anaml-app-pool"
      }
      additional_tags = {
        "k8s.io/cluster-autoscaler/node-template/label/node_pool" = "anaml-app-pool"
      }
    }
    spark = {
      capacity_type    = "SPOT"
      instance_types   = var.spark_instance_types
      desired_capacity = var.spark_asg_minimum_size_by_az * length(var.zones)
      min_capacity     = var.spark_asg_minimum_size_by_az * length(var.zones)
      max_capacity     = var.spark_asg_maximum_size_by_az * length(var.zones)
      public_ip        = true
      labels = {
        node_pool = "anaml-spark-pool"
      }
      additional_tags = {
        "k8s.io/cluster-autoscaler/node-template/label/node_pool" = "anaml-spark-pool"
      }
      taints = [
        {
          key    = "spark-only"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }


  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

}

# data "aws_iam_openid_connect_provider" "anaml_eks_cluster" {
#   url = module.eks.cluster_oidc_issuer_url
# }

# resource "aws_iam_openid_connect_provider" "anaml_eks_cluster" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = data.aws_iam_openid_connect_provider.anaml_eks_cluster.thumbprint_list
#   url             = module.eks.cluster_oidc_issuer_url
# }



resource "aws_iam_policy" "aws_load_balancer_controller_iam_policy" {
  name = "AnamlAWSLoadBalancerControllerIAMPolicy"

  # This taken straight from the AWS docs and is required for the loadbalancer controller
  # https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
  # curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.3/docs/install/iam_policy.json
  policy = file("${path.module}/_templates/aws_load_balancer_controller_iam_policy.json")
}

data "aws_caller_identity" "current" {}
resource "aws_iam_role" "aws_eks_load_balancer_controller_role" {
  name = "AnamlAmazonEKSLoadBalancerControllerRole"
  assume_role_policy = templatefile("${path.module}/_templates/load_balancer_role_trust_policy.json", {
    //substr removes 'https://' prefix
    oidcProviderUrl = substr(module.eks.cluster_oidc_issuer_url, 8, -1)
    accountId       = data.aws_caller_identity.current.account_id
  })
}

resource "aws_iam_role_policy_attachment" "aws_eks_load_balancer_controller_role_policy_attachment" {
  role       = aws_iam_role.aws_eks_load_balancer_controller_role.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller_iam_policy.arn
}

resource "kubernetes_service_account" "aws_load_balancer_controller_service_account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" : aws_iam_role.aws_eks_load_balancer_controller_role.arn
    }

  }
}

resource "helm_release" "aws_loadbalancer_controller" {
  name             = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = false
  chart            = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  version          = "1.6.2"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [
    kubernetes_service_account.aws_load_balancer_controller_service_account
  ]

}

resource "helm_release" "spot_termination_handler" {
  name       = "aws-node-termination-handler"
  chart      = "aws-node-termination-handler"
  repository = "https://aws.github.io/eks-charts/"
  version    = "0.21.0"
  namespace  = "kube-system"
}

resource "aws_eip" "nat_gw_elastic_ip" {
  domain = "vpc"

  tags = {
    Name            = "anaml-eks-nat-eip"
    iac_environment = var.iac_environment_tag
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "anaml-vpc"
  cidr = var.main_network_block
  azs  = data.aws_availability_zones.available.names

  private_subnets = [
    # this loop will create a one-line list as ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20", ...]
    # with a length depending on how many Zones are available
    for zone_id in data.aws_availability_zones.available.zone_ids :
    cidrsubnet(var.main_network_block, var.subnet_prefix_extension, tonumber(substr(zone_id, length(zone_id) - 1, 1)) - 1)
  ]

  public_subnets = [
    # this loop will create a one-line list as ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20", ...]
    # with a length depending on how many Zones are available
    # there is a zone Offset variable, to make sure no collisions are present with private subnet blocks
    for zone_id in data.aws_availability_zones.available.zone_ids :
    cidrsubnet(var.main_network_block, var.subnet_prefix_extension, tonumber(substr(zone_id, length(zone_id) - 1, 1)) + var.zone_offset - 1)
  ]

  # enable single NAT Gateway to save some money
  # WARNING: this could create a single point of failure, since we are creating a NAT Gateway in one AZ only
  # feel free to change these options if you need to ensure full Availability without the need of running 'terraform apply'
  # reference: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.44.0#nat-gateway-scenarios
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  reuse_nat_ips          = true
  external_nat_ip_ids    = [aws_eip.nat_gw_elastic_ip.id]

  enable_dns_support               = true
  enable_dns_hostnames             = true
  enable_dhcp_options              = true
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]


  # add VPC/Subnet tags required by EKS
  tags = {
    "kubernetes.io/cluster/anaml-eks" = "shared"
    iac_environment                   = var.iac_environment_tag
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/anaml-eks" = "shared"
    "kubernetes.io/role/elb"          = "1"
    iac_environment                   = var.iac_environment_tag
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/anaml-eks" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
    iac_environment                   = var.iac_environment_tag
  }
}

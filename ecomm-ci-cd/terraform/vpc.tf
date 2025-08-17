# Provider
provider "aws" {
    access_key = var.access_key
    secret_key = var.secret_key
    region = "us-east-1"
}

variable "access_key" {}
variable "secret_key" {}
variable "vpc_cidr" {}
variable "private_subnet_cidrs" {}
variable "public_subnet_cidrs" {}


# Get the availability zones in the current region
data "aws_availability_zones" "azs" {}

module "ecomm-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

   name = "ecomm-vpc"
   cidr = var.vpc_cidr

   azs = data.aws_availability_zones.azs.names
   private_subnets = var.private_subnet_cidrs
   public_subnets = var.public_subnet_cidrs

   enable_nat_gateway = true
   single_nat_gateway = true
   enable_vpn_gateway = true
   enable_dns_hostnames = true

   tags = {
    Terraform = "true"
    Environment = "dev"

    "kubernetes.io/cluster/ecomm-eks-cluster" = "shared"
   }


   public_subnet_tags = {
    "kubernetes.io/cluster/ecomm-eks-cluster" = "shared"
    "kubernetes.io/role/elb" = 1
   }


   private_subnet_tags = {
    "kubernetes.io/cluster/ecomm-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb" = 1
   }


}
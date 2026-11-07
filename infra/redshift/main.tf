terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      proyecto = "bookhive-lab7"
      grupo    = "7"
    }
  }
}

variable "sufijo" {
  type        = string
  description = "El MISMO sufijo usado en infra/datos (ej. g7-0711)"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Contraseña del usuario administrador (8+ caracteres con mayúscula, minúscula y número)"
}

locals {
  bucket_datos = "bookhive-lab-datos-${var.sufijo}"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

data "aws_route_tables" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = data.aws_vpc.default.id
  service_name      = "com.amazonaws.us-east-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.default.ids
  tags              = { Name = "lab-s3-gateway" }
}

resource "aws_iam_role" "redshift_s3" {
  name = "redshift-s3-lab"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = ["redshift.amazonaws.com", "redshift-serverless.amazonaws.com"] }
    }]
  })
}

resource "aws_iam_role_policy" "lectura_s3" {
  name = "lectura-s3-lab"
  role = aws_iam_role.redshift_s3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:GetBucketLocation", "s3:ListBucket"]
      Resource = [
        "arn:aws:s3:::${local.bucket_datos}",
        "arn:aws:s3:::${local.bucket_datos}/datos/*",
      ]
    }]
  })
}

resource "aws_redshiftserverless_namespace" "lab" {
  namespace_name       = "lab-bookhive-ns"
  db_name              = "dev"
  admin_username       = "awsuser"
  admin_user_password  = var.admin_password
  iam_roles            = [aws_iam_role.redshift_s3.arn]
  default_iam_role_arn = aws_iam_role.redshift_s3.arn
}

resource "aws_redshiftserverless_workgroup" "lab" {
  namespace_name      = aws_redshiftserverless_namespace.lab.namespace_name
  workgroup_name      = "lab-bookhive"
  base_capacity       = 4
  max_capacity        = 8
  publicly_accessible = false
  subnet_ids          = data.aws_subnets.default.ids
  security_group_ids  = [data.aws_security_group.default.id]

  depends_on = [aws_vpc_endpoint.s3]
}

resource "aws_redshiftserverless_usage_limit" "diario" {
  resource_arn  = aws_redshiftserverless_workgroup.lab.arn
  usage_type    = "serverless-compute"
  amount        = 4
  period        = "daily"
  breach_action = "deactivate"
}

output "workgroup" {
  value = aws_redshiftserverless_workgroup.lab.workgroup_name
}

output "rol_iam_arn" {
  value = aws_iam_role.redshift_s3.arn
}

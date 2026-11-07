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
  description = "Sufijo para el bucket S3"
}

resource "aws_s3_bucket" "datos" {
  bucket        = "bookhive-lab-datos-${var.sufijo}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket                  = aws_s3_bucket.datos.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "libros" {
  bucket = aws_s3_bucket.datos.id
  key    = "datos/libros/libros.csv"
  source = "${path.module}/../../datos/salida/libros/libros.csv"
  etag   = filemd5("${path.module}/../../datos/salida/libros/libros.csv")
}

resource "aws_s3_object" "sesiones" {
  bucket = aws_s3_bucket.datos.id
  key    = "datos/sesiones/sesiones_lectura.csv"
  source = "${path.module}/../../datos/salida/sesiones/sesiones_lectura.csv"
  etag   = filemd5("${path.module}/../../datos/salida/sesiones/sesiones_lectura.csv")
}

output "bucket_datos" {
  value = aws_s3_bucket.datos.bucket
}
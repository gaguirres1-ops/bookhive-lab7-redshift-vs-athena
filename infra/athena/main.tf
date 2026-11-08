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

locals {
  bucket_datos = "bookhive-lab-datos-${var.sufijo}"

  tablas = {
    libros = {
      carpeta = "libros"
      columnas = [
        { nombre = "book_id", tipo = "int" },
        { nombre = "titulo", tipo = "string" },
        { nombre = "genero", tipo = "string" },
        { nombre = "paginas_totales", tipo = "int" },
      ]
    }
    sesiones_lectura = {
      carpeta = "sesiones"
      columnas = [
        { nombre = "session_id", tipo = "bigint" },
        { nombre = "user_id", tipo = "int" },
        { nombre = "pais", tipo = "string" },
        { nombre = "book_id", tipo = "int" },
        { nombre = "paginas_leidas", tipo = "int" },
        { nombre = "duracion_min", tipo = "int" },
        { nombre = "dispositivo", tipo = "string" },
        { nombre = "inicio", tipo = "timestamp" },
      ]
    }
  }
}

resource "aws_s3_bucket" "resultados" {
  bucket        = "bookhive-lab-athena-res-${var.sufijo}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "resultados" {
  bucket                  = aws_s3_bucket.resultados.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_athena_workgroup" "lab" {
  name          = "lab-athena"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration = true
    bytes_scanned_cutoff_per_query  = 1073741824

    result_configuration {
      output_location = "s3://${aws_s3_bucket.resultados.bucket}/resultados/"
    }
  }
}

resource "aws_glue_catalog_database" "lab" {
  name = "bookhive_lab"
}

resource "aws_glue_catalog_table" "tabla" {
  for_each      = local.tablas
  name          = each.key
  database_name = aws_glue_catalog_database.lab.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                 = "TRUE"
    classification           = "csv"
    "skip.header.line.count" = "1"
  }

  storage_descriptor {
    location      = "s3://${local.bucket_datos}/datos/${each.value.carpeta}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim" = ","
      }
    }

    dynamic "columns" {
      for_each = each.value.columnas
      content {
        name = columns.value.nombre
        type = columns.value.tipo
      }
    }
  }
}

output "workgroup" {
  value = aws_athena_workgroup.lab.name
}

output "base_de_datos" {
  value = aws_glue_catalog_database.lab.name
}
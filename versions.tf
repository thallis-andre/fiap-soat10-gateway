terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "tfstate-fiap-soat10-f4"
    key    = "global/s3/gtw.tfstate"
    region = "us-east-1"
  }
}

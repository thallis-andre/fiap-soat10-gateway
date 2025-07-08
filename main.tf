resource "aws_apigatewayv2_api" "fiap_food" {
  name          = "fiap_food"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.fiap_food.id
  name        = "dev"
  auto_deploy = true
}


data "terraform_remote_state" "fiap_food_eks" {
  backend = "s3"
  config = {
    bucket = "tfstate-fiap-soat10-f4"
    key    = "global/s3/eks.tfstate"
    region = "us-east-1"
  }
}

resource "aws_security_group" "vpc_link" {
  name   = "fiap-food-k8s-vpc-link"
  vpc_id = data.terraform_remote_state.fiap_food_eks.outputs.fiap_food_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_apigatewayv2_vpc_link" "fiap_food_eks" {
  name = "fiap-food-eks"

  security_group_ids = [
    aws_security_group.vpc_link.id
  ]

  subnet_ids = [
    data.terraform_remote_state.fiap_food_eks.outputs.fiap_food_priv_subnet_1a_id,
    data.terraform_remote_state.fiap_food_eks.outputs.fiap_food_priv_subnet_1b_id,
  ]
}

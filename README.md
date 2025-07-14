# FIAP Food Gateway - API Gateway AWS

## 📋 Descrição

Este repositório contém a infraestrutura como código (IaC) para provisionar um API Gateway na AWS, responsável por centralizar o acesso a todos os microsserviços da aplicação FIAP Food, incluindo a Lambda de autenticação e os serviços no EKS.

### Responsabilidades
- Provisionar API Gateway na AWS
- Configurar mapeamentos para Lambda (Identity Service)
- Configurar mapeamentos para microsserviços no EKS
- Gerenciar autenticação e autorização
- Configurar CORS e rate limiting

## 🏗️ Arquitetura

### Tecnologias Utilizadas
- **IaC**: Terraform
- **Gateway**: AWS API Gateway (REST API)
- **Autenticação**: AWS Cognito
- **Lambda**: Serverless identity service
- **EKS**: Microsserviços containerizados
- **DNS**: Route 53 (opcional)

### Componentes Integrados
- **Lambda Function**: FiapFoodIdentity (autenticação)
- **EKS Services**: Orders, Payments, Preparation
- **Load Balancer**: Application Load Balancer (ALB)
- **Cognito**: Identity Provider

## 🗺️ Mapeamentos de Rotas

### Estrutura de Rotas
```
/api
├── /auth
│   ├── POST /signin     → Lambda (FiapFoodIdentity)
│   ├── POST /signup     → Lambda (FiapFoodIdentity)
│   └── POST /refresh    → Lambda (FiapFoodIdentity)
├── /orders
│   ├── GET /orders      → EKS (Orders Service)
│   ├── POST /orders     → EKS (Orders Service)
│   ├── GET /orders/{id} → EKS (Orders Service)
│   └── PUT /orders/{id} → EKS (Orders Service)
├── /payments
│   ├── POST /payments   → EKS (Payments Service)
│   ├── GET /payments/{id} → EKS (Payments Service)
│   └── POST /webhooks/mercadopago → EKS (Payments Service)
└── /preparation
    ├── GET /preparation → EKS (Preparation Service)
    └── PUT /preparation/{id} → EKS (Preparation Service)
```

## 🔧 Configuração Terraform

### API Gateway Principal
```hcl
resource "aws_api_gateway_rest_api" "fiap_food_api" {
  name        = "fiap-food-api"
  description = "API Gateway for FIAP Food application"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "fiap_food_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.fiap_food_api.id
  stage_name  = "prod"
  
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.eks_integration
  ]
}
```

### Integração com Lambda (Identity Service)
```hcl
# Resource para /auth
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.fiap_food_api.id
  parent_id   = aws_api_gateway_rest_api.fiap_food_api.root_resource_id
  path_part   = "auth"
}

# Integração com Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.fiap_food_api.id
  resource_id = aws_api_gateway_resource.auth.id
  http_method = aws_api_gateway_method.auth_method.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.identity_lambda.invoke_arn
}
```

### Integração com EKS (Microsserviços)
```hcl
# Resource para /orders
resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.fiap_food_api.id
  parent_id   = aws_api_gateway_rest_api.fiap_food_api.root_resource_id
  path_part   = "orders"
}

# Integração com EKS via ALB
resource "aws_api_gateway_integration" "eks_orders_integration" {
  rest_api_id = aws_api_gateway_rest_api.fiap_food_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.orders_method.http_method
  
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${data.aws_lb.eks_alb.dns_name}/orders/{proxy}"
}
```

## 🚀 Deploy e Configuração

### Pré-requisitos
- AWS CLI configurado
- Terraform >= 1.5.0
- Cluster EKS em execução
- Lambda de identity deployada

### Variáveis de Ambiente
```bash
# Configurar no arquivo .env ou terraform.tfvars
AWS_REGION=us-east-1
API_GATEWAY_NAME=fiap-food-api
LAMBDA_FUNCTION_NAME=fiap-food-identity
EKS_CLUSTER_NAME=fiap-food-cluster
COGNITO_USER_POOL_ID=<user_pool_id>
```

### Comandos de Deploy

```bash
# Inicializar Terraform
terraform init

# Planejar mudanças
terraform plan

# Aplicar infraestrutura
terraform apply

# Obter Load Balancers do EKS
aws elbv2 describe-load-balancers --query 'LoadBalancers[?Type==`application`].[LoadBalancerName,DNSName]' --output table
```

### Outputs Disponíveis
- `api_gateway_url`: URL base do API Gateway
- `api_gateway_execution_arn`: ARN de execução
- `api_gateway_id`: ID do API Gateway
- `stage_name`: Nome do stage (prod)

## 🔗 Descoberta de Load Balancers

### Comando para Descobrir ALB do EKS
```bash
# Listar todos os Load Balancers
aws elbv2 describe-load-balancers --query 'LoadBalancers[?Type==`application`].[LoadBalancerName,DNSName]' --output table

# Obter apenas os DNS Names
aws elbv2 describe-load-balancers --query 'LoadBalancers[?Type==`application`].DNSName' --output table

# Filtrar por tags específicas
aws elbv2 describe-load-balancers --query 'LoadBalancers[?Type==`application` && starts_with(LoadBalancerName, `k8s-fiapfood`)]'
```

### Integração Automática com EKS
```hcl
# Data source para descobrir o ALB automaticamente
data "aws_lb" "eks_alb" {
  tags = {
    "kubernetes.io/cluster/fiap-food-cluster" = "owned"
    "kubernetes.io/service-name" = "fiap-food/orders-service"
  }
}

# Usar o DNS name do ALB nas integrações
locals {
  alb_dns_name = data.aws_lb.eks_alb.dns_name
}
```

## 🔒 Segurança e Autenticação

### Cognito Authorizer
```hcl
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                   = "cognito-authorizer"
  rest_api_id           = aws_api_gateway_rest_api.fiap_food_api.id
  type                  = "COGNITO_USER_POOLS"
  provider_arns         = [aws_cognito_user_pool.fiap_food_pool.arn]
  identity_source       = "method.request.header.Authorization"
}
```

### CORS Configuration
```hcl
resource "aws_api_gateway_method" "cors_method" {
  rest_api_id   = aws_api_gateway_rest_api.fiap_food_api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors_integration" {
  rest_api_id = aws_api_gateway_rest_api.fiap_food_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.cors_method.http_method
  
  type = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "cors_response" {
  rest_api_id = aws_api_gateway_rest_api.fiap_food_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.cors_method.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}
```

## 📊 Monitoramento e Logs

### CloudWatch Metrics
- Request count
- Latency (P50, P90, P95)
- Error rate (4xx, 5xx)
- Integration latency

### Logs Configurados
```hcl
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.fiap_food_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.fiap_food_api.id
  stage_name    = "prod"
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}
```

## 🛠️ Rate Limiting e Throttling

### Usage Plans
```hcl
resource "aws_api_gateway_usage_plan" "fiap_food_usage_plan" {
  name = "fiap-food-usage-plan"
  
  api_stages {
    api_id = aws_api_gateway_rest_api.fiap_food_api.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }
  
  quota_settings {
    limit  = 10000
    period = "DAY"
  }
  
  throttle_settings {
    burst_limit = 100
    rate_limit  = 50
  }
}
```

## 🔄 CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Deploy API Gateway
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1
    
    - name: Deploy with Terraform
      run: |
        terraform init
        terraform plan
        terraform apply -auto-approve
```

## 📚 Endpoints de Exemplo

### Autenticação
```bash
# Sign up
curl -X POST https://<api-gateway-url>/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"name": "João Silva", "email": "joao@example.com", "cpf": "12345678901"}'

# Sign in
curl -X POST https://<api-gateway-url>/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"email": "joao@example.com", "password": "senha123"}'
```

### Pedidos
```bash
# Criar pedido
curl -X POST https://<api-gateway-url>/api/orders \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"customer_id": "123", "items": [{"item_id": "1", "quantity": 2}]}'

# Listar pedidos
curl -X GET https://<api-gateway-url>/api/orders \
  -H "Authorization: Bearer <token>"
```

## 📚 Documentação Adicional

Para ver a documentação completa do projeto, acesse: [FIAP Food Docs](https://github.com/thallis-andre/fiap-food-docs)

## 👨‍💻 Autor

- **Thallis André Faria Moreira** - RM360145
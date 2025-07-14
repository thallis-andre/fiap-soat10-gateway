# Tech Challenge FIAP Project

Este repositório contem o códido fonte Terraform utilizado para provisionar um APIGateway na AWS. Os mapeamentos necessários para acessar as aplicações FiapFoodIdentity(lambda), FiapFoodPayments, FiapFoodPreparation e FiapFoodOrder também são gerenciados por meio deste repositorio. Para ver a documentação do projeto, acessar a página da org no Github: [Link](https://github.com/thallis-andre/fiap-food-docs)

## Autor do Projeto SOAT10

- **Thallis André Faria Moreira** - RM360145

# Obter os Load Balancers criados pelos serviços Kubernetes
aws elbv2 describe-load-balancers --query 'LoadBalancers[?Type==`application`].[LoadBalancerName,DNSName]' --output table

# Ou para ver apenas os DNSNames
aws elbv2 describe-load-balancers --query 'LoadBalancers[?Type==`application`].DNSName' --output table
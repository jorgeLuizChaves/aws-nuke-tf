# AWS Nuke

Este projeto tem como objetivo implantar o AWS-Nuke em uma conta e permitir que seja possível fazer uma implantação do AWS Nuke e configurar para que o AWS-Nuke rode programado através de cronjob.

O que é o `aws-nuke` ? 

O aws-nuke é uma ferramenta que te auxilia na remoção de recursos AWS que não estão sendo utilizados.

# Casos de uso
- ambientes que são utilizado para testes e após a utilização podem ser destruídos para economizar no custos no fim do dia.
- Ambientes provisionados com a ferramenta `terraform` algumas vezes falham e alguns recursos ficam implantados e outros não, isso pode gerar uma bagunça na conta AWS, para evitar essa situação podemos rodar `aws-nuke` para que a conta fique sem nenhum recurso, assim mantendo organizada e sem gerar custo.

# Arquitetura da solução
![visão geral da arquitetura](config/architecture-overview.png)

# Como funciona
A solução foi implementada utilizando `IaC` (Infrastructure as Code) no caso terraform.

## requisitos
- uma conta AWS
- terraform

## Variáveis
- `project_name`: nome do projeto do codebuild.
- `region`: região aonde será implantada a solução.
- `aws_nuke_cron`: cronjob de execução do aws nuke.

## Implantação

Para executar a implatanção é necessário que o usuário que será utilizado para realizar a implantação tenha permissões necessárias.

```bash
$ terraform apply 
```


# Referências
- https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html
- https://github.com/aws-samples/aws-nuke-account-cleanser-example
- https://github.com/rebuy-de/aws-nuke


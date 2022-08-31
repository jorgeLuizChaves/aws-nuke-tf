# Filters
Para evitar que você corra o risco de remover um recurso importante quando o aws-nuke é executado, podemos utilizar os `filters`, os `filters` permitem que recursos que se encontram em uma determinada condição não sejam removidos, os filtros podem ser abranjentes ou bem específico como veremos a seguir.

## exemplos

### um recurso IAM User filtrado através do nome
```yaml
# a specific resource based by name
ACCOUNT:
  filters:
    IAMUser:
    - "my_iam_name"
```

### um recurso EC2 filtrado através de uma tag
```yaml
# a specific resource based by name
ACCOUNT:
  filters:
    EC2Instance:
    - property: "tag:DoNotNuke" #filter by tag
      value: "true"
```

### um recurso EC2 filtrado através de um atributo
```yaml
# a specific resource based by name
ACCOUNT:
  filters:
    IAMUserPolicyAttachment:
    - property: RoleName #filter by attribute
      value: "admin"
```


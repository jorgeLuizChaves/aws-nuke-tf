## Expressões cron

O cron é composto por seis campos, `0 7 ? * * *"`, que são separados por um espaço em branco

| Campo | Valores | Wildcards |
| ------ | ------ | ------ | 
| minutos | 0-59  | , - * /|
| Horas | 0-23  | , - * /|
| D.ay-of-month | 1-31  | , - * ? / L W|
| Mês | 1-12 ou JAN-DEZ  | , - * /|
| D.ay-of-week | 1-7 ou DOM-SÁB| , - * ? L #|
| Ano | 1970-2199 | , - * /|

Para saber mais como funciona a expressão cron, visite o link [eb-create-rule-schedule](https://docs.aws.amazon.com/pt_br/eventbridge/latest/userguide/eb-create-rule-schedule.html).
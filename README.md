# Перенос данных из Яндекс Директ в витрину Yandex Managed Service for ClickHouse®

С помощью этого сценария вы можете мигрировать данные из Яндекс Директ в Managed Service for ClickHouse® с использованием сервисов Cloud Functions, Object Storage и Data Transfer. Для этого:

1. Перенесите данные из Яндекс Директ в Object Storage с использованием Cloud Functions.
2. Перенесите данные из Object Storage в Managed Service for ClickHouse® с использованием Data Transfer.

Сценарий может быть выполнен в [Консоли Управления Yandex Cloud](https://console.cloud.yandex.ru) или с помощью Terraform. Для выполнения сценария вам потребуются файл [example-py.zip](example-py.zip) с кодом функции на Python.
Для выполнения сценария с помощью Terraform скачайте конфигурационный файл, [ya-direct-to-mch.tf](ya-direct-to-mch.tf). 

При выполнении сценария вы подготовите тестовые данные, создадите и активируете трансфер, проверите работоспособность трансфера, а затем, удалите данные и ресурсы, которые вам больше не потребуются. Подробное описание см. в [практическом руководстве](https://cloud.yandex.ru/ru/docs/data-transfer/tutorials/direct-to-mch).

Дополнительные материалы о Yandex Data Transfer:
* [Доступные трансферы](https://cloud.yandex.ru/docs/data-transfer/transfer-matrix)
* [Практические руководства](https://cloud.yandex.ru/docs/data-transfer/tutorials/)

# Praxe 2025 – demo
Spring Boot + Docker + Postgres + LocalStack + Testcontainers + k6

## Запуск
docker compose up -d postgres localstack
docker compose up -d app
curl http://localhost:8080/api/hello

## Тесты
.\gradlew.bat test

## Нагрузка
docker run --rm -v ${PWD}:/scripts grafana/k6 run /scripts/k6/hello.js

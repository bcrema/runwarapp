# Codex Agent Guide — backend

## Escopo
- Kotlin/Spring Boot backend (API, domínio, config de segurança, migrations).
- Não altere frontend ou iOS aqui.

## Stack e comandos
- Gradle wrapper: `./gradlew bootRun`, `./gradlew test`.
- Migrations via Flyway em `src/main/resources/db/migration`.
- Logs/config em `src/main/resources/application.yml`.

## Padrões
- Seguir estilos existentes (Kotlin + Spring idiomático).
- Use `rg` para busca; evite mexer em pacotes/namespaces (`com.runwar`) sem pedido explícito.
- Não renomeie variáveis/identificadores técnicos (tokens, DB names) sem aprovação.
- Sempre trabalhe em uma branch de feature separada da `main` e abra PR para revisão, evitando merges diretos.

## Testes
- Sempre garanta cobertura de testes e resultados passando para mudanças.
- Priorize `./gradlew test` para validar mudanças de código.

## Segurança/segredos
- Não comitar segredos; use `.env`/variáveis de ambiente.

## Checklist rápida antes de sair
- Código compila? Testes relevantes rodados?
- Config nova documentada em `backend/README.md` se necessário.

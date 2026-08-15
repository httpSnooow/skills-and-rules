---
name: explicar-decisao-tecnica
description: >-
  Explains the architectural motivation, design patterns, and trade-offs behind
  a coding decision. Use when introducing a design pattern, complex abstraction,
  or when asking 'why' a piece of code was structured a certain way.
---

# Explicar Decisão Técnica

## Quando aplicar

Quando a IA sugerir uma abstração (ex: Factory, Strategy, Dependency Injection, Middleware, Custom Hook) ou quando você solicitar uma explicação pedagógica de um trecho de código.

## Formato da Explicação

Ao introduzir um padrão ou estrutura avançada, forneça uma explicação concisa dividida em 3 pontos:

1. **O Problema:** Qual dor ou acoplamento este padrão está evitando?
2. **A Solução:** Como a estrutura escolhida resolve esse problema de forma elegante.
3. **Trade-off (O Custo):** Qual a complexidade adicionada e quando NÃO valeria a pena usar esse padrão.

## Exemplo de Abordagem

> **Por que usar Injeção de Dependência aqui?**
> - **Problema:** Se instanciarmos `new PostgresRepository()` direto no serviço, não conseguiremos testar o serviço sem subir um banco de dados real.
> - **Solução:** Passamos uma interface `UserRepository` como parâmetro, permitindo trocar o Postgres por um Mock nos testes.
> - **Trade-off:** Cria mais arquivos e interfaces no projeto, o que seria exagero para scripts simples.

## O que evitar

- Usar jargões acadêmicos sem dar um exemplo prático no próprio contexto do projeto.
- Criar abstrações sem explicar o motivo de elas existirem.

---
name: analisar-padroes
description: >-
  Searches the codebase for similar implementations before writing new code
  and aligns new work with existing architecture, naming, and shared utilities.
  Use when implementing a new feature, API, screen, hook, service, or refactor
  where consistency with the rest of the repository matters.
---

# Analisar padrões

## Quando aplicar

Antes de implementar algo novo (funcionalidade, endpoint, componente, hook, serviço, DTO, teste).

## Fluxo

1. **Definir o que é “similar”**: mesmo domínio (ex.: outro CRUD), mesma camada (ex.: outro controller), mesmo padrão de UI (ex.: lista com filtros).
2. **Buscar de forma ampla**: busca semântica (“How is X done?”) e, em seguida, busca exata por nomes conhecidos (pastas, sufixos como `Service`, `Controller`, `use*`).
3. **Ler 1–3 referências boas**: arquivos que já passaram em produção ou que o time usa como modelo.
4. **Extrair o padrão**: estrutura de pastas, convenção de nomes, tratamento de erro, tipos/DTOs, como testes estão organizados, uso de bibliotecas internas.
5. **Implementar espelhando o padrão**: reutilizar componentes, helpers e abstrações existentes; só introduzir algo novo quando não houver equivalente razoável.

## Checklist rápido

- [ ] Existe implementação parecida já no repositório?
- [ ] Nomes e pastas seguem o mesmo estilo das referências?
- [ ] Dá para reutilizar tipos, hooks, clients HTTP ou componentes em vez de duplicar?
- [ ] Se o stack tiver camadas (ex.: controller → service → repo), a nova peça encaixa na mesma ordem?

## O que evitar

- Inventar estrutura nova sem olhar o que já existe no mesmo módulo/time.
- Copiar um arquivo inteiro sem entender por que a referência foi feita assim (contexto pode diferir).

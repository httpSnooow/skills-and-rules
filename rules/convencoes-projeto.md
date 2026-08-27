# Convenções do Projeto Atual

> **Instrução ao agente:** Se este arquivo não estiver preenchido (os campos ainda contêm `[preencher: ...]`),
> pergunte ao usuário as convenções antes de qualquer geração de código que dependa delas.
> Não assuma convenções — pergunte.

Esta rule é um **placeholder ativo** — ela existe para ser preenchida por projeto e referenciada pelo `context.md` do `.ai/`. Cada projeto deve ter sua própria versão com as convenções específicas.

> **Instrução ao agente (pós-preenchimento):** Quando os campos acima estiverem preenchidos,
> aplique-os como restrições de geração de código:
> - Use o framework e runtime declarados em imports e dependências sugeridas.
> - Use o framework de testes declarado em qualquer arquivo de teste gerado.
> - Use o padrão de nomenclatura declarado em nomes de arquivos e variáveis.
> - Use o padrão de commit declarado em sugestões de mensagem de commit.
> - Se detectar conflito entre as convenções declaradas e o código existente no repositório,
>   sinalize em `## Observações fora do escopo` antes de continuar.

## Framework e runtime
- [preencher: ex. Node 20 + TypeScript 5.x + ESM]

## Framework de testes
- [preencher: ex. Vitest + Testing Library]

## Linter e formatter
- [preencher: ex. ESLint + Prettier, config em .eslintrc]

## Estrutura de branches
- [preencher: ex. main + feature/* + hotfix/*]

## Padrão de nomenclatura de arquivos
- [preencher: ex. kebab-case para arquivos, PascalCase para componentes]

## Padrão de commit
- [preencher: ex. Conventional Commits — feat/fix/docs/chore]

## Como rodar testes localmente
- [preencher: ex. `npm test` ou `pnpm run test:unit`]

## Onde ficam as env vars documentadas
- [preencher: ex. `.env.example` na raiz]

## Dependências obrigatórias do projeto
- [preencher: ex. React 19, Prisma 6, Zod 3]

## Padrão de tratamento de erro
- [preencher: ex. Result<T, E> / Either monad / exceções tipadas / Problem Details RFC 7807 / sealed class kotlin]

## Observações adicionais
- [preencher: qualquer convenção específica não coberta acima]

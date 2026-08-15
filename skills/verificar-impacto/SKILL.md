---
name: verificar-impacto
description: >-
  Finds usages of changed symbols (imports, references, tests) and checks that
  dependent flows still behave correctly after an edit. Use before considering
  a task done, before opening a PR, or after renames, signature changes, and
  shared utility edits.
---

# Verificar impacto

## Quando aplicar

Antes de concluir qualquer alteração que mude API pública: funções exportadas, classes, tipos compartilhados, constantes, rotas, props de componentes reutilizados, contratos de serviço.

## Fluxo

1. **Listar o que mudou**: símbolos renomeados, assinaturas, comportamento observável (retorno, exceção, side-effect).
2. **Rastrear usos**: busca por nome do símbolo e por caminhos de import (`from '.../foo'`, imports relativos). Incluir outros pacotes do monorepo se existirem.
3. **Priorizar superfícies críticas**: chamadas em produção, adaptadores, factories, testes automatizados, mocks que espelham o contrato.
4. **Validar**: onde o tipo ou contrato mudou, cada call site precisa compilar/rodar com a nova forma; onde o comportamento mudou, fluxos que dependiam do antigo precisam ser atualizados ou documentados.
5. **Rodar o que fizer sentido**: testes afetados, build do pacote, ou checagem de tipo no escopo mínimo necessário.
6. **Verificar impacto em runtime e configuração:**
   - **Feature flags:** se a funcionalidade alterada tem uma flag de feature, verificar se o comportamento antigo ainda é correto quando a flag está `false`.
   - **Variáveis de ambiente:** se a mudança depende de uma env var nova, documentá-la — quem não tiver a var configurada vai ter comportamento silenciosamente diferente.
   - **Configuração por ambiente:** o mesmo código que funciona em `development` pode falhar em `production` por diferenças de `NODE_ENV`, timeouts, ou limites de rate.

## Checklist rápido

- [ ] Todos os imports/referências ao símbolo alterado foram encontrados?
- [ ] Testes que importam ou instanciam o código alterado foram atualizados?
- [ ] Há indireção (re-export, barrel `index.ts`, injeção de dependência) que exige busca extra?
- [ ] Mudança em contrato compartilhado: todos os consumidores foram ajustados?
- [ ] A mudança afeta código sob feature flag? O caminho `flag=false` foi verificado?
- [ ] Foram introduzidas env vars novas? Estão documentadas no `.env.example` ou equivalente?

## O que evitar

- Considerar “pronto” só porque o arquivo editado está correto localmente.
- Ignorar strings dinâmicas ou reflexão se o projeto usar (buscar também por nome em configurações e templates).

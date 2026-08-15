---
name: debugar-root-cause
description: >-
  Systematic 4-phase debugging framework: hypothesis → minimum experiment →
  isolation → fix. Use when investigating a bug, unexpected behavior, failing
  test, or runtime error where the cause is not immediately obvious.
---

# Debugar Root Cause — Framework de Debugging em 4 Fases

## Quando aplicar

Ao receber um bug report, erro de runtime, teste falhando, ou comportamento inesperado sem causa óbvia. **Não aplicar** para erros triviais (typo, import faltando, variável undefined com causa visível).

## Fluxo obrigatório em 4 fases

### Fase 1 — Leitura e hipóteses (ANTES de qualquer mudança no código)

- Ler o stack trace ou log **completo** — não o resumo, a mensagem completa
- Identificar a linha exata do erro e o contexto ao redor (5 linhas antes e depois)
- Listar **2-3 hipóteses** ordenadas por probabilidade, explicando o raciocínio de cada uma
- Nunca começar pela hipótese mais complexa — começar pela mais simples e local

**Formato:**

```
## Hipóteses (ordenadas por probabilidade)

1. **[Mais provável]** O `userId` chega como `undefined` porque o middleware de auth
   não está executando antes deste handler — o erro está na ordem dos middlewares.
2. **[Possível]** A query usa `user_id` mas a coluna foi renomeada para `userId`
   na última migration.
3. **[Improvável]** Race condition entre duas requisições concorrentes no mesmo recurso.
```

### Fase 2 — Experimento mínimo

- Para cada hipótese, definir o **menor experimento** que a confirma ou refuta (ex: um `console.log` estratégico, uma asserção temporária, trocar um valor hardcoded para testar)
- O experimento deve ser **reversível** — nada que precise de rollback em produção
- Confirmar qual hipótese o experimento valida antes de avançar

### Fase 3 — Isolamento

- Uma vez identificada a causa, **reproduzir o bug no menor contexto possível** (um teste unitário isolado, se viável)
- Se não conseguir reproduzir em isolamento, a causa raiz **ainda não foi encontrada** — voltar à Fase 1
- Nunca considerar o bug "resolvido" sem reprodução controlada

### Fase 4 — Fix e validação

- Aplicar o fix **cirúrgico** na causa raiz (não no sintoma)
- Verificar que o experimento da Fase 2 agora passa
- **Adicionar um teste de regressão** que teria capturado esse bug antes
- Documentar no PR/commit: o que era, o que causou, o que foi corrigido (3 frases)

**Formato do commit:**

```
fix: corrigir cálculo de desconto para pedidos com cupom expirado

O desconto era aplicado mesmo com cupom expirado porque a validação de
data comparava `expireAt` com a data de criação do pedido em vez da data atual.

Teste de regressão adicionado: `describe('desconto com cupom expirado')`.
```

## O que evitar

- **"Mudar e ver se funciona"** sem hipótese — isso é debugging por chute
- Corrigir o **sintoma** sem confirmar a causa raiz (o bug volta de outra forma)
- Não adicionar teste de regressão após correção (o bug vai re-aparecer)
- Assumir que o bug está no código que você acabou de escrever — pode estar em uma dependência, configuração ou dado corrompido

## Checklist rápido

- [ ] A causa raiz foi identificada e documentada (não só o sintoma)?
- [ ] O fix é na causa, não no sintoma?
- [ ] Um teste de regressão foi adicionado?
- [ ] O commit/PR descreve o que era, o que causou, o que foi corrigido?

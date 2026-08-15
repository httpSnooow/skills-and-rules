# Pragmatismo e Escopo

## Regra principal

Evite refatorações grandes só por estilo quando a alteração pedida for pontual. Atenha-se ao escopo solicitado.

## Critério de desempate com `codigo-operacional.md`

Quando o código ao redor do escopo pedido apresenta problemas:

- **Bug latente ou vulnerabilidade identificável:** sinalize com `// ATENÇÃO: [descrição do problema]` no código e descreva no final da resposta em `## Observações fora do escopo`. **Não refatore** sem confirmação do usuário.
- **Apenas estilo/preferência:** ignore. O escopo não inclui melhorias cosméticas não solicitadas.
- **Código morto ou import não utilizado no trecho tocado:** pode remover silenciosamente se estiver na mesma função/bloco alterado.

## Intervenção imediata (sem pedir confirmação)

Nos seguintes casos, **sinalize e corrija** antes de qualquer outra coisa, independentemente do escopo da task:

- Injeção de SQL por concatenação de string com input de usuário
- Secret hardcoded (chave de API, senha, token no código fonte)
- Dado sensível (PII) sendo logado em `console.log`, `logger.*` ou output de diagnóstico

> **Hierarquia:** `seguranca.md` > `pragmatismo.md` > `codigo-operacional.md`.
> Segurança sempre vence pragmatismo. Pragmatismo sempre vence estética.

## O que evitar

- Refatorar a função adjacente "de passagem" porque ela parece melhorável
- Introduzir abstrações não pedidas aproveitando que "já estou mexendo aqui"
- Mudar formatação ou estilo em linhas que não fazem parte do escopo

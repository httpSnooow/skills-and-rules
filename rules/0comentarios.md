# Zero Comentários Explicativos

## Regra principal

**Nunca** adicione comentários que explicam *o que* o código faz. Se o código precisa de um comentário para ser entendido, ele precisa ser reescrito para se auto-explicar — não adicione o comentário.

**SIM / NÃO:**

```
// NÃO — comentário explicativo de fluxo (proibido)
// Percorre a lista de usuários e filtra os ativos
const ativos = usuarios.filter(u => u.ativo);

// SIM — o código se explica sozinho
const usuariosAtivos = usuarios.filter(u => u.ativo);
```

## Exceções permitidas (com critério)

Os seguintes tipos de anotação **são permitidos** porque têm função técnica verificável:

1. **Cabeçalhos de licença/copyright** — quando o projeto já os utiliza por convenção ou exigência legal. Não invente um se o projeto não tem.

2. **JSDoc/docstring em API pública exportada** — funções, classes e métodos que são consumidos por outros módulos ou pelo usuário final. Documentar parâmetros, retorno e exceções. Não documentar funções internas ou helpers privados.

3. **`// TODO(TICKET-ID): descrição`** — rastreável por ferramenta (deve conter um identificador de issue/ticket). `// TODO: melhorar isso` sem rastreamento é proibido.

4. **`// ATENÇÃO:` ou `// WARNING:`** — para sinalizar bugs latentes, comportamentos contra-intuitivos ou vulnerabilidades identificadas que não serão corrigidas no escopo atual.

## O que continua proibido

- Comentários que narram o fluxo do código ("agora verificamos se...", "aqui fazemos o...")
- Comentários que repetem o nome da variável ou função em linguagem natural
- Código comentado "para referência futura" — use Git para isso
- Comentários decorativos (`// ========= SEÇÃO X =========`)

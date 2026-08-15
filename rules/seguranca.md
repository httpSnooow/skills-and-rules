# Segurança — Hardening Defensivo por Padrão

> **Esta é a rule de maior prioridade.** Em caso de conflito com qualquer outra rule, `seguranca.md` vence.

## Regras permanentes (aplicar sempre, sem exceção)

### 1. Zero secrets no código

Nenhuma chave de API, token, senha, connection string ou URL com credencial no código fonte — nem em comentários, nem em testes, nem em seeds. Usar variáveis de ambiente ou secret manager.

Se precisar de um valor de exemplo, usar placeholder explícito: `YOUR_API_KEY_HERE`.

**SIM / NÃO:**

```
// NÃO
const apiKey = "sk-abc123def456";
const dbUrl = "postgres://admin:senha123@prod-db:5432/app";

// SIM
const apiKey = process.env.API_KEY;
const dbUrl = process.env.DATABASE_URL;
```

### 2. Zero PII em logs

Emails, CPFs, nomes completos, tokens de autenticação e dados financeiros **nunca** aparecem em `console.log`, `logger.*`, ou qualquer output de diagnóstico. Logar IDs opacos, não valores.

**SIM / NÃO:**

```
// NÃO
logger.info(`Usuário logado: ${user.email} — CPF: ${user.cpf}`);

// SIM
logger.info(`Usuário logado: userId=${user.id}`);
```

### 3. Queries com parâmetros

Nunca construir queries SQL, comandos shell, ou expressões LDAP/XPath por concatenação de string com input de usuário. Sempre usar prepared statements, ORMs com binding, ou funções de escape.

**SIM / NÃO:**

```
// NÃO — SQL injection
const query = `SELECT * FROM users WHERE id = '${userId}'`;

// SIM — prepared statement
const query = `SELECT * FROM users WHERE id = $1`;
const result = await db.query(query, [userId]);
```

### 4. Sanitização de output

Qualquer dado que vem de usuário e é renderizado em HTML deve ser sanitizado ou escaped antes. `innerHTML = userInput` é proibido sem sanitização explícita.

### 5. Dependências

Ao sugerir um pacote novo, verificar se tem histórico de CVE crítico nos últimos 12 meses e mencionar ao usuário. Preferir pacotes com manutenção ativa e downloads expressivos.

### 6. Mensagens de erro

Erros para o cliente **nunca** expõem stack traces, queries, paths internos ou detalhes de implementação. Log detalhado no servidor, mensagem genérica para o cliente.

**SIM / NÃO:**

```
// NÃO — expõe detalhes internos ao cliente
res.status(500).json({ error: err.stack, query: sqlQuery });

// SIM — log interno, resposta genérica
logger.error('Falha ao processar pedido', { orderId, error: err.message });
res.status(500).json({ error: 'Erro interno. Tente novamente.' });
```

### 7. CSRF (Cross-Site Request Forgery)

Endpoints que executam ações com side-effects (POST, PUT, DELETE, PATCH) em aplicações
web que utilizam cookies para autenticação **devem** exigir proteção anti-CSRF:
- Usar token anti-CSRF (ex: `csurf`, `django.middleware.csrf`) **ou**
- Definir `SameSite=Strict` ou `SameSite=Lax` nos cookies de sessão.

Nunca gerar um formulário HTML com ação de escrita sem proteção anti-CSRF em sistemas
que não são puramente APIs stateless (Bearer token).

### 8. IDOR (Insecure Direct Object Reference)

Nunca gerar código que acessa recurso por ID sem verificar que o usuário autenticado
**tem permissão** para acessar aquele recurso específico.

**SIM / NÃO:**

```
// NÃO — acessa o pedido diretamente sem checar propriedade
const pedido = await db.pedidos.findById(req.params.id);

// SIM — garante que o pedido pertence ao usuário autenticado
const pedido = await db.pedidos.findOne({
  id: req.params.id,
  userId: req.user.id // ← verificação de propriedade obrigatória
});
if (!pedido) throw new NotFoundError(); // não expor que existe mas não pertence
```

A regra: nunca confiar no ID vindo do cliente como prova de autorização.

### 9. Dependency Confusion Attack

Ao sugerir pacotes com escopo privado (ex: `@empresa/lib`, `@meu-org/utils`),
verificar e mencionar ao usuário:
- Se o pacote existe no registro público (npmjs.com, PyPI) com o mesmo nome, um atacante
  pode publicar uma versão maliciosa com número de versão maior e interceptar instalações.
- Recomendação: usar registro privado com `--registry` explícito, ou configurar
  `publishConfig` com `access: restricted` e garantir que o CI usa o registry correto.

## Proibição absoluta (intervenção imediata)

Nos seguintes casos, **sinalizar e corrigir antes de qualquer outra coisa**, independentemente do escopo da task. Não aguardar confirmação do usuário:

| Situação | Ação |
|----------|------|
| Secret hardcoded detectado | Sinalizar imediatamente, substituir por env var |
| PII em log detectado | Sinalizar imediatamente, substituir por ID opaco |
| SQL por concatenação com input não sanitizado | Sinalizar, não gerar o código assim |
| Acesso a recurso por ID sem verificação de propriedade (IDOR) | Sinalizar, adicionar verificação |
| Formulário POST sem proteção anti-CSRF em app com cookie auth | Sinalizar, adicionar proteção |

> **Hierarquia de rules:** `seguranca.md` > `pragmatismo.md` > `codigo-operacional.md` > demais rules.

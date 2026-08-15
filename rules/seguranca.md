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

## Proibição absoluta (intervenção imediata)

Nos seguintes casos, **sinalizar e corrigir antes de qualquer outra coisa**, independentemente do escopo da task. Não aguardar confirmação do usuário:

| Situação | Ação |
|----------|------|
| Secret hardcoded detectado | Sinalizar imediatamente, substituir por env var |
| PII em log detectado | Sinalizar imediatamente, substituir por ID opaco |
| SQL por concatenação com input não sanitizado | Sinalizar, não gerar o código assim |

> **Hierarquia de rules:** `seguranca.md` > `pragmatismo.md` > `codigo-operacional.md` > demais rules.

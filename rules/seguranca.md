# Segurança — Hardening Defensivo por Padrão

> **Esta é a rule de maior prioridade.** Em caso de conflito com qualquer outra rule, `seguranca.md` vence.

## Hierarquia Completa de Rules (ordem de precedência)

Em caso de conflito entre rules, respeitar esta ordem:

1. `seguranca.md` — segurança sempre vence tudo
2. `limites.md` — proibições absolutas de execução autônoma
3. `pragmatismo.md` — escopo e proporcionalidade de intervenção
4. `contratos-e-api-design.md` + `resiliencia-e-fallback.md` + `performance-e-escala.md` — qualidade técnica (mesmo nível)
5. `codigo-operacional.md` + `0comentarios.md` — estilo de código (mesmo nível)
6. `token-budget.md` + `fluxo-humano.md` + `ambiguidade.md` — comportamento interacional (mesmo nível)
7. `convencoes-projeto.md` — contexto específico do projeto ativo (pode sobrescrever itens do nível 5)

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

Ao sugerir um pacote novo, mencionar ao usuário que deve auditar o histórico de CVE antes de adotar (via `npm audit`, `snyk`, ou [nvd.nist.gov](https://nvd.nist.gov)). Preferir pacotes com manutenção ativa (último commit < 6 meses) e downloads expressivos. Se o pacote for substituto de um pacote conhecido como deprecated ou com CVE público reconhecido, sinalizar explicitamente.

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
- Usar token anti-CSRF (`django.middleware.csrf` para Django; `csrf-csrf` para Express/Node.js — **atenção: o pacote `csurf` está deprecated desde 2023 e não deve ser usado em projetos novos**) **ou**
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

### 10. SSRF (Server-Side Request Forgery)

Nunca gerar código que faz requests HTTP para URLs fornecidas diretamente por input de usuário sem validação.

**SIM / NÃO:**

```
// NÃO — qualquer URL que o usuário fornecer pode acessar serviços internos
async function importarDados(url) {
  return fetch(url); // http://169.254.169.254 (AWS metadata), http://localhost:8080/admin
}

// SIM — allowlist de hosts permitidos
const HOSTS_PERMITIDOS = new Set(['api.parceiro.com', 'data.fornecedor.com']);

async function importarDados(url) {
  const parsed = new URL(url);
  if (!HOSTS_PERMITIDOS.has(parsed.hostname)) {
    throw new ForbiddenError('Host não permitido');
  }
  return fetch(url);
}
```

### 11. Mass Assignment

Nunca gerar endpoints que mapeiam o body da request diretamente para uma entidade sem lista explícita de campos permitidos. Campos como `role`, `isAdmin`, `plano` podem ser sobrescritos.

**SIM / NÃO:**

```kotlin
// NÃO — Spring Boot: qualquer campo do JSON pode sobrescrever campos internos
@PutMapping("/users/{id}")
fun update(@RequestBody user: User): User = userRepo.save(user)

// SIM — DTO com apenas os campos editáveis pelo usuário
@PutMapping("/users/{id}")
fun update(@RequestBody dto: UserUpdateDto, @PathVariable id: UUID): User {
  val user = userRepo.findById(id).orElseThrow()
  user.nome = dto.nome
  user.email = dto.email
  // `role` e `isAdmin` não estão no DTO — não podem ser alterados via request
  return userRepo.save(user)
}
```

## Proibição absoluta (intervenção imediata)

Nos seguintes casos, **sinalizar e corrigir antes de qualquer outra coisa**, independentemente do escopo da task. Não aguardar confirmação do usuário:

| Situação | Ação |
|----------|------|
| Secret hardcoded detectado | Sinalizar imediatamente, substituir por env var |
| PII em log detectado | Sinalizar imediatamente, substituir por ID opaco |
| SQL por concatenação com input não sanitizado | Sinalizar, não gerar o código assim |
| Acesso a recurso por ID sem verificação de propriedade (IDOR) | Sinalizar, adicionar verificação |
| Formulário POST sem proteção anti-CSRF em app com cookie auth | Sinalizar, adicionar proteção |
| URL de usuário passada diretamente para fetch/HttpClient sem validação de host | Sinalizar SSRF, adicionar allowlist |
| @RequestBody mapeado diretamente para entidade com campos sensíveis (role, isAdmin) | Sinalizar mass assignment, criar DTO |

> **Hierarquia de rules:** `seguranca.md` > `pragmatismo.md` > `codigo-operacional.md` > demais rules.

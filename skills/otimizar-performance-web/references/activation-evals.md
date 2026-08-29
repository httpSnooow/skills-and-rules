# Activation Evals — `otimizar-performance-web`

Casos de teste para validar que a `description` da skill dispara nos contextos corretos e não dispara nos incorretos.

---

## Casos de Ativação Positiva (should_trigger = SIM)

| # | Query | should_trigger | Por que é um bom caso |
|---|---|---|---|
| P1 | "Tô com um endpoint `/orders` que tá demorando 4 segundos, consegue dar uma olhada?" | SIM | Sintoma claro de performance em endpoint — gatilho direto |
| P2 | "Escreve um service que busca todos os pedidos de um usuário com os dados do produto de cada item" | SIM | Iteração sobre resultados → N+1 quase certo; usuário não pediu "performance" |
| P3 | "Como faço paginação nessa rota de listagem de usuários?" | SIM | Paginação → avaliar OFFSET vs cursor |
| P4 | "Preciso conectar no banco de dados num handler do Express" | SIM | Criação de conexão → pool ausente |
| P5 | "Cria uma função que importa 50.000 registros de um CSV no banco" | SIM | Volume alto → bulk write obrigatório |
| P6 | "Tenho esse `for await` que chama a API do Stripe pra cada pedido" | SIM | I/O em loop sequencial → paralelismo + timeout |
| P7 | "Adiciona cache nessa rota de produto" | SIM | Cache → TTL + invalidação |
| P8 | "Como posso otimizar essa query? `SELECT * FROM orders WHERE user_id = $1`" | SIM | SELECT * + WHERE sem índice confirmado |
| P9 | "Minha aplicação Spring Boot fica sem conexões disponíveis sob carga" | SIM | Connection pool exausto → HikariCP config |

---

## Casos de Ativação Negativa (should_trigger = NÃO)

| # | Query | should_trigger | Por que é um bom near-miss |
|---|---|---|---|
| N1 | "Como implemento o padrão Strategy em Kotlin?" | NÃO | Design pattern puro sem I/O — similar em vocabulário mas diferente em domínio |
| N2 | "O bundle do meu React tá muito grande, como reduzo?" | NÃO | Frontend perf / bundle splitting — escopo explicitamente fora desta skill |
| N3 | "Escreve um teste unitário pra essa função de desconto" | NÃO | Sem I/O; teste puro de lógica de negócio |
| N4 | "Como adiciono uma nova coluna na tabela `users` sem downtime?" | NÃO | Migração de schema → `migracoes-zero-downtime` |
| N5 | "Adiciona logs estruturados nesse endpoint" | NÃO | Observabilidade → `observabilidade-e-telemetria` |
| N6 | "Cria uma migration pra criar a tabela `orders`" | NÃO | Schema design, não otimização de acesso |
| N7 | "Explica o que é um índice de banco de dados" | NÃO | Pergunta educacional — a skill executa, não ensina |
| N8 | "Meu LCP tá em 4 segundos no Lighthouse, como melhoro?" | NÃO | Core Web Vitals / frontend — fora do escopo |
| N9 | "Faz uma análise de segurança desse endpoint de login" | NÃO | Security review — sem overlap com performance de I/O |

---

## Casos Funcionais

### Casos Felizes

| Entrada | Comportamento esperado | Método de verificação |
|---|---|---|
| Código com loop `for (const order of orders) { await db.user.findUnique(...) }` | Emite `⚠️ N+1 detectado` e reescreve com `include` / JOIN antes de continuar | O output deve conter o warning e o código reescrito sem loop com query |
| Query `SELECT * FROM products WHERE category_id = $1` | Remove `*`, lista colunas explícitas, emite warning de índice ausente em `category_id` | Output não contém `SELECT *`; contém `⚠️ Índice ausente` |
| Pedido de endpoint paginado sem contexto de cursor | Gera cursor pagination com `hasMore` + `nextCursor`; não gera OFFSET | Output contém `WHERE id > :cursor`; não contém `OFFSET` |
| `new Pool(...)` dentro de handler de request | Emite warning e move pool para singleton de módulo | Warning presente; pool fora do handler no código gerado |

### Casos-Limite (Edge Cases)

| Entrada | Comportamento esperado | Método de verificação |
|---|---|---|
| Tabela com < 100 linhas onde N+1 teria impacto mínimo | Ainda sinaliza N+1 e reescreve — "vai ser rápido com poucos dados" não é justificativa | Output não contém N+1 mesmo para tabelas pequenas |
| Cache para dado de autorização sem TTL mencionado | Aplica TTL máximo de 60s e nota o risco de acesso indevido por até 60s | Output contém `EX 60` ou equivalente + nota sobre revogação |
| OFFSET pequeno (ex: `OFFSET 5`) em tabela de 50 linhas | Sinaliza o anti-padrão e sugere cursor, mas nota que o impacto é baixo neste volume | Warning presente, mas gradação do risco documentada |
| Usuário pede `SELECT *` explicitamente | Reescreve com colunas explícitas e explica por que; não atende a pedido diretamente | Output sem `SELECT *` + justificativa presente |

### Casos Adversariais

| Entrada | Comportamento esperado | Método de verificação |
|---|---|---|
| "Só precisa funcionar, pode gerar com N+1 mesmo" | Recusa e gera sem N+1 — a instrução da skill é não-negociável | Output sem N+1; pode mencionar que o padrão correto tem custo similar |
| "Não precisa de timeout, essa API nunca falha" | Gera com timeout de qualquer forma + nota de que timeout é obrigatório em produção | Output contém timeout; nota de risk presente |
| "Usa `SELECT *` que fica mais fácil de manter" | Listas colunas explícitas; explica o trade-off real vs. percebido de manutenibilidade | Output sem `SELECT *`; argumento contra-argumentado |

---

## Como Rodar os Evals

1. Para cada query da tabela de positivos, verificar se o modelo ativa o fluxo da skill (emite pelo menos um dos sinais: `⚠️ N+1 detectado`, `⚠️ Índice ausente`, reescreve com cursor, adiciona TTL, etc.)
2. Para cada query da tabela de negativos, verificar se o modelo responde sem aplicar o fluxo de performance (sem emitir warnings de N+1 ou índice desnecessariamente)
3. Se um caso negativo disparar a skill incorretamente → ajustar a `description` para torná-la mais específica (adicionar "does not activate for..." com o caso concreto)
4. Se um caso positivo não disparar → verificar se a `description` cobre o sinal de ativação; adicionar exemplo de paráfrase se necessário

**Critério de aprovação:** 100% dos positivos disparam + 100% dos negativos não disparam em 3 runs consecutivos.

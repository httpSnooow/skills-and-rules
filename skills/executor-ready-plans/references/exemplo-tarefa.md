# Exemplo de tarefa: ruim vs. bom

Fixtures executáveis em `evals/fixtures/`. O linter deve reprovar o ruim e aprovar o bom.

## A Tarefa 0 (obrigatória no início)

Toda tarefa 0 de pré-checagem deve seguir este modelo (para inicializar PROGRESS.md fora do git e garantir o commit base):

```
### Tarefa 0 — Pré-checagem do estado base
Cobre: nenhum (pré-checagem)
Depende de: nenhuma
Arquivos: nenhum (PROGRESS.md é local e excluído do git, passo 4)
Passos: 1. Rode `git rev-parse --short HEAD`. 2. Rode `git status --short`. 3. Rode `pytest -q`. 4. Rode `echo PROGRESS.md >> .git/info/exclude` e crie `PROGRESS.md` vazio.
Verificação: HEAD = `abc1234`; status vazio; `0 passed`
Pronto quando: os três resultados coincidem e `git status --short` continua vazio
Commit: nenhum
Se falhar: Protocolo de execução do cabeçalho
```

## Ruim (reprove)
```
### Tarefa 3 — Adicionar validação e tratamento de erros no cadastro (similar à Tarefa 2)
Implemente a lógica apropriada e adicione os testes necessários, etc.
```
Falhas: dois comportamentos no título; "similar à"; sem arquivos, sem assinaturas, sem verificação, sem "pronto quando"; placeholders ("apropriada", "etc.").

## Bom
```
### Tarefa 3 — Rejeitar cadastro com e-mail duplicado
Cobre: R1.AC3 (SE o e-mail normalizado já existir ENTÃO o sistema DEVE levantar EmailDuplicadoError e não alterar o repositório)
Depende de: Tarefa 2
Arquivos: modificar `src/usuarios.py` (âncora: `def cadastrar`) | modificar `tests/test_usuarios.py` (final do arquivo)
Consome: `cadastrar(repo: dict[str, str], email: str, nome: str) -> str` (Tarefa 2, sem checagem de duplicidade)
Produz: `class EmailDuplicadoError(Exception)` em `src/usuarios.py`; `cadastrar` passa a levantá-la

Passos:
1. Em `src/usuarios.py`, acima de `def cadastrar`, adicione:
   ```python
   class EmailDuplicadoError(Exception):
       pass
   ```
2. Ao final de `tests/test_usuarios.py`, adicione (e acrescente `EmailDuplicadoError` ao import existente de `src.usuarios`):
   ```python
   def test_email_duplicado_levanta_erro_sem_alterar_repo():
       repo = {"ana@exemplo.com": "Ana"}
       with pytest.raises(EmailDuplicadoError):
           cadastrar(repo, "ANA@exemplo.com", "Outra")
       assert repo == {"ana@exemplo.com": "Ana"}
   ```
3. Rode `pytest tests/test_usuarios.py::test_email_duplicado_levanta_erro_sem_alterar_repo -q` → esperado: FALHA com `DID NOT RAISE`.
4. Em `cadastrar`, depois de `chave = email.strip().lower()`, adicione:
   ```python
   if chave in repo:
       raise EmailDuplicadoError(chave)
   ```

Verificação: `pytest -q` → esperado: `2 passed`
Pronto quando: o teste novo passa e o teste da Tarefa 2 continua passando
Commit: `feat(usuarios): rejeita e-mail duplicado`
Se falhar: Protocolo de execução do cabeçalho (uma correção de import, depois PARE e reporte)
```

Por que é bom: uma mudança de comportamento; falha esperada informada (vermelho pelo motivo certo); assert escrito à mão; âncora em vez de número de linha; Consome/Produz com assinaturas exatas; verificação com saída esperada.

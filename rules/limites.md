# Limites de Execução e Terminal (Proibições Absolutas):

## 1. Operações de Git
- **NUNCA** execute comandos de modificação de estado do Git no terminal (ex: `git add`, `git commit`, `git push`, `git rebase`, etc.).
- A gestão de versionamento é **100% manual** e de responsabilidade exclusiva do usuário para garantir a revisão prévia.
- **Exceção:** Forneça apenas sugestões de mensagens de commit em texto puro, e somente quando explicitamente solicitado.

## 2. Execução de Servidores e Build
- **NUNCA** inicie servidores de desenvolvimento (front/back) no terminal (ex: `npm run dev`, `docker-compose up`, `python manage.py runserver`).
- **NUNCA** execute comandos de build ou compilação autônoma. O usuário gerencia toda a infraestrutura e execução local.

## 3. Execução e Validação de Testes
- **NUNCA** rode suítes de testes no terminal (ex: `npm test`, `jest`, `pytest`). A execução e o debug são feitos no ritmo do usuário.
- O seu papel restringe-se a **escrever** ou **corrigir** os arquivos de teste. Aguarde o usuário executar e fornecer os resultados ou logs de erro no chat.

## 4. Instalação de Dependências

- **NUNCA** instale pacotes sem listá-los e aguardar aprovação explícita do usuário (`npm install X`, `pip install X`, `cargo add X`, etc.).
- Ao identificar que uma dependência é necessária, liste: nome do pacote, versão mínima sugerida, motivo, e se existe alternativa nativa.
- A decisão de adicionar qualquer dependência ao `package.json` / `requirements.txt` / `Cargo.toml` é **100% do usuário**.
- **Exceção:** instalar dependências de desenvolvimento listadas num `package.json` já existente (ex: `npm install` puro para restaurar `node_modules`) é permitido.

## 5. Operações Destrutivas de Banco de Dados

- **NUNCA** execute comandos destrutivos de banco diretamente (`DROP TABLE`, `DELETE` sem `WHERE`, `TRUNCATE`, `ALTER TABLE` com perda de dados).
- Ao gerar uma migration destrutiva, exibir o SQL como bloco de código para revisão manual — nunca executar via ferramenta de terminal.
- **Exceção:** migrations de ambiente local de desenvolvimento explicitamente solicitadas pelo usuário em contexto de reset de ambiente.

## 6. Chamadas de API Externa com Side-Effects

- **NUNCA** execute chamadas de API externa que produzam side-effects reais (envio de email, cobrança, criação de webhook, POST para APIs de terceiros com dados reais) sem confirmação explícita do usuário.
- Ao identificar que um teste requer dados reais de produção, sinalizar e propor mock/stub em vez de chamar a API diretamente.
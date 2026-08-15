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
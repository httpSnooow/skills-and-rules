# EARS e dimensionamento (consulta sob demanda)

## Padrões EARS (Mavin et al., 2009; rótulos PT ↔ WHEN/THEN/IF/WHILE/WHERE)

- Ubíquo: `O sistema DEVE <resposta>`
- Evento: `QUANDO <evento> ENTÃO o sistema DEVE <resposta>`
- Estado: `ENQUANTO <estado> o sistema DEVE <resposta>`
- Comportamento indesejado: `SE <condição de erro> ENTÃO o sistema DEVE <resposta>`
- Opcional: `ONDE <funcionalidade presente> o sistema DEVE <resposta>`
- Complexo: `ENQUANTO <estado>, QUANDO <evento> ENTÃO o sistema DEVE <resposta>`

Todo requisito tem ao menos um critério de caminho feliz **e** um de erro ou limite. Requisito não funcional relevante vira critério com limiar numérico verificável por comando (ex.: `p95 < 200 ms com 100 req/s`).

## Como adaptar ao tamanho da mudança

- **Pequena (1 a 3 tarefas)**: cabeçalho enxuto, mas preserve Tarefa 0, verificação e protocolo de execução.
- **Feature média**: aplique tudo.
- **Feature grande ou vários subsistemas**: divida em vários planos independentes, cada um entregando algo testável, e use um plano-índice com a ordem.
- **Correção de bug**: comece com a tarefa que reproduz o bug em um teste falhando; depois a correção mínima.

## Dimensionamento

- **Capacidade do executor:** plano + arquivos citados devem ocupar ≤50% da janela. Heurística sem fonte pública: calibre com seus dados. Se não couber, divida em planos independentes com plano-índice.
- **Nível de detalhe:** quanto menos capaz o executor, mais código literal. Para executor forte, troque código trivial por assinatura + critério de teste e declare o nível no cabeçalho.
- **Paralelismo:** por padrão, sequencial. Marque `Paralelizável com: Tarefa X` só se os arquivos forem disjuntos e nenhuma das duas consumir o que a outra produz.

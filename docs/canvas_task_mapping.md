# Mapeamento Canvas -> Bot

Este bot nao chama a API do Canvas diretamente. Ele le a tabela `tasks` no Supabase (dados ja sincronizados do Canvas).

## Campos usados da tabela `tasks`

- `nome`: titulo da atividade no Canvas.
- `id_disciplina`: disciplina associada.
- `situacao`: status textual sincronizado (ex.: `Pendente`, `Atrasada (Nao entregue)`, `Nota: 29.6/37`).
- `data_fim`: prazo da atividade (base para vencida/hoje/semana).
- `data_entrega`: data/hora de envio (quando existe, atividade e tratada como concluida).
- `nota` / `nota_maxima`: pontuacao (apoio para prioridade e leitura humana).
- `canvas_id` / `link_canvas`: referencia da atividade no Canvas.

## Regras de status no bot

1. `done=true` quando:
- `data_entrega` existe; ou
- `situacao` inicia com `nota:`; ou
- `situacao` contem marcadores de conclusao (`conclu`, `corrigida`, `finalizada`, `avaliada`, `entregue`) sem `nao entregue`.

2. `pending=true` quando `situacao` contem:
- `pendente`, `nao entregue`, `atrasada` (e nao estiver concluida).

3. `in_progress=true` quando `situacao` contem:
- `andamento`, `em andamento`, `em progresso` (e nao estiver concluida).

4. Classificacao por prazo (somente para tarefas nao concluidas com `data_fim` valida):
- `vencida`: `data_fim < hoje` (ou hint textual de atrasada com `data_fim <= hoje`);
- `hoje`: `data_fim == hoje`;
- `semana`: `hoje < data_fim <= hoje+7`.

## Erro comum evitado por este mapeamento

- Tarefa com `situacao = "Nota: ..."` e `data_fim` antiga nao deve aparecer como vencida.
- Tarefa com `situacao = "Atrasada (Nao entregue)"` nao pode ser tratada como concluida so por conter a palavra `entregue`.

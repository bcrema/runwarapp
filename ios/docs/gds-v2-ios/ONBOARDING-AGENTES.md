# Onboarding de Agentes - GDS v2.0 iOS Quadras

## Objetivo
Fornecer prompts curtos para execucao paralela por varios agentes com escopo fechado, dependencia clara e qualidade consistente.

## Regras gerais
1. Ler primeiro:
   - `ios/docs/gds-v2-ios/00-decisoes-v2-ios.md`
   - `ios/docs/gds-v2-ios/README.md`
   - `ios/docs/gds-v2-ios/TAREFAS-AGENTES.md`
   - `ios/docs/gds-v2-ios/STATUS.md`
2. Trabalhar apenas no passo atribuido.
3. Nao alterar backend.
4. Incluir testes da propria etapa.
5. Atualizar `STATUS.md` ao iniciar e concluir.
6. Padrao obrigatorio: `1 agente = 1 branch = 1 worktree`.

## Setup worktree (exemplo)
1. Na raiz do repo:
   - `cd [repo-principal]`
2. Criar worktree por passo/agente:
   - `git worktree add ../runwarapp-wt-v2-01 -b feat/ios-v2-01-contrato-quadra`
   - `git worktree add ../runwarapp-wt-v2-02 -b feat/ios-v2-02-mapa-quadras`
   - `git worktree add ../runwarapp-wt-v2-03 -b feat/ios-v2-03-elegibilidade`
3. Entrar no worktree e validar:
   - `git rev-parse --abbrev-ref HEAD`
   - `pwd`

## Prompt base (copiar para qualquer agente)
```text
Voce e o dono do passo <PASSO>. Execute somente o que esta em ios/docs/gds-v2-ios/<ARQUIVO-DO-PASSO>.

Regras:
1) Nao alterar backend.
2) Cumprir criterios de pronto e testes do passo.
3) Trabalhar em worktree dedicado e branch dedicada.
4) Se houver bloqueio, registrar em ios/docs/gds-v2-ios/STATUS.md e parar.
5) Ao concluir, registrar no STATUS.md:
   - status
   - resumo tecnico
   - branch/worktree
   - comandos de teste e resultado
```

## Prompt por agente

### Agente iOS API/Domain (`01`)
```text
Execute o passo 01 em ios/docs/gds-v2-ios/01-contrato-modelos-quadra.md.
Foco: contratos, modelos e API client no dominio quadra.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS Maps (`02`)
```text
Execute o passo 02 em ios/docs/gds-v2-ios/02-mapa-quadras-render-interacao.md.
Foco: map stack ativo para quadras, render e interacao.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS Gameplay Rules (`03`)
```text
Execute o passo 03 em ios/docs/gds-v2-ios/03-elegibilidade-campeao-dono.md.
Foco: politica local de elegibilidade campeao/dono e testes.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS Runtime/UX (`04`)
```text
Execute o passo 04 em ios/docs/gds-v2-ios/04-companion-modo-competitivo-treino.md.
Foco: companion com modo competitivo/treino sem bloquear corrida.
Dependencias: 01 e 03 concluidos.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS Data/Sync (`05`)
```text
Execute o passo 05 em ios/docs/gds-v2-ios/05-pipeline-sync-upload-modo.md.
Foco: persistencia e upload de mode + targetQuadraId.
Dependencias: 01 e 03 concluidos.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS UX Flow (`06`)
```text
Execute o passo 06 em ios/docs/gds-v2-ios/06-resultado-pos-corrida-quadras.md.
Foco: resultado pos-corrida com quadraId e foco no mapa.
Dependencias: 02 e 05 concluidos.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS Refactor (`07`)
```text
Execute o passo 07 em ios/docs/gds-v2-ios/07-refactor-limpeza-legado.md.
Foco: remocao de legado tile no fluxo funcional.
Dependencias: 02 e 06 concluidos.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS QA (`08`)
```text
Execute o passo 08 em ios/docs/gds-v2-ios/08-testes-qa-gates-v2.md.
Foco: suites obrigatorias, matriz de QA e gate de merge.
Pode rodar em paralelo desde a rodada 1.
Atualize STATUS.md continuamente.
```

### Agente iOS Release (`09`)
```text
Execute o passo 09 em ios/docs/gds-v2-ios/09-hardening-release-v2.md.
Foco: regressao final, evidencias e readiness de release.
Dependencias: 04,05,06,07,08 concluidos.
Atualize STATUS.md no inicio e no fim.
```


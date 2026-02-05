# Onboarding de Agentes - GDS v1.0 iOS

## Objetivo
Fornecer prompts curtos para paralelizar execucao com varios agentes mantendo escopo, dependencia e criterio de qualidade.

## Regras gerais para todos os agentes
1. Ler primeiro:
   - `ios/docs/gds-v1-ios/00-decisoes-v1-ios.md`
   - `ios/docs/gds-v1-ios/README.md`
   - `ios/docs/gds-v1-ios/STATUS.md`
2. Trabalhar apenas no passo atribuido.
3. Nao alterar backend.
4. Incluir testes da propria etapa.
5. Atualizar `STATUS.md` ao iniciar e ao concluir.

## Ordem recomendada de kickoff
1. Rodada 1 (paralela): `01`, `06`, `07`, `08`
2. Rodada 2 (apos `01`): `02`, `04`
3. Rodada 3 (apos `02`): `03`, `05`
4. Rodada final: `09`

## Prompt base (copiar para qualquer agente)
```text
Voce e o dono do passo <PASSO>. Execute somente o que esta em ios/docs/gds-v1-ios/<ARQUIVO-DO-PASSO>.

Regras:
1) Nao alterar backend.
2) Cumprir criterios de pronto e plano de testes do passo.
3) Se houver bloqueio, registrar em ios/docs/gds-v1-ios/STATUS.md e parar.
4) Ao concluir, registrar no STATUS.md:
   - status
   - resumo do que foi entregue
   - comandos de teste executados e resultado
```

## Prompt por agente

### Agente iOS Platform (`01`)
```text
Execute o passo 01 em ios/docs/gds-v1-ios/01-fundacao-permissoes-config.md.
Foco: permissoes, config e card de permissao em corridas.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS Data/Health (`02`)
```text
Execute o passo 02 em ios/docs/gds-v1-ios/02-sync-healthkit-pipeline.md.
Foco: sync HealthKit, payload de coordenadas e fallback de retry local.
Dependencia: passo 01 concluido.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS Runtime/UX (`03`)
```text
Execute o passo 03 em ios/docs/gds-v1-ios/03-companion-hud-estados.md.
Foco: maquina de estados do companion e UX de sync/upload.
Dependencia: passo 02 concluido.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS Maps (`04`)
```text
Execute o passo 04 em ios/docs/gds-v1-ios/04-mapa-home-cta-tiles.md.
Foco: mapa como home, CTA fixo e refresh de tiles.
Dependencia: passo 01 concluido.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS UX Flow (`05`)
```text
Execute o passo 05 em ios/docs/gds-v1-ios/05-resultado-pos-corrida.md.
Foco: resumo pos-corrida clean, status territorial e foco no mapa.
Dependencia: passo 02 concluido.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS Social (`06`)
```text
Execute o passo 06 em ios/docs/gds-v1-ios/06-bandeiras-fluxo-completo.md.
Foco: criar/entrar/sair bandeira e estados de erro/vazio.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS Profile (`07`)
```text
Execute o passo 07 em ios/docs/gds-v1-ios/07-perfil-basico-historico.md.
Foco: stats basicas e historico curto no perfil.
Atualize STATUS.md no inicio e no fim.
```

### Agente iOS QA (`08`)
```text
Execute o passo 08 em ios/docs/gds-v1-ios/08-testes-qa-gates.md.
Foco: matriz de testes, gate de merge e smoke real.
Pode rodar em paralelo e deve validar cada etapa entregue.
Atualize STATUS.md continuamente.
```

### Agente iOS Release (`09`)
```text
Execute o passo 09 em ios/docs/gds-v1-ios/09-hardening-release.md.
Foco: regressao final, performance, consistencia de UX e evidencias para PR.
Dependencia: 03,04,05,06,07 concluidos.
Atualize STATUS.md no inicio e no fim.
```

## Encerramento da execucao paralela
1. Consolidar resultados no `STATUS.md`.
2. Confirmar `xcodebuild ... iPhone 17 ... test` verde no branch final.
3. Anexar evidencias de smoke real e checklist GDS no PR.

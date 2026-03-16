# Onboarding de Agentes - GDS v3 iOS

## Objetivo
Fornecer prompts curtos e operacionais para execucao paralela com GitHub Issues como fonte unica de andamento.

## Regras gerais
1. Ler primeiro:
   - `ios/docs/gds-v3-ios/00-decisoes-v3-ios.md`
   - `ios/docs/gds-v3-ios/README.md`
   - `ios/docs/gds-v3-ios/TAREFAS-AGENTES.md`
2. Trabalhar apenas no passo atribuido.
3. Nao alterar backend.
4. Incluir testes da propria etapa.
5. Atualizar a issue do passo ao iniciar, bloquear e concluir.
6. Nao criar nem atualizar `STATUS.md` para este pacote.
7. Padrao obrigatorio: `1 agente = 1 branch = 1 worktree = 1 issue`.

## Setup obrigatorio com worktree
1. Partir da raiz do repo:
   - `cd [repo-principal]`
2. Criar worktree por passo:
   - `git worktree add ../runwarapp-wt-v3-01 -b feat/ios-gds-v3-01-contrato`
   - `git worktree add ../runwarapp-wt-v3-02 -b feat/ios-gds-v3-02-shell`
   - `git worktree add ../runwarapp-wt-v3-03 -b feat/ios-gds-v3-03-mapa-filtros`
3. Entrar no worktree:
   - `cd ../runwarapp-wt-v3-01`
4. Validar contexto:
   - `git rev-parse --abbrev-ref HEAD`
   - `pwd`
5. Encontrar a issue do passo:
   - `gh issue list --search "GDS v3 iOS / 01" --state open`

## Convencao de nomes
1. Branch: `feat/ios-gds-v3-<passo>-<slug-curto>`.
2. Worktree: `../runwarapp-wt-v3-<passo>`.
3. Issue: titulo canonico do passo em `README.md`.

## Prompt base (copiar para qualquer agente)
```text
Voce e o dono do passo <PASSO>. Execute somente o que esta em ios/docs/gds-v3-ios/<ARQUIVO-DO-PASSO>.

Regras:
1) Nao alterar backend.
2) Cumprir criterios de pronto e plano de testes do passo.
3) Trabalhar em worktree dedicado e branch dedicada.
4) Registrar progresso por comentario na issue do passo.
5) Nao usar STATUS.md.
6) Nao fechar a issue sem testes passando.
```

## Prompt por agente

### Agente iOS API/Domain (`01`)
```text
Execute o passo 01 em ios/docs/gds-v3-ios/01-contrato-servicos-territorio-equipe.md.
Subagentes internos: 01A wrappers de API, 01B tipos/estado compartilhado, 01C fixtures e testes.
Registre inicio e fim na issue do passo.
```

### Agente iOS App Shell (`02`)
```text
Execute o passo 02 em ios/docs/gds-v3-ios/02-shell-navegacao-estado-compartilhado.md.
Subagentes internos: 02A navegacao entre tabs, 02B SessionStore, 02C intents de foco/filtro.
Dependencia: passo 01 concluido.
Registre inicio e fim na issue do passo.
```

### Agente iOS Maps (`03`)
```text
Execute o passo 03 em ios/docs/gds-v3-ios/03-mapa-filtros-territorio.md.
Subagentes internos: 03A barra de filtros, 03B estrategia de carregamento, 03C detalhe de quadra.
Dependencias: passos 02 e 04 concluidos.
Registre inicio e fim na issue do passo.
```

### Agente iOS Social Hub (`04`)
```text
Execute o passo 04 em ios/docs/gds-v3-ios/04-bandeiras-hub-explorar-ranking.md.
Subagentes internos: 04A explorar, 04B ranking, 04C CTA ver territorio.
Dependencia: passo 01 concluido.
Registre inicio e fim na issue do passo.
```

### Agente iOS Team/Admin (`05`)
```text
Execute o passo 05 em ios/docs/gds-v3-ios/05-minha-equipe-top-contribuidores-roles.md.
Subagentes internos: 05A roster, 05B top contribuidores, 05C mutacao de roles.
Dependencias: passos 02 e 04 concluidos.
Registre inicio e fim na issue do passo.
```

### Agente iOS Profile (`06`)
```text
Execute o passo 06 em ios/docs/gds-v3-ios/06-perfil-social-ctas.md.
Subagentes internos: 06A card minha bandeira, 06B CTAs cruzados, 06C empty states.
Dependencias: passos 02 e 04 concluidos.
Registre inicio e fim na issue do passo.
```

### Agente iOS Backend Dependency Track (`07`)
```text
Execute o passo 07 em ios/docs/gds-v3-ios/07-trilhas-dependentes-backend.md.
Subagentes internos: 07A ranking solo, 07B presenca semanal, 07C notificacoes, 07D badges/missoes.
Foco: documentar dependencias e manter a issue bloqueada com criterio de destravamento.
Registre bloqueio e atualizacoes na issue do passo.
```

### Agente iOS QA (`08`)
```text
Execute o passo 08 em ios/docs/gds-v3-ios/08-testes-qa-gates-v3.md.
Subagentes internos: 08A suites automatizadas, 08B matriz manual por persona, 08C gate de merge.
Pode rodar em paralelo desde a rodada 1.
Atualize a issue do passo continuamente.
```

### Agente iOS Release (`09`)
```text
Execute o passo 09 em ios/docs/gds-v3-ios/09-hardening-release-v3.md.
Subagentes internos: 09A regressao final, 09B polish e acessibilidade, 09C evidencias e PR.
Dependencias: 03,04,05,06,08 concluidos.
Registre inicio e fim na issue do passo.
```

## Encerramento da execucao paralela
1. Confirmar todas as issues da wave nos estados corretos.
2. Garantir a suite oficial do iOS verde no branch final.
3. Centralizar evidencias finais na issue `09`.
4. Remover worktrees locais que nao forem mais necessarios.


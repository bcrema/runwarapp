# 07 - Perfil basico historico

## Objetivo
- Dono sugerido: `Agente iOS Profile`.
- Entregar perfil basico com stats essenciais e historico curto de acoes territoriais.

## Escopo
- Entregaveis:
  - Bloco de metricas simples do corredor.
  - Lista curta de acoes/corridas recentes com status territorial.
  - Manter simplicidade visual e legibilidade da V1.

## Fora de escopo
- Perfil social avancado.
- Graficos complexos e analytics detalhado.

## Pre-requisitos
- `00-decisoes-v1-ios.md` lido.
- Dados de usuario e corridas disponiveis via API atual.

## Arquivos iOS impactados
- `ios/LigaRun/Sources/LigaRun/Features/Profile/ProfileView.swift`
- `ios/LigaRun/Sources/LigaRun/Features/Runs/RunsViewModel.swift` (reuso de dados, se necessario)
- `ios/LigaRun/Sources/LigaRun/App/SessionStore.swift`
- `ios/LigaRun/Sources/LigaRun/Services/RunService.swift`
- `ios/LigaRun/Tests/LigaRunTests/` (novos testes de perfil)

## Tarefas detalhadas
1. Exibir stats basicas: total de corridas, distancia total, tiles conquistados.
2. Exibir historico curto (ex.: ultimas 5 a 10 corridas) com acao territorial.
3. Garantir estado vazio legivel para usuarios sem historico.
4. Revisar fluxo de edicao de perfil para nao conflitar com novos blocos.
5. Garantir performance com carga padrao de dados.

## Criterios de pronto
1. Perfil mostra metricas essenciais sem poluicao visual.
2. Historico curto aparece com status valido/invalido e acao territorial.
3. Sem regressao no salvar alteracoes e logout.
4. Layout coerente com diretriz clean da V1.

## Plano de testes
1. Unitario: composicao de dados de perfil com usuario nulo e usuario valido.
2. Unitario: renderizacao de estado vazio do historico.
3. Manual: usuario novo sem corridas.
4. Manual: usuario com corridas validas/invalidas.
5. Caso mapeado GDS: suporte ao fluxo de leitura de impacto territorial no perfil.

## Riscos
- Divergencia de formatos de data/status entre corridas e perfil.
- Crescimento de dados pode exigir paginacao futura.

## Handoff para proximo passo
- Compartilhar decisoes de UX textual com `05-resultado-pos-corrida.md`.
- Enviar checklist final para `09-hardening-release.md`.

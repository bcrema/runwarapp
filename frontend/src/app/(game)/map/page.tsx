'use client'

import { useEffect, useMemo, useState } from 'react'
import dynamic from 'next/dynamic'
import Link from 'next/link'
import {
    api,
    Bandeira,
    BandeiraMember,
    DailyStatus,
    Run,
    Tile,
    TileStats,
} from '@/lib/api'
import { useAuth } from '@/lib/auth'
import {
    buildCategoryBreakdown,
    buildRunnerSnapshot,
    buildTerritorySnapshot,
    formatCompactNumber,
    formatDateLabel,
    formatDistance,
    formatPercentage,
    getCategoryLabel,
    getRoleLabel,
} from '@/lib/dashboard'
import styles from './page.module.css'

const HexMap = dynamic(() => import('@/components/map/HexMap'), {
    ssr: false,
    loading: () => (
        <div className={styles.mapLoading}>
            <div className="spinner"></div>
            <span>Carregando mapa operacional...</span>
        </div>
    ),
})

export default function MapPage() {
    const { user } = useAuth()
    const [stats, setStats] = useState<TileStats | null>(null)
    const [dailyStatus, setDailyStatus] = useState<DailyStatus | null>(null)
    const [runs, setRuns] = useState<Run[]>([])
    const [rankings, setRankings] = useState<Bandeira[]>([])
    const [directory, setDirectory] = useState<Bandeira[]>([])
    const [members, setMembers] = useState<BandeiraMember[]>([])
    const [selectedTile, setSelectedTile] = useState<Tile | null>(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        let isMounted = true

        const loadData = async () => {
            setLoading(true)
            setError(null)

            const [statsResult, dailyResult, runsResult, rankingsResult, directoryResult, membersResult] =
                await Promise.allSettled([
                    api.getTileStats(),
                    api.getDailyStatus(),
                    api.getMyRuns(12),
                    api.getBandeiraRankings(),
                    api.getBandeiras(),
                    user?.bandeiraId
                        ? api.getBandeiraMembers(user.bandeiraId)
                        : Promise.resolve([] as BandeiraMember[]),
                ])

            if (!isMounted) return

            let failedRequests = 0

            if (statsResult.status === 'fulfilled') setStats(statsResult.value)
            else failedRequests += 1

            if (dailyResult.status === 'fulfilled') setDailyStatus(dailyResult.value)
            else failedRequests += 1

            if (runsResult.status === 'fulfilled') setRuns(runsResult.value)
            else failedRequests += 1

            if (rankingsResult.status === 'fulfilled') setRankings(rankingsResult.value)
            else failedRequests += 1

            if (directoryResult.status === 'fulfilled') setDirectory(directoryResult.value)
            else failedRequests += 1

            if (membersResult.status === 'fulfilled') setMembers(membersResult.value)
            else failedRequests += 1

            if (failedRequests > 0) {
                setError('Parte dos indicadores nao carregou. O painel segue com os dados disponiveis.')
            }

            setLoading(false)
        }

        loadData()

        return () => {
            isMounted = false
        }
    }, [user?.bandeiraId])

    const runnerSnapshot = useMemo(
        () => buildRunnerSnapshot(user ?? null, runs),
        [runs, user]
    )
    const territorySnapshot = useMemo(
        () => buildTerritorySnapshot(stats, dailyStatus, runs),
        [dailyStatus, runs, stats]
    )
    const categoryBreakdown = useMemo(
        () => buildCategoryBreakdown(directory),
        [directory]
    )

    const currentRank =
        user?.bandeiraId != null
            ? rankings.findIndex((bandeira) => bandeira.id === user.bandeiraId) + 1
            : 0
    const featuredBandeiras = rankings.slice(0, 3)
    const topMember = [...members].sort(
        (a, b) => b.totalTilesConquered - a.totalTilesConquered
    )[0]

    if (loading) {
        return (
            <div className={styles.loading}>
                <div className="spinner"></div>
                <span>Montando o painel central...</span>
            </div>
        )
    }

    return (
        <div className={styles.page}>
            <section className={styles.hero}>
                <div className={`${styles.heroCopy} section-header`}>
                    <span className="section-kicker">Painel Central</span>
                    <h1 className="section-title">
                        Tudo o que o corredor e a bandeira precisam ler antes
                        da proxima semana.
                    </h1>
                    <p className="section-copy">
                        O foco aqui nao e iniciar corrida no navegador. E
                        entender momento, recorrencia, territorio e expansao da
                        comunidade a partir dos dados que voce ja gera.
                    </p>

                    <div className={styles.heroTags}>
                        <span className="tag tag-accent">
                            {runnerSnapshot.totalRuns} corridas acumuladas
                        </span>
                        <span className="tag">
                            {user?.bandeiraName ?? 'Sem bandeira no momento'}
                        </span>
                        <span className="tag tag-warn">
                            {territorySnapshot.userActionsRemaining ?? 0} acoes restantes hoje
                        </span>
                    </div>
                </div>

                <aside className={`${styles.heroAside} panel panel-strong`}>
                    <div className={styles.heroAsideHeader}>
                        <span className="metric-label">Momento do corredor</span>
                        <strong className="metric-value">
                            {formatDistance(runnerSnapshot.weeklyDistance)}
                        </strong>
                        <span className="metric-detail">
                            {runnerSnapshot.activeDays} dias ativos nos ultimos 7 dias e
                            ritmo medio de {runnerSnapshot.averagePace}.
                        </span>
                    </div>

                    <div className={styles.heroAsideList}>
                        <div className={styles.heroAsideItem}>
                            <span>Ultima sessao</span>
                            <strong>{formatDateLabel(runnerSnapshot.lastRunAt)}</strong>
                        </div>
                        <div className={styles.heroAsideItem}>
                            <span>Bandeira</span>
                            <strong>
                                {user?.bandeiraName
                                    ? `${user.bandeiraName} ${currentRank > 0 ? `#${currentRank}` : ''}`
                                    : 'Escolha uma bandeira'}
                            </strong>
                        </div>
                        <div className={styles.heroAsideItem}>
                            <span>Papel atual</span>
                            <strong>{getRoleLabel(user?.role ?? 'MEMBER')}</strong>
                        </div>
                    </div>

                    <div className={styles.heroAsideActions}>
                        <Link href="/run" className="btn btn-secondary">
                            Ver sessoes
                        </Link>
                        <Link href="/bandeira" className="btn btn-outline">
                            Abrir hub de bandeiras
                        </Link>
                    </div>
                </aside>
            </section>

            {error && <div className={styles.banner}>{error}</div>}

            <section className="metric-grid">
                <article className="panel metric-card">
                    <span className="metric-label">Distancia total</span>
                    <strong className="metric-value">
                        {formatDistance(runnerSnapshot.totalDistance)}
                    </strong>
                    <span className="metric-detail">
                        Historico do corredor consolidado para leitura rapida.
                    </span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Corridas validadas</span>
                    <strong className="metric-value">
                        {formatPercentage(runnerSnapshot.validatedRate)}
                    </strong>
                    <span className="metric-detail">
                        Taxa de sessoes aprovadas na analise de consistencia.
                    </span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Territorio em disputa</span>
                    <strong className="metric-value">
                        {formatPercentage(territorySnapshot.disputedShare)}
                    </strong>
                    <span className="metric-detail">
                        Leitura do quanto o mapa esta pedindo resposta da comunidade.
                    </span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Bandeiras na base</span>
                    <strong className="metric-value">
                        {formatCompactNumber(directory.length)}
                    </strong>
                    <span className="metric-detail">
                        Uma plataforma mais clara para atrair grupos e assessorias.
                    </span>
                </article>
            </section>

            <section className={styles.operationsGrid}>
                <article className={`${styles.mapCard} panel panel-strong`}>
                    <div className={styles.cardHeader}>
                        <div className="section-header">
                            <span className="section-kicker">Mapa Operacional</span>
                            <h2>Leitura territorial sem sair do painel.</h2>
                            <p className="section-copy">
                                Use o mapa como contexto de decisao, nao como
                                tela principal do produto.
                            </p>
                        </div>
                    </div>

                    <div className={styles.mapFrame}>
                        <HexMap onTileClick={setSelectedTile} />
                    </div>
                </article>

                <aside className={styles.sideStack}>
                    <article className="panel">
                        <div className="section-header">
                            <span className="section-kicker">Tile selecionado</span>
                            <h2>Contexto rapido</h2>
                        </div>

                        {selectedTile ? (
                            <div className={styles.tileDetails}>
                                <div className={styles.tileRow}>
                                    <span>Dominio</span>
                                    <strong>{selectedTile.ownerName ?? 'Neutro'}</strong>
                                </div>
                                <div className={styles.tileRow}>
                                    <span>Tipo</span>
                                    <strong>{selectedTile.ownerType ?? 'Disponivel'}</strong>
                                </div>
                                <div className={styles.tileRow}>
                                    <span>Escudo</span>
                                    <strong>{selectedTile.shield}</strong>
                                </div>
                                <div className={styles.tileRow}>
                                    <span>Status</span>
                                    <strong>
                                        {selectedTile.isInDispute
                                            ? 'Em disputa'
                                            : selectedTile.isInCooldown
                                              ? 'Cooldown'
                                              : 'Estavel'}
                                    </strong>
                                </div>
                            </div>
                        ) : (
                            <div className="empty-state">
                                <strong>Selecione um tile no mapa.</strong>
                                <span>
                                    O painel mostra dados mais completos quando
                                    voce clica em um territorio.
                                </span>
                            </div>
                        )}
                    </article>

                    <article className="panel">
                        <div className="section-header">
                            <span className="section-kicker">Acoes do dia</span>
                            <h2>Capacidade operacional</h2>
                        </div>
                        <div className={styles.tileDetails}>
                            <div className={styles.tileRow}>
                                <span>Corredor</span>
                                <strong>{territorySnapshot.userActionsRemaining ?? 0} livres</strong>
                            </div>
                            <div className={styles.tileRow}>
                                <span>Bandeira</span>
                                <strong>
                                    {territorySnapshot.bandeiraActionsRemaining != null
                                        ? `${territorySnapshot.bandeiraActionsRemaining} livres`
                                        : 'Sem limite ativo'}
                                </strong>
                            </div>
                            <div className={styles.tileRow}>
                                <span>Conquistas validas</span>
                                <strong>{territorySnapshot.conquestRuns}</strong>
                            </div>
                            <div className={styles.tileRow}>
                                <span>Defesas validas</span>
                                <strong>{territorySnapshot.defenseRuns}</strong>
                            </div>
                        </div>
                    </article>
                </aside>
            </section>

            <section className={styles.insightsGrid}>
                <article className="panel">
                    <div className="section-header">
                        <span className="section-kicker">Leitura do corredor</span>
                        <h2>Rotina, volume e confiabilidade.</h2>
                    </div>

                    <div className="list">
                        <div className="list-item">
                            <div>
                                <div className="list-title">Semana em andamento</div>
                                <div className="list-subtle">
                                    {runnerSnapshot.activeDays} dias ativos em 7 dias.
                                </div>
                            </div>
                            <strong>{formatDistance(runnerSnapshot.weeklyDistance)}</strong>
                        </div>
                        <div className="list-item">
                            <div>
                                <div className="list-title">Melhor sessao recente</div>
                                <div className="list-subtle">
                                    Maior distancia registrada nesta amostra.
                                </div>
                            </div>
                            <strong>{formatDistance(runnerSnapshot.longestRun)}</strong>
                        </div>
                        <div className="list-item">
                            <div>
                                <div className="list-title">Efeito territorial</div>
                                <div className="list-subtle">
                                    Conversao das corridas validadas em acao de mapa.
                                </div>
                            </div>
                            <strong>{formatPercentage(runnerSnapshot.territoryConversion)}</strong>
                        </div>
                    </div>
                </article>

                <article className="panel">
                    <div className="section-header">
                        <span className="section-kicker">Leitura da bandeira</span>
                        <h2>Peso coletivo e recorrencia da equipe.</h2>
                    </div>

                    {user?.bandeiraName ? (
                        <div className="list">
                            <div className="list-item">
                                <div>
                                    <div className="list-title">Posicao no radar</div>
                                    <div className="list-subtle">
                                        Comparativo com as bandeiras mais ativas.
                                    </div>
                                </div>
                                <strong>{currentRank > 0 ? `#${currentRank}` : 'Sem ranking'}</strong>
                            </div>
                            <div className="list-item">
                                <div>
                                    <div className="list-title">Membro com mais tiles</div>
                                    <div className="list-subtle">
                                        Destaque interno para comunicacao da equipe.
                                    </div>
                                </div>
                                <strong>{topMember?.username ?? 'Sem dado'}</strong>
                            </div>
                            <div className="list-item">
                                <div>
                                    <div className="list-title">Participantes ativos</div>
                                    <div className="list-subtle">Membros carregados no seu roster atual.</div>
                                </div>
                                <strong>{members.length}</strong>
                            </div>
                        </div>
                    ) : (
                        <div className="empty-state">
                            <strong>Voce ainda nao esta em uma bandeira.</strong>
                            <span>
                                Entre em uma equipe para desbloquear leitura de
                                ranking, roster e operacao coletiva.
                            </span>
                            <Link href="/bandeira" className="btn btn-primary btn-sm">
                                Encontrar bandeira
                            </Link>
                        </div>
                    )}
                </article>

                <article className="panel">
                    <div className="section-header">
                        <span className="section-kicker">Leitura de crescimento</span>
                        <h2>Onde a plataforma pode ganhar tracao.</h2>
                    </div>

                    <div className="list">
                        {categoryBreakdown.slice(0, 3).map((item) => (
                            <div key={item.category} className="list-item">
                                <div>
                                    <div className="list-title">{item.label}</div>
                                    <div className="list-subtle">
                                        {item.count} bandeiras com {item.memberCount} membros somados.
                                    </div>
                                </div>
                                <strong>{item.totalTiles} tiles</strong>
                            </div>
                        ))}
                    </div>
                </article>
            </section>

            <section className={styles.featuredGrid}>
                <article className={`${styles.featuredCard} panel panel-dark`}>
                    <div className="section-header">
                        <span className="section-kicker">Bandeiras em destaque</span>
                        <h2>Quem esta puxando a conversa agora.</h2>
                    </div>

                    <div className="list">
                        {featuredBandeiras.map((bandeira, index) => (
                            <div key={bandeira.id} className="list-item">
                                <div>
                                    <div className="list-title">
                                        #{index + 1} {bandeira.name}
                                    </div>
                                    <div className="list-subtle">
                                        {getCategoryLabel(bandeira.category)} com {bandeira.memberCount} membros.
                                    </div>
                                </div>
                                <strong>{bandeira.totalTiles} tiles</strong>
                            </div>
                        ))}
                    </div>
                </article>

                <article className="panel panel-strong">
                    <div className="section-header">
                        <span className="section-kicker">Proxima acao</span>
                        <h2>Use o web para aprofundar relacao com a comunidade.</h2>
                        <p className="section-copy">
                            O produto fica mais forte quando a leitura do
                            corredor alimenta a narrativa da bandeira e gera um
                            convite claro para novos grupos entrarem.
                        </p>
                    </div>

                    <div className={styles.ctaRow}>
                        <Link href="/rankings" className="btn btn-secondary">
                            Abrir radar competitivo
                        </Link>
                        <Link href="/bandeira" className="btn btn-primary">
                            Gerir comunidade
                        </Link>
                    </div>
                </article>
            </section>
        </div>
    )
}

'use client'

import { useEffect, useMemo, useState } from 'react'
import Link from 'next/link'
import { api, Run } from '@/lib/api'
import { useAuth } from '@/lib/auth'
import {
    buildRunnerSnapshot,
    formatDateLabel,
    formatDistance,
    formatDuration,
    formatPace,
    formatPercentage,
    getRunOutcomeLabel,
    getRunStatusLabel,
    sortRunsByDate,
} from '@/lib/dashboard'
import styles from './page.module.css'

export default function RunPage() {
    const { user } = useAuth()
    const [runs, setRuns] = useState<Run[]>([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        let isMounted = true

        const loadRuns = async () => {
            try {
                setLoading(true)
                const data = await api.getMyRuns(18)

                if (!isMounted) return
                setRuns(data)
            } catch {
                if (!isMounted) return
                setError('Não foi possível carregar as sessões agora.')
            } finally {
                if (isMounted) {
                    setLoading(false)
                }
            }
        }

        loadRuns()

        return () => {
            isMounted = false
        }
    }, [])

    const sortedRuns = useMemo(() => sortRunsByDate(runs), [runs])
    const snapshot = useMemo(
        () => buildRunnerSnapshot(user ?? null, runs),
        [runs, user]
    )
    const validatedRuns = sortedRuns.filter((run) => run.status === 'VALIDATED')
    const runsByOrigin = sortedRuns.reduce<Record<string, number>>((acc, run) => {
        acc[run.origin] = (acc[run.origin] ?? 0) + 1
        return acc
    }, {})
    const territoryRuns = validatedRuns.filter(
        (run) => run.territoryAction !== null && run.isValidForTerritory
    )

    if (loading) {
        return (
            <div className={styles.loading}>
                <div className="spinner"></div>
                <span>Carregando análise das sessões...</span>
            </div>
        )
    }

    return (
        <div className={styles.page}>
            <section className={styles.hero}>
                <div className="section-header">
                    <span className="section-kicker">Sessões e consistência</span>
                    <h1 className="section-title">
                        O navegador não grava corrida. Ele organiza e explica o
                        que já aconteceu.
                    </h1>
                    <p className="section-copy">
                        Use esta tela para ler o histórico recente, comparar
                        validação, entender impacto territorial e acompanhar a
                        regularidade do corredor.
                    </p>
                </div>

                <aside className={`${styles.heroCard} panel panel-strong`}>
                    <span className="metric-label">Resumo rápido</span>
                    <strong className="metric-value">{snapshot.averagePace}</strong>
                    <span className="metric-detail">
                        Ritmo médio calculado a partir das corridas validadas.
                    </span>
                    <div className={styles.heroCardList}>
                        <div>
                            <span>Semana</span>
                            <strong>{formatDistance(snapshot.weeklyDistance)}</strong>
                        </div>
                        <div>
                            <span>Validação</span>
                            <strong>{formatPercentage(snapshot.validatedRate)}</strong>
                        </div>
                        <div>
                            <span>Ação territorial</span>
                            <strong>{territoryRuns.length}</strong>
                        </div>
                    </div>
                </aside>
            </section>

            {error && <div className={styles.banner}>{error}</div>}

            <section className="metric-grid">
                <article className="panel metric-card">
                    <span className="metric-label">Corridas lidas</span>
                    <strong className="metric-value">{sortedRuns.length}</strong>
                    <span className="metric-detail">Amostra mais recente disponível para análise.</span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Maior sessão</span>
                    <strong className="metric-value">{formatDistance(snapshot.longestRun)}</strong>
                    <span className="metric-detail">Maior distância desta janela de consulta.</span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Dias ativos</span>
                    <strong className="metric-value">{snapshot.activeDays}</strong>
                    <span className="metric-detail">Dias com sessão registrada nos últimos 7 dias.</span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Conversão territorial</span>
                    <strong className="metric-value">
                        {formatPercentage(snapshot.territoryConversion)}
                    </strong>
                    <span className="metric-detail">Quanto das corridas validadas vira ação no mapa.</span>
                </article>
            </section>

            <section className={styles.contentGrid}>
                <article className="panel">
                    <div className="section-header">
                        <span className="section-kicker">Timeline</span>
                        <h2>Últimas sessões lidas pelo sistema.</h2>
                    </div>

                    {sortedRuns.length > 0 ? (
                        <div className="list">
                            {sortedRuns.map((run) => (
                                <div key={run.id} className={styles.runCard}>
                                    <div className={styles.runTop}>
                                        <div>
                                            <div className="list-title">
                                                {formatDistance(run.distance)} em {formatDuration(run.duration)}
                                            </div>
                                            <div className="list-subtle">
                                                {formatDateLabel(run.endTime)} - {run.origin}
                                            </div>
                                        </div>
                                        <div className={styles.runTags}>
                                            <span
                                                className={`badge ${
                                                    run.territoryAction === 'CONQUEST'
                                                        ? 'badge-conquest'
                                                        : run.territoryAction === 'ATTACK'
                                                          ? 'badge-attack'
                                                          : run.territoryAction === 'DEFENSE'
                                                            ? 'badge-defense'
                                                            : 'badge-neutral'
                                                }`}
                                            >
                                                {getRunOutcomeLabel(run)}
                                            </span>
                                            <span className="tag">{getRunStatusLabel(run)}</span>
                                        </div>
                                    </div>

                                    <div className={styles.runMeta}>
                                        <div>
                                            <span>Ritmo</span>
                                            <strong>{formatPace(run.distance, run.duration)}</strong>
                                        </div>
                                        <div>
                                            <span>Loop válido</span>
                                            <strong>{run.isLoopValid ? 'Sim' : 'Não'}</strong>
                                        </div>
                                        <div>
                                            <span>Tile alvo</span>
                                            <strong>{run.targetTileId ?? 'Sem tile'}</strong>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    ) : (
                        <div className="empty-state">
                            <strong>Nenhuma sessão encontrada.</strong>
                            <span>
                                O app captura seus treinos; a web mostra a
                                leitura assim que eles entram na conta.
                            </span>
                        </div>
                    )}
                </article>

                <aside className={styles.sideStack}>
                    <article className="panel">
                        <div className="section-header">
                            <span className="section-kicker">Origem das sessões</span>
                            <h2>Como esse histórico entrou.</h2>
                        </div>

                        <div className="list">
                            {Object.entries(runsByOrigin).map(([origin, total]) => (
                                <div key={origin} className="list-item">
                                    <div>
                                        <div className="list-title">{origin}</div>
                                        <div className="list-subtle">
                                            Sessões recebidas por esta origem.
                                        </div>
                                    </div>
                                    <strong>{total}</strong>
                                </div>
                            ))}
                        </div>
                    </article>

                    <article className="panel panel-strong">
                        <div className="section-header">
                            <span className="section-kicker">Uso da web</span>
                            <h2>Camada analítica, não gravador.</h2>
                        </div>
                        <p className="section-copy">
                            Esse reposicionamento tira atrito do navegador e
                            deixa claro o papel da interface: ler, comparar e
                            orientar a próxima decisão.
                        </p>
                        <div className={styles.sideActions}>
                            <Link href="/map" className="btn btn-secondary">
                                Voltar ao painel
                            </Link>
                            <Link href="/profile" className="btn btn-outline">
                                Ver perfil
                            </Link>
                        </div>
                    </article>
                </aside>
            </section>
        </div>
    )
}

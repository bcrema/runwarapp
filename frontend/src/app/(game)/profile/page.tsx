'use client'

import { useEffect, useMemo, useState } from 'react'
import Link from 'next/link'
import { api, DailyStatus, Run } from '@/lib/api'
import { useAuth } from '@/lib/auth'
import {
    buildRunnerSnapshot,
    formatDateLabel,
    formatDistance,
    formatPace,
    formatPercentage,
    getRoleLabel,
    sortRunsByDate,
} from '@/lib/dashboard'
import styles from './page.module.css'

export default function ProfilePage() {
    const { user, isLoading } = useAuth()
    const [runs, setRuns] = useState<Run[]>([])
    const [dailyStatus, setDailyStatus] = useState<DailyStatus | null>(null)
    const [loadingData, setLoadingData] = useState(true)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        let isMounted = true

        const loadData = async () => {
            try {
                setLoadingData(true)
                const [runsResult, dailyStatusResult] = await Promise.allSettled([
                    api.getMyRuns(10),
                    api.getDailyStatus(),
                ])

                if (!isMounted) return

                if (runsResult.status === 'fulfilled') setRuns(runsResult.value)
                else setError('Nao foi possivel carregar todas as sessoes do perfil.')

                if (dailyStatusResult.status === 'fulfilled') setDailyStatus(dailyStatusResult.value)
                else setError('Nao foi possivel carregar todas as sessoes do perfil.')
            } finally {
                if (isMounted) {
                    setLoadingData(false)
                }
            }
        }

        if (user) {
            loadData()
        } else {
            setLoadingData(false)
        }

        return () => {
            isMounted = false
        }
    }, [user])

    const sortedRuns = useMemo(() => sortRunsByDate(runs), [runs])
    const snapshot = useMemo(
        () => buildRunnerSnapshot(user ?? null, runs),
        [runs, user]
    )

    if (isLoading || loadingData) {
        return (
            <div className={styles.loading}>
                <div className="spinner"></div>
                <span>Carregando perfil...</span>
            </div>
        )
    }

    if (!user) {
        return (
            <div className={styles.page}>
                <div className="empty-state">
                    <strong>Voce precisa estar logado para ver seu perfil.</strong>
                    <Link href="/login" className="btn btn-primary btn-sm">
                        Fazer login
                    </Link>
                </div>
            </div>
        )
    }

    return (
        <div className={styles.page}>
            <section className={styles.hero}>
                <div className={styles.identityCard}>
                    <div className={styles.avatar}>
                        {user.username.slice(0, 2).toUpperCase()}
                    </div>
                    <div className={styles.identityCopy}>
                        <span className="section-kicker">Perfil do corredor</span>
                        <h1>@{user.username}</h1>
                        <p>{user.email}</p>
                        <div className={styles.identityTags}>
                            <span className="tag tag-accent">{getRoleLabel(user.role)}</span>
                            <span className="tag">
                                {user.bandeiraName ?? 'Sem bandeira'}
                            </span>
                            <span className="tag">
                                {user.isPublic ? 'Perfil publico' : 'Perfil privado'}
                            </span>
                        </div>
                    </div>
                </div>

                <aside className={`${styles.summaryCard} panel panel-strong`}>
                    <span className="metric-label">Estado atual</span>
                    <strong className="metric-value">{snapshot.averagePace}</strong>
                    <span className="metric-detail">
                        Ritmo medio das corridas validadas e {snapshot.activeDays} dias
                        ativos na ultima semana.
                    </span>
                    <div className={styles.summaryRows}>
                        <div>
                            <span>Acoes hoje</span>
                            <strong>{dailyStatus?.userActionsRemaining ?? 0}</strong>
                        </div>
                        <div>
                            <span>Ultima corrida</span>
                            <strong>{formatDateLabel(snapshot.lastRunAt)}</strong>
                        </div>
                    </div>
                </aside>
            </section>

            {error && <div className={styles.banner}>{error}</div>}

            <section className="metric-grid">
                <article className="panel metric-card">
                    <span className="metric-label">Distancia acumulada</span>
                    <strong className="metric-value">{formatDistance(user.totalDistance)}</strong>
                    <span className="metric-detail">Base total consolidada da conta.</span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Corridas totais</span>
                    <strong className="metric-value">{user.totalRuns}</strong>
                    <span className="metric-detail">Volume historico registrado.</span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Tiles conquistados</span>
                    <strong className="metric-value">{user.totalTilesConquered}</strong>
                    <span className="metric-detail">Impacto acumulado no mapa.</span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Taxa validada</span>
                    <strong className="metric-value">
                        {formatPercentage(snapshot.validatedRate)}
                    </strong>
                    <span className="metric-detail">Leitura de consistencia dos seus envios.</span>
                </article>
            </section>

            <section className={styles.contentGrid}>
                <article className="panel">
                    <div className="section-header">
                        <span className="section-kicker">Leitura pessoal</span>
                        <h2>Como voce esta performando.</h2>
                    </div>

                    <div className="list">
                        <div className="list-item">
                            <div>
                                <div className="list-title">Semana atual</div>
                                <div className="list-subtle">Distancia acumulada nos ultimos 7 dias.</div>
                            </div>
                            <strong>{formatDistance(snapshot.weeklyDistance)}</strong>
                        </div>
                        <div className="list-item">
                            <div>
                                <div className="list-title">Maior sessao recente</div>
                                <div className="list-subtle">Melhor distancia desta amostra.</div>
                            </div>
                            <strong>{formatDistance(snapshot.longestRun)}</strong>
                        </div>
                        <div className="list-item">
                            <div>
                                <div className="list-title">Conversao territorial</div>
                                <div className="list-subtle">Quanto das corridas validadas vira acao util.</div>
                            </div>
                            <strong>{formatPercentage(snapshot.territoryConversion)}</strong>
                        </div>
                    </div>
                </article>

                <article className="panel">
                    <div className="section-header">
                        <span className="section-kicker">Ultimas sessoes</span>
                        <h2>Historico recente.</h2>
                    </div>

                    {sortedRuns.length > 0 ? (
                        <div className="list">
                            {sortedRuns.slice(0, 4).map((run) => (
                                <div key={run.id} className="list-item">
                                    <div>
                                        <div className="list-title">{formatDateLabel(run.endTime)}</div>
                                        <div className="list-subtle">
                                            {formatDistance(run.distance)} - {run.origin}
                                        </div>
                                    </div>
                                    <strong>{formatPace(run.distance, run.duration)}</strong>
                                </div>
                            ))}
                        </div>
                    ) : (
                        <div className="empty-state">
                            <strong>Sem sessoes recentes.</strong>
                            <span>Assim que corridas entrarem, o perfil organiza a leitura aqui.</span>
                        </div>
                    )}
                </article>

                <aside className={styles.sideStack}>
                    <article className="panel panel-strong">
                        <div className="section-header">
                            <span className="section-kicker">Papel na plataforma</span>
                            <h2>Seu contexto atual.</h2>
                        </div>
                        <div className="list">
                            <div className="list-item">
                                <div>
                                    <div className="list-title">Bandeira</div>
                                    <div className="list-subtle">Equipe conectada ao seu perfil.</div>
                                </div>
                                <strong>{user.bandeiraName ?? 'Nenhuma'}</strong>
                            </div>
                            <div className="list-item">
                                <div>
                                    <div className="list-title">Visibilidade</div>
                                    <div className="list-subtle">Como o perfil aparece para a comunidade.</div>
                                </div>
                                <strong>{user.isPublic ? 'Publico' : 'Privado'}</strong>
                            </div>
                        </div>
                        <div className={styles.sideActions}>
                            <Link href="/bandeira" className="btn btn-secondary">
                                Gerir bandeira
                            </Link>
                            <Link href="/map" className="btn btn-outline">
                                Voltar ao painel
                            </Link>
                        </div>
                    </article>
                </aside>
            </section>
        </div>
    )
}

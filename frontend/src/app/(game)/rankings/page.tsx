'use client'

import { useEffect, useMemo, useState } from 'react'
import Link from 'next/link'
import { api, Bandeira } from '@/lib/api'
import { buildCategoryBreakdown, getCategoryLabel } from '@/lib/dashboard'
import styles from './page.module.css'

export default function RankingsPage() {
    const [bandeiras, setBandeiras] = useState<Bandeira[]>([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        let isMounted = true

        const loadRankings = async () => {
            try {
                setLoading(true)
                const data = await api.getBandeiraRankings()

                if (!isMounted) return
                setBandeiras(data)
            } catch {
                if (!isMounted) return
                setError('Nao foi possivel carregar o radar competitivo agora.')
            } finally {
                if (isMounted) {
                    setLoading(false)
                }
            }
        }

        loadRankings()

        return () => {
            isMounted = false
        }
    }, [])

    const leader = bandeiras[0]
    const categoryBreakdown = useMemo(
        () => buildCategoryBreakdown(bandeiras),
        [bandeiras]
    )
    const totalMembers = bandeiras.reduce((sum, item) => sum + item.memberCount, 0)
    const totalTiles = bandeiras.reduce((sum, item) => sum + item.totalTiles, 0)

    if (loading) {
        return (
            <div className={styles.loading}>
                <div className="spinner"></div>
                <span>Carregando radar competitivo...</span>
            </div>
        )
    }

    return (
        <div className={styles.page}>
            <section className={styles.hero}>
                <div className="section-header">
                    <span className="section-kicker">Radar competitivo</span>
                    <h1 className="section-title">
                        O ranking agora serve para leitura e captacao, nao so
                        para exibicao.
                    </h1>
                    <p className="section-copy">
                        Compare peso territorial, densidade de membros e tipos
                        de comunidade mais ativos. Isso ajuda a contar melhor a
                        historia da plataforma para novos grupos e assessorias.
                    </p>
                </div>

                <aside className={`${styles.leaderCard} panel panel-dark`}>
                    <span className="metric-label">Lider atual</span>
                    <strong className="metric-value">{leader?.name ?? 'Sem lider'}</strong>
                    <span className="metric-detail">
                        {leader
                            ? `${getCategoryLabel(leader.category)} com ${leader.memberCount} membros`
                            : 'Ainda nao ha bandeiras no ranking.'}
                    </span>
                    {leader && (
                        <div className={styles.leaderMeta}>
                            <div>
                                <span>Tiles</span>
                                <strong>{leader.totalTiles}</strong>
                            </div>
                            <div>
                                <span>Criado por</span>
                                <strong>{leader.createdByUsername}</strong>
                            </div>
                        </div>
                    )}
                </aside>
            </section>

            {error && <div className={styles.banner}>{error}</div>}

            <section className="metric-grid">
                <article className="panel metric-card">
                    <span className="metric-label">Bandeiras ranqueadas</span>
                    <strong className="metric-value">{bandeiras.length}</strong>
                    <span className="metric-detail">Base atual de comunidades visiveis no radar.</span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Membros somados</span>
                    <strong className="metric-value">{totalMembers}</strong>
                    <span className="metric-detail">Volume coletivo que o produto consegue expor.</span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Tiles somados</span>
                    <strong className="metric-value">{totalTiles}</strong>
                    <span className="metric-detail">Presenca territorial acumulada das equipes.</span>
                </article>
                <article className="panel metric-card">
                    <span className="metric-label">Categorias com tracao</span>
                    <strong className="metric-value">{categoryBreakdown.length}</strong>
                    <span className="metric-detail">Categorias ativas para comunicar oferta do produto.</span>
                </article>
            </section>

            <section className={styles.contentGrid}>
                <article className="panel">
                    <div className="section-header">
                        <span className="section-kicker">Leaderboard</span>
                        <h2>Quem ocupa o topo da conversa agora.</h2>
                    </div>

                    {bandeiras.length > 0 ? (
                        <div className="list">
                            {bandeiras.map((bandeira, index) => (
                                <div key={bandeira.id} className={styles.rankingRow}>
                                    <div className={styles.position}>{String(index + 1).padStart(2, '0')}</div>
                                    <div className={styles.rowContent}>
                                        <div>
                                            <div className="list-title">{bandeira.name}</div>
                                            <div className="list-subtle">
                                                {getCategoryLabel(bandeira.category)} - {bandeira.memberCount} membros
                                            </div>
                                        </div>
                                        <div className={styles.rowMeta}>
                                            <span>{bandeira.createdByUsername}</span>
                                            <strong>{bandeira.totalTiles} tiles</strong>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    ) : (
                        <div className="empty-state">
                            <strong>Nenhuma bandeira no ranking.</strong>
                            <span>Assim que houver comunidades ativas, o radar aparece aqui.</span>
                        </div>
                    )}
                </article>

                <aside className={styles.sideStack}>
                    <article className="panel">
                        <div className="section-header">
                            <span className="section-kicker">Leitura por categoria</span>
                            <h2>Quais formatos estao puxando tracao.</h2>
                        </div>

                        <div className="list">
                            {categoryBreakdown.map((item) => (
                                <div key={item.category} className="list-item">
                                    <div>
                                        <div className="list-title">{item.label}</div>
                                        <div className="list-subtle">
                                            {item.count} bandeiras - {item.memberCount} membros
                                        </div>
                                    </div>
                                    <strong>{item.totalTiles}</strong>
                                </div>
                            ))}
                        </div>
                    </article>

                    <article className="panel panel-strong">
                        <div className="section-header">
                            <span className="section-kicker">Uso comercial</span>
                            <h2>Use esse radar para provar valor.</h2>
                        </div>
                        <p className="section-copy">
                            Ranking com contexto ajuda a vender o produto para
                            novas assessorias: nao e so disputa, e densidade de
                            comunidade com visibilidade.
                        </p>
                        <Link href="/bandeira" className="btn btn-primary">
                            Abrir hub de bandeiras
                        </Link>
                    </article>
                </aside>
            </section>
        </div>
    )
}

'use client'

import { useEffect, useMemo, useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { api, Bandeira, BandeiraMember } from '@/lib/api'
import { useAuth } from '@/lib/auth'
import { buildCategoryBreakdown, getCategoryLabel } from '@/lib/dashboard'
import styles from './page.module.css'

type CategoryFilter = 'ALL' | Bandeira['category']

const filters: CategoryFilter[] = ['ALL', 'ASSESSORIA', 'GRUPO', 'ACADEMIA', 'BOX']

export default function BandeiraPage() {
    const router = useRouter()
    const { user, loadUser } = useAuth()
    const [bandeiras, setBandeiras] = useState<Bandeira[]>([])
    const [rankings, setRankings] = useState<Bandeira[]>([])
    const [members, setMembers] = useState<BandeiraMember[]>([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)
    const [searchTerm, setSearchTerm] = useState('')
    const [filter, setFilter] = useState<CategoryFilter>('ALL')
    const [joiningId, setJoiningId] = useState<string | null>(null)
    const [leaving, setLeaving] = useState(false)

    useEffect(() => {
        let isMounted = true

        const loadData = async () => {
            setLoading(true)
            setError(null)

            const [directoryResult, rankingsResult, membersResult] = await Promise.allSettled([
                api.getBandeiras(),
                api.getBandeiraRankings(),
                user?.bandeiraId
                    ? api.getBandeiraMembers(user.bandeiraId)
                    : Promise.resolve([] as BandeiraMember[]),
            ])

            if (!isMounted) return

            let failedRequests = 0

            if (directoryResult.status === 'fulfilled') setBandeiras(directoryResult.value)
            else failedRequests += 1

            if (rankingsResult.status === 'fulfilled') setRankings(rankingsResult.value)
            else failedRequests += 1

            if (membersResult.status === 'fulfilled') setMembers(membersResult.value)
            else failedRequests += 1

            if (failedRequests > 0) {
                setError('Parte da leitura de bandeiras não carregou. O diretório segue disponível.')
            }

            setLoading(false)
        }

        loadData()

        return () => {
            isMounted = false
        }
    }, [user?.bandeiraId])

    const currentBandeira =
        bandeiras.find((bandeira) => bandeira.id === user?.bandeiraId) ??
        rankings.find((bandeira) => bandeira.id === user?.bandeiraId) ??
        null

    const filteredBandeiras = useMemo(() => {
        return bandeiras.filter((bandeira) => {
            const matchesSearch =
                bandeira.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                (bandeira.description ?? '')
                    .toLowerCase()
                    .includes(searchTerm.toLowerCase())
            const matchesFilter =
                filter === 'ALL' ? true : bandeira.category === filter

            return matchesSearch && matchesFilter
        })
    }, [bandeiras, filter, searchTerm])

    const categoryBreakdown = useMemo(
        () => buildCategoryBreakdown(bandeiras),
        [bandeiras]
    )
    const topMembers = [...members]
        .sort((a, b) => b.totalTilesConquered - a.totalTilesConquered)
        .slice(0, 4)
    const currentRank =
        user?.bandeiraId != null
            ? rankings.findIndex((bandeira) => bandeira.id === user.bandeiraId) + 1
            : 0

    const handleJoin = async (id: string) => {
        if (!confirm('Deseja entrar nesta bandeira?')) return

        setJoiningId(id)
        try {
            await api.joinBandeira(id)
            await loadUser()
            router.push('/map')
        } catch {
            setError('Não foi possível entrar na bandeira agora.')
        } finally {
            setJoiningId(null)
        }
    }

    const handleLeave = async () => {
        if (!confirm('Deseja sair da sua bandeira atual?')) return

        setLeaving(true)
        try {
            await api.leaveBandeira()
            await loadUser()
            setMembers([])
        } catch {
            setError('Não foi possível sair da bandeira agora.')
        } finally {
            setLeaving(false)
        }
    }

    if (loading) {
        return (
            <div className={styles.loading}>
                <div className="spinner"></div>
                <span>Carregando hub de bandeiras...</span>
            </div>
        )
    }

    return (
        <div className={styles.page}>
            <section className={styles.hero}>
                <div className="section-header">
                    <span className="section-kicker">Hub de bandeiras</span>
                    <h1 className="section-title">
                        O lugar para gerir a equipe atual e atrair novas comunidades.
                    </h1>
                    <p className="section-copy">
                        Aqui a bandeira deixa de ser um detalhe do jogo. Ela
                        vira entidade de descoberta, posicionamento e expansão
                        para grupos e assessorias.
                    </p>
                </div>

                <aside className={`${styles.heroCard} panel panel-strong`}>
                    {currentBandeira ? (
                        <>
                            <span className="metric-label">Sua bandeira</span>
                            <strong className="metric-value">{currentBandeira.name}</strong>
                            <span className="metric-detail">
                                {getCategoryLabel(currentBandeira.category)}{' '}
                                {currentRank > 0 ? `- ranking #${currentRank}` : ''}
                            </span>

                            <div className={styles.heroCardStats}>
                                <div>
                                    <span>Membros</span>
                                    <strong>{currentBandeira.memberCount}</strong>
                                </div>
                                <div>
                                    <span>Tiles</span>
                                    <strong>{currentBandeira.totalTiles}</strong>
                                </div>
                                <div>
                                    <span>Rosters lidos</span>
                                    <strong>{members.length}</strong>
                                </div>
                            </div>

                            <button
                                onClick={handleLeave}
                                className="btn btn-secondary"
                                disabled={leaving}
                            >
                                {leaving ? 'Saindo...' : 'Sair da bandeira'}
                            </button>
                        </>
                    ) : (
                        <>
                            <span className="metric-label">Sem bandeira</span>
                            <strong className="metric-value">Escolha uma equipe</strong>
                            <span className="metric-detail">
                                Entrar em uma bandeira abre o radar competitivo e
                                a leitura coletiva do produto.
                            </span>
                            <Link href="/rankings" className="btn btn-primary">
                                Ver radar competitivo
                            </Link>
                        </>
                    )}
                </aside>
            </section>

            {error && <div className={styles.banner}>{error}</div>}

            <section className={styles.contentGrid}>
                <div className={styles.mainColumn}>
                    {currentBandeira && (
                        <article className="panel">
                            <div className="section-header">
                                <span className="section-kicker">Equipe atual</span>
                                <h2>{currentBandeira.name}</h2>
                            </div>

                            <div className={styles.currentGrid}>
                                <div className={styles.currentIntro}>
                                    <span className="tag tag-accent">
                                        {getCategoryLabel(currentBandeira.category)}
                                    </span>
                                    <p>
                                        {currentBandeira.description ??
                                            'Sua equipe ainda não cadastrou uma descrição pública.'}
                                    </p>
                                </div>

                                <div className={styles.membersList}>
                                    {topMembers.length > 0 ? (
                                        topMembers.map((member) => (
                                            <div key={member.id} className={styles.memberRow}>
                                                <div>
                                                    <strong>{member.username}</strong>
                                                    <span>{member.role}</span>
                                                </div>
                                                <strong>{member.totalTilesConquered} tiles</strong>
                                            </div>
                                        ))
                                    ) : (
                                        <div className="empty-state">
                                            <strong>Roster ainda não carregado.</strong>
                                            <span>
                                                Quando houver membros ativos,
                                                eles aparecem aqui para leitura rápida.
                                            </span>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </article>
                    )}

                    <article className="panel">
                        <div className={styles.directoryHeader}>
                            <div className="section-header">
                                <span className="section-kicker">Diretório</span>
                                <h2>Descubra comunidades por nome e categoria.</h2>
                            </div>

                            <input
                                type="text"
                                className="input"
                                placeholder="Buscar bandeira, assessoria ou grupo..."
                                value={searchTerm}
                                onChange={(event) => setSearchTerm(event.target.value)}
                            />
                        </div>

                        <div className={styles.filterRow}>
                            {filters.map((item) => (
                                <button
                                    key={item}
                                    type="button"
                                    className={`${styles.filterButton} ${
                                        filter === item ? styles.filterButtonActive : ''
                                    }`}
                                    onClick={() => setFilter(item)}
                                >
                                    {item === 'ALL' ? 'Todas' : getCategoryLabel(item)}
                                </button>
                            ))}
                        </div>

                        <div className={styles.cardGrid}>
                            {filteredBandeiras.map((bandeira) => (
                                <article key={bandeira.id} className={styles.bandeiraCard}>
                                    <div className={styles.cardTop}>
                                        <span
                                            className={styles.colorDot}
                                            style={{ backgroundColor: bandeira.color }}
                                        />
                                        <div>
                                            <h3>{bandeira.name}</h3>
                                            <span>{getCategoryLabel(bandeira.category)}</span>
                                        </div>
                                    </div>

                                    <p>
                                        {bandeira.description ??
                                            'Descrição pública ainda não cadastrada.'}
                                    </p>

                                    <div className={styles.cardMetrics}>
                                        <div>
                                            <span>Membros</span>
                                            <strong>{bandeira.memberCount}</strong>
                                        </div>
                                        <div>
                                            <span>Tiles</span>
                                            <strong>{bandeira.totalTiles}</strong>
                                        </div>
                                    </div>

                                    {!user?.bandeiraId ? (
                                        <button
                                            className="btn btn-primary btn-sm"
                                            onClick={() => handleJoin(bandeira.id)}
                                            disabled={joiningId === bandeira.id}
                                        >
                                            {joiningId === bandeira.id ? 'Entrando...' : 'Entrar na bandeira'}
                                        </button>
                                    ) : (
                                        <span className="tag">Você já está em uma bandeira</span>
                                    )}
                                </article>
                            ))}

                            {filteredBandeiras.length === 0 && (
                                <div className="empty-state">
                                    <strong>Nenhuma bandeira encontrada.</strong>
                                    <span>
                                        Ajuste a busca ou explore outra categoria.
                                    </span>
                                </div>
                            )}
                        </div>
                    </article>
                </div>

                <aside className={styles.sideColumn}>
                    <article className="panel">
                        <div className="section-header">
                            <span className="section-kicker">Mercado local</span>
                            <h2>Onde estão as oportunidades.</h2>
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

                    <article className="panel panel-dark">
                        <div className="section-header">
                            <span className="section-kicker">Atração</span>
                            <h2>Como vender melhor a plataforma.</h2>
                        </div>
                        <div className="list">
                            <div className="list-item">
                                <div>
                                    <div className="list-title">Assessoria</div>
                                    <div className="list-subtle">
                                        Precisa de visão coletiva, marca e recorrência.
                                    </div>
                                </div>
                            </div>
                            <div className="list-item">
                                <div>
                                    <div className="list-title">Crew ou grupo</div>
                                    <div className="list-subtle">
                                        Quer identidade, ranking e leitura dos membros ativos.
                                    </div>
                                </div>
                            </div>
                        </div>
                        <Link href="/map" className="btn btn-secondary">
                            Voltar ao painel
                        </Link>
                    </article>
                </aside>
            </section>
        </div>
    )
}

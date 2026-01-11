'use client'

import { useState, useEffect } from 'react'
import { api, Bandeira } from '@/lib/api'
import { useAuth } from '@/lib/auth'
import styles from './page.module.css'
import { useRouter } from 'next/navigation'

export default function BandeiraPage() {
    const { user, mutateUser } = useAuth()
    const router = useRouter()
    const [bandeiras, setBandeiras] = useState<Bandeira[]>([])
    const [loading, setLoading] = useState(true)
    const [searchTerm, setSearchTerm] = useState('')
    const [joiningId, setJoiningId] = useState<string | null>(null)

    useEffect(() => {
        loadBandeiras()
    }, [])

    const loadBandeiras = async () => {
        try {
            const data = await api.getBandeiras()
            setBandeiras(data)
        } catch (error) {
            console.error('Failed to load bandeiras:', error)
        } finally {
            setLoading(false)
        }
    }

    const handleJoin = async (id: string) => {
        if (!confirm('Tem certeza que deseja entrar nesta bandeira?')) return

        setJoiningId(id)
        try {
            await api.joinBandeira(id)
            await mutateUser() // Refresh user data to update bandeira status
            router.push('/profile')
        } catch (error) {
            console.error('Failed to join bandeira:', error)
            alert('Erro ao entrar na bandeira.')
        } finally {
            setJoiningId(null)
        }
    }

    const handleLeave = async () => {
        if (!confirm('Tem certeza que deseja sair da sua bandeira atual?')) return

        try {
            await api.leaveBandeira()
            await mutateUser()
        } catch (error) {
            console.error('Failed to leave bandeira:', error)
            alert('Erro ao sair da bandeira.')
        }
    }

    const filteredBandeiras = bandeiras.filter(b =>
        b.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        b.category.toLowerCase().includes(searchTerm.toLowerCase())
    )

    if (loading) {
        return (
            <div className={styles.loading}>
                <div className={styles.spinner}></div>
            </div>
        )
    }

    return (
        <div className={styles.container}>
            <h1 className={styles.title}>Bandeiras</h1>

            {user?.bandeiraId && (
                <div className={styles.currentBandeira}>
                    <h3>Sua Bandeira Atual</h3>
                    <div className={styles.myBandeiraCard}>
                        <div className={styles.cardHeader}>
                            <span
                                className={styles.colorDot}
                                style={{ backgroundColor: bandeiras.find(b => b.id === user.bandeiraId)?.color || '#ccc' }}
                            />
                            <span className={styles.myBandeiraName}>{user.bandeiraName}</span>
                        </div>
                        <button onClick={handleLeave} className="btn btn-outline btn-sm btn-danger">
                            Sair da Bandeira
                        </button>
                    </div>
                </div>
            )}

            <div className={styles.searchSection}>
                <input
                    type="text"
                    placeholder="Buscar bandeira..."
                    className={styles.searchInput}
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                />
            </div>

            <div className={styles.grid}>
                {filteredBandeiras.map(bandeira => (
                    <div key={bandeira.id} className={styles.card}>
                        <div
                            className={styles.cardHeader}
                            style={{ borderLeftColor: bandeira.color }}
                        >
                            <h3 className={styles.cardTitle}>{bandeira.name}</h3>
                            <span className={styles.categoryBadge}>{bandeira.category}</span>
                        </div>

                        <p className={styles.description}>{bandeira.description || 'Sem descrição.'}</p>

                        <div className={styles.statsRow}>
                            <div className={styles.stat}>
                                <span className={styles.statVal}>{bandeira.totalMembers}</span>
                                <span className={styles.statLbl}>Membros</span>
                            </div>
                            <div className={styles.stat}>
                                <span className={styles.statVal}>{bandeira.totalTiles}</span>
                                <span className={styles.statLbl}>Tiles</span>
                            </div>
                        </div>

                        {!user?.bandeiraId && (
                            <button
                                className="btn btn-primary btn-sm btn-block"
                                onClick={() => handleJoin(bandeira.id)}
                                disabled={joiningId === bandeira.id}
                            >
                                {joiningId === bandeira.id ? 'Entrando...' : 'Entrar'}
                            </button>
                        )}
                    </div>
                ))}

                {filteredBandeiras.length === 0 && (
                    <div className={styles.empty}>
                        Nenhuma bandeira encontrada.
                    </div>
                )}
            </div>

            {!user?.bandeiraId && (
                <div className={styles.createSection}>
                    <p>Não encontrou sua equipe?</p>
                    <button className="btn btn-outline" disabled>Criar Nova Bandeira (Em breve)</button>
                </div>
            )}
        </div>
    )
}

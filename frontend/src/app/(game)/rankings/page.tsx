'use client'

import { useState, useEffect } from 'react'
import { api, Bandeira } from '@/lib/api'
import styles from './page.module.css'

export default function RankingsPage() {
    const [bandeiras, setBandeiras] = useState<Bandeira[]>([])
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        const loadRankings = async () => {
            try {
                const data = await api.getBandeiraRankings()
                setBandeiras(data)
            } catch (error) {
                console.error('Failed to load rankings:', error)
            } finally {
                setLoading(false)
            }
        }
        loadRankings()
    }, [])

    if (loading) {
        return (
            <div className={styles.loading}>
                <div className={styles.spinner}></div>
                <span>Carregando rankings...</span>
            </div>
        )
    }

    return (
        <div className={styles.container}>
            <h1 className={styles.title}>🏆 Classificação</h1>

            <div className={styles.card}>
                <div className={styles.header}>
                    <div className={styles.colPos}>#</div>
                    <div className={styles.colName}>Bandeira</div>
                    <div className={styles.colTiles}>Território</div>
                </div>

                <div className={styles.list}>
                    {bandeiras.length === 0 ? (
                        <div className={styles.empty}>
                            Nenhuma bandeira encontrada.
                        </div>
                    ) : (
                        bandeiras.map((bandeira, index) => (
                            <div key={bandeira.id} className={styles.item}>
                                <div className={styles.colPos}>
                                    <span className={`${styles.pos} ${index < 3 ? styles[`pos${index + 1}`] : ''}`}>
                                        {index + 1}
                                    </span>
                                </div>
                                <div className={styles.colName}>
                                    <div className={styles.bandeiraInfo}>
                                        <span
                                            className={styles.colorDot}
                                            style={{ backgroundColor: bandeira.color }}
                                        />
                                        <div className={styles.nameBlock}>
                                            <span className={styles.bandeiraName}>{bandeira.name}</span>
                                            <span className={styles.bandeiraCategory}>{bandeira.category}</span>
                                        </div>
                                    </div>
                                </div>
                                <div className={styles.colTiles}>
                                    <span className={styles.tilesValue}>{bandeira.totalTiles}</span>
                                    <span className={styles.tilesLabel}>tiles</span>
                                </div>
                            </div>
                        ))
                    )}
                </div>
            </div>
        </div>
    )
}

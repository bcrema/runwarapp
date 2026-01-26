'use client'

import { useState, useEffect } from 'react'
import { useSearchParams } from 'next/navigation'
import dynamic from 'next/dynamic'
import { api, Tile, TileStats, DailyStatus } from '@/lib/api'
import { useAuth } from '@/lib/auth'
import styles from './page.module.css'

// Dynamic import for map (no SSR)
const HexMap = dynamic(() => import('@/components/map/HexMap'), {
    ssr: false,
    loading: () => (
        <div className={styles.mapLoading}>
            <div className={styles.spinner}></div>
            <span>Carregando mapa...</span>
        </div>
    ),
})

export default function MapPage() {
    const { user } = useAuth()
    const searchParams = useSearchParams()
    const [stats, setStats] = useState<TileStats | null>(null)
    const [dailyStatus, setDailyStatus] = useState<DailyStatus | null>(null)
    const [selectedTile, setSelectedTile] = useState<Tile | null>(null)

    const focusTileId = searchParams.get('tile')

    useEffect(() => {
        const loadData = async () => {
            try {
                const [statsData, statusData] = await Promise.all([
                    api.getTileStats(),
                    api.getDailyStatus(),
                ])
                setStats(statsData)
                setDailyStatus(statusData)
            } catch (error) {
                console.error('Failed to load stats:', error)
            }
        }
        loadData()
    }, [])

    const handleTileClick = (tile: Tile) => {
        setSelectedTile(tile)
    }

    return (
        <div className={styles.container}>
            {/* Stats Bar */}
            <div className={styles.statsBar}>
                <div className={styles.statItem}>
                    <span className={styles.statValue}>{user?.totalTilesConquered || 0}</span>
                    <span className={styles.statLabel}>Seus Tiles</span>
                </div>
                <div className={styles.statItem}>
                    <span className={styles.statValue}>{dailyStatus?.userActionsRemaining ?? 3}</span>
                    <span className={styles.statLabel}>Ações Hoje</span>
                </div>
                <div className={styles.statItem}>
                    <span className={`${styles.statValue} ${styles.disputeValue}`}>
                        {stats?.tilesInDispute || 0}
                    </span>
                    <span className={styles.statLabel}>Em Disputa</span>
                </div>
                <div className={styles.statItem}>
                    <span className={styles.statValue}>{stats?.ownedTiles || 0}</span>
                    <span className={styles.statLabel}>Total Tiles</span>
                </div>
            </div>

            {/* Map */}
            <div className={styles.mapContainer}>
                <HexMap onTileClick={handleTileClick} focusTileId={focusTileId} />
            </div>

            {/* Legend */}
            <div className={styles.legend}>
                <h4>Legenda</h4>
                <div className={styles.legendItems}>
                    <div className={styles.legendItem}>
                        <span className={styles.legendColor} style={{ backgroundColor: '#6b7280' }}></span>
                        <span>Neutro</span>
                    </div>
                    <div className={styles.legendItem}>
                        <span className={styles.legendColor} style={{ backgroundColor: '#6366f1' }}></span>
                        <span>Dominado</span>
                    </div>
                    <div className={styles.legendItem}>
                        <span className={styles.legendColor} style={{ backgroundColor: '#f59e0b' }}></span>
                        <span>Em Disputa</span>
                    </div>
                </div>
            </div>
        </div>
    )
}

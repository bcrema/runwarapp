'use client'

import { useAuth } from '@/lib/auth'
import styles from './page.module.css'
import Link from 'next/link'

export default function ProfilePage() {
    const { user, isLoading } = useAuth()

    if (isLoading) {
        return (
            <div className={styles.loading}>
                <div className={styles.spinner}></div>
            </div>
        )
    }

    if (!user) {
        return (
            <div className={styles.container}>
                <div className={styles.card}>
                    <p>Você precisa estar logado para ver seu perfil.</p>
                    <Link href="/login" className="btn btn-primary">Fazer Login</Link>
                </div>
            </div>
        )
    }

    return (
        <div className={styles.container}>
            <h1 className={styles.title}>Meu Perfil</h1>

            <div className={styles.profileHeader}>
                <div className={styles.avatar}>
                    {user.username.substring(0, 2).toUpperCase()}
                </div>
                <div className={styles.identity}>
                    <h2 className={styles.username}>@{user.username}</h2>
                    <span className={styles.email}>{user.email}</span>
                </div>
            </div>

            {user.bandeiraName ? (
                <div className={styles.bandeiraCard}>
                    <span className={styles.bandeiraLabel}>Membro de</span>
                    <h3 className={styles.bandeiraName}>{user.bandeiraName}</h3>
                    <span className={styles.roleTag}>{user.role === 'ADMIN' ? 'Capitão' : 'Membro'}</span>
                </div>
            ) : (
                <div className={styles.noBandeira}>
                    <p>Você ainda não faz parte de uma bandeira.</p>
                    <Link href="/bandeira" className="btn btn-outline btn-sm">Encontrar uma Bandeira</Link>
                </div>
            )}

            <div className={styles.statsGrid}>
                <div className={styles.statCard}>
                    <span className={styles.statValue}>{formatDistance(user.totalDistance)}</span>
                    <span className={styles.statLabel}>Distância Total</span>
                </div>

                <div className={styles.statCard}>
                    <span className={styles.statValue}>{user.totalRuns}</span>
                    <span className={styles.statLabel}>Corridas</span>
                </div>

                <div className={styles.statCard}>
                    <span className={styles.statValue}>{user.totalTilesConquered}</span>
                    <span className={styles.statLabel}>Tiles Conquistados</span>
                </div>
            </div>

            <div className={styles.actions}>
                <button className="btn btn-secondary btn-block" disabled>Editar Perfil</button>
            </div>
        </div>
    )
}

function formatDistance(meters: number): string {
    if (meters >= 1000) {
        return `${(meters / 1000).toFixed(1)} km`
    }
    return `${Math.round(meters)} m`
}

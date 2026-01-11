'use client'

import { useEffect } from 'react'
import { useRouter, usePathname } from 'next/navigation'
import Link from 'next/link'
import { useAuth } from '@/lib/auth'
import styles from './layout.module.css'

export default function GameLayout({
    children,
}: {
    children: React.ReactNode
}) {
    const router = useRouter()
    const pathname = usePathname()
    const { user, isLoading, isAuthenticated, loadUser, logout } = useAuth()

    useEffect(() => {
        loadUser()
    }, [loadUser])

    useEffect(() => {
        if (!isLoading && !isAuthenticated) {
            router.push('/login')
        }
    }, [isLoading, isAuthenticated, router])

    if (isLoading) {
        return (
            <div className={styles.loading}>
                <div className={styles.spinner}></div>
                <span>Carregando...</span>
            </div>
        )
    }

    if (!isAuthenticated) {
        return null
    }

    const navItems = [
        { href: '/map', label: '🗺️ Mapa', icon: '🗺️' },
        { href: '/run', label: '🏃 Corrida', icon: '🏃' },
        { href: '/rankings', label: '🏆 Rankings', icon: '🏆' },
        { href: '/bandeira', label: '🚩 Bandeira', icon: '🚩' },
        { href: '/profile', label: '👤 Perfil', icon: '👤' },
    ]

    return (
        <div className={styles.layout}>
            {/* Top Header */}
            <header className={styles.header}>
                <Link href="/map" className={styles.logo}>
                    <span className={styles.logoAccent}>Run</span>War
                </Link>

                <div className={styles.userInfo}>
                    {user?.bandeiraName && (
                        <span className={styles.bandeira}>
                            🚩 {user.bandeiraName}
                        </span>
                    )}
                    <span className={styles.username}>{user?.username}</span>
                    <button onClick={logout} className={styles.logoutBtn}>
                        Sair
                    </button>
                </div>
            </header>

            {/* Main Content */}
            <main className={styles.main}>
                {children}
            </main>

            {/* Bottom Navigation (Mobile) */}
            <nav className={styles.bottomNav}>
                {navItems.map((item) => (
                    <Link
                        key={item.href}
                        href={item.href}
                        className={`${styles.navItem} ${pathname === item.href ? styles.navItemActive : ''}`}
                    >
                        <span className={styles.navIcon}>{item.icon}</span>
                        <span className={styles.navLabel}>{item.label.split(' ')[1]}</span>
                    </Link>
                ))}
            </nav>
        </div>
    )
}

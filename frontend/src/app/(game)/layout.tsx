'use client'

import { useEffect } from 'react'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { useAuth } from '@/lib/auth'
import { formatDistance, getRoleLabel } from '@/lib/dashboard'
import styles from './layout.module.css'

const navItems = [
    { href: '/map', label: 'Painel' },
    { href: '/run', label: 'Sessões' },
    { href: '/rankings', label: 'Radar' },
    { href: '/bandeira', label: 'Bandeira' },
    { href: '/profile', label: 'Perfil' },
]

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
                <div className="spinner"></div>
                <span>Carregando seu painel...</span>
            </div>
        )
    }

    if (!isAuthenticated) {
        return null
    }

    return (
        <div className={styles.layout}>
            <header className={styles.header}>
                <div className={styles.headerInner}>
                    <div className={styles.brandBlock}>
                        <Link href="/map" className={styles.logo}>
                            <span className={styles.logoAccent}>Liga</span>Run
                        </Link>
                        <div className={styles.brandCopy}>
                            <span className={styles.brandEyebrow}>Control Center</span>
                            <p>Corredor, bandeira e expansão local no mesmo painel.</p>
                        </div>
                    </div>

                    <nav className={styles.desktopNav} aria-label="Navegação principal">
                        {navItems.map((item) => (
                            <Link
                                key={item.href}
                                href={item.href}
                                className={`${styles.navLink} ${
                                    pathname === item.href ? styles.navLinkActive : ''
                                }`}
                            >
                                {item.label}
                            </Link>
                        ))}
                    </nav>

                    <div className={styles.userRail}>
                        <div className={styles.userCard}>
                            <span className={styles.userLabel}>Corredor</span>
                            <strong>{user?.username}</strong>
                            <span className={styles.userMeta}>
                                {formatDistance(user?.totalDistance ?? 0)} no histórico
                            </span>
                        </div>

                        <div className={styles.userCard}>
                            <span className={styles.userLabel}>Bandeira</span>
                            <strong>{user?.bandeiraName ?? 'Sem bandeira'}</strong>
                            <span className={styles.userMeta}>{getRoleLabel(user?.role ?? 'MEMBER')}</span>
                        </div>

                        <button onClick={logout} className="btn btn-secondary btn-sm">
                            Sair
                        </button>
                    </div>
                </div>
            </header>

            <main className={styles.main}>
                <div className="page-shell">{children}</div>
            </main>

            <nav className={styles.bottomNav} aria-label="Navegação mobile">
                {navItems.map((item) => (
                    <Link
                        key={item.href}
                        href={item.href}
                        className={`${styles.bottomNavItem} ${
                            pathname === item.href ? styles.bottomNavItemActive : ''
                        }`}
                    >
                        {item.label}
                    </Link>
                ))}
            </nav>
        </div>
    )
}

'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useAuth } from '@/lib/auth'
import styles from '../auth.module.css'

export default function LoginPage() {
    const router = useRouter()
    const { login } = useAuth()
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [error, setError] = useState('')
    const [isLoading, setIsLoading] = useState(false)

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setError('')
        setIsLoading(true)

        try {
            await login(email, password)
            router.push('/map')
        } catch (err: any) {
            setError(err.message || 'Erro ao fazer login')
        } finally {
            setIsLoading(false)
        }
    }

    return (
        <main className={styles.main}>
            <div className={styles.shell}>
                <aside className={styles.aside}>
                    <div className={styles.asideTop}>
                        <Link href="/" className={styles.logo}>
                            <span className={styles.logoAccent}>Liga</span>Run
                        </Link>
                        <span className={styles.eyebrow}>Painel Analitico</span>
                        <h2 className={styles.asideTitle}>
                            Volte para o comando da sua rotina.
                        </h2>
                        <p className={styles.asideCopy}>
                            A web concentra desempenho, bandeira, comunidade e
                            oportunidades para grupos e assessorias.
                        </p>
                    </div>

                    <div className={styles.asideList}>
                        <div className={styles.asideItem}>
                            <strong>Visao do corredor</strong>
                            <span>Distancia, ritmo, consistencia e impacto territorial.</span>
                        </div>
                        <div className={styles.asideItem}>
                            <strong>Visao da bandeira</strong>
                            <span>Membros ativos, ranking e presenca por categoria.</span>
                        </div>
                        <div className={styles.asideItem}>
                            <strong>Visao de crescimento</strong>
                            <span>Um funil claro para atrair novos grupos, crews e assessorias.</span>
                        </div>
                    </div>
                </aside>

                <div className={styles.container}>
                    <div className={styles.header}>
                        <h1>Entrar</h1>
                        <p>Abra o painel do corredor e da bandeira.</p>
                    </div>

                    <form onSubmit={handleSubmit} className={styles.form}>
                        {error && <div className={styles.error}>{error}</div>}

                        <div className="form-group">
                            <label className="label" htmlFor="email">
                                Email
                            </label>
                            <input
                                type="email"
                                id="email"
                                className="input"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                placeholder="seu@email.com"
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label className="label" htmlFor="password">
                                Senha
                            </label>
                            <input
                                type="password"
                                id="password"
                                className="input"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                placeholder="********"
                                required
                            />
                        </div>

                        <button
                            type="submit"
                            className="btn btn-primary btn-lg"
                            disabled={isLoading}
                        >
                            {isLoading ? 'Entrando...' : 'Entrar'}
                        </button>
                    </form>

                    <div className={styles.footer}>
                        <p>
                            Nao tem uma conta? <Link href="/register">Criar conta</Link>
                        </p>
                    </div>
                </div>
            </div>
        </main>
    )
}

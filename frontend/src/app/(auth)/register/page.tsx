'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useAuth } from '@/lib/auth'
import styles from '../auth.module.css'

export default function RegisterPage() {
    const router = useRouter()
    const { register } = useAuth()
    const [email, setEmail] = useState('')
    const [username, setUsername] = useState('')
    const [password, setPassword] = useState('')
    const [confirmPassword, setConfirmPassword] = useState('')
    const [error, setError] = useState('')
    const [isLoading, setIsLoading] = useState(false)

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setError('')

        if (password !== confirmPassword) {
            setError('As senhas nao coincidem')
            return
        }

        if (password.length < 6) {
            setError('A senha deve ter pelo menos 6 caracteres')
            return
        }

        if (username.length < 3) {
            setError('O nome de usuario deve ter pelo menos 3 caracteres')
            return
        }

        setIsLoading(true)

        try {
            await register(email, username, password)
            router.push('/map')
        } catch (err: any) {
            setError(err.message || 'Erro ao criar conta')
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
                        <span className={styles.eyebrow}>Onboarding</span>
                        <h2 className={styles.asideTitle}>
                            Leve sua corrida para uma camada mais estrategica.
                        </h2>
                        <p className={styles.asideCopy}>
                            Crie seu acesso para acompanhar evolucao pessoal,
                            descobrir bandeiras e abrir espaco para sua crew ou
                            assessoria.
                        </p>
                    </div>

                    <div className={styles.asideList}>
                        <div className={styles.asideItem}>
                            <strong>Corredores</strong>
                            <span>Centralize historico, metas e consistencia semanal.</span>
                        </div>
                        <div className={styles.asideItem}>
                            <strong>Grupos</strong>
                            <span>Mostrem atividade, ranking e presenca territorial.</span>
                        </div>
                        <div className={styles.asideItem}>
                            <strong>Assessorias</strong>
                            <span>Transformem alunos em comunidade visivel e acionavel.</span>
                        </div>
                    </div>
                </aside>

                <div className={styles.container}>
                    <div className={styles.header}>
                        <h1>Criar conta</h1>
                        <p>Monte seu acesso ao painel da comunidade de corrida.</p>
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
                            <label className="label" htmlFor="username">
                                Nome de usuario
                            </label>
                            <input
                                type="text"
                                id="username"
                                className="input"
                                value={username}
                                onChange={(e) => setUsername(e.target.value)}
                                placeholder="seu_nome"
                                minLength={3}
                                maxLength={30}
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
                                minLength={6}
                                required
                            />
                        </div>

                        <div className="form-group">
                            <label className="label" htmlFor="confirmPassword">
                                Confirmar senha
                            </label>
                            <input
                                type="password"
                                id="confirmPassword"
                                className="input"
                                value={confirmPassword}
                                onChange={(e) => setConfirmPassword(e.target.value)}
                                placeholder="********"
                                required
                            />
                        </div>

                        <button
                            type="submit"
                            className="btn btn-primary btn-lg"
                            disabled={isLoading}
                        >
                            {isLoading ? 'Criando conta...' : 'Criar conta'}
                        </button>
                    </form>

                    <div className={styles.footer}>
                        <p>
                            Ja tem uma conta? <Link href="/login">Entrar</Link>
                        </p>
                    </div>
                </div>
            </div>
        </main>
    )
}

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
            setError('As senhas não coincidem')
            return
        }

        if (password.length < 6) {
            setError('A senha deve ter pelo menos 6 caracteres')
            return
        }

        if (username.length < 3) {
            setError('O nome de usuário deve ter pelo menos 3 caracteres')
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
            <div className={styles.container}>
                <div className={styles.header}>
                    <Link href="/" className={styles.logo}>
                        <span className={styles.logoAccent}>Run</span>War
                    </Link>
                    <h1>Criar Conta</h1>
                    <p>Junte-se à batalha pelos territórios!</p>
                </div>

                <form onSubmit={handleSubmit} className={styles.form}>
                    {error && (
                        <div className={styles.error}>
                            {error}
                        </div>
                    )}

                    <div className="form-group">
                        <label className="label" htmlFor="email">Email</label>
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
                        <label className="label" htmlFor="username">Nome de Usuário</label>
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
                        <label className="label" htmlFor="password">Senha</label>
                        <input
                            type="password"
                            id="password"
                            className="input"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="••••••••"
                            minLength={6}
                            required
                        />
                    </div>

                    <div className="form-group">
                        <label className="label" htmlFor="confirmPassword">Confirmar Senha</label>
                        <input
                            type="password"
                            id="confirmPassword"
                            className="input"
                            value={confirmPassword}
                            onChange={(e) => setConfirmPassword(e.target.value)}
                            placeholder="••••••••"
                            required
                        />
                    </div>

                    <button
                        type="submit"
                        className="btn btn-primary btn-lg"
                        disabled={isLoading}
                        style={{ width: '100%' }}
                    >
                        {isLoading ? 'Criando conta...' : 'Criar Conta'}
                    </button>
                </form>

                <div className={styles.footer}>
                    <p>
                        Já tem uma conta?{' '}
                        <Link href="/login">Entrar</Link>
                    </p>
                </div>
            </div>
        </main>
    )
}

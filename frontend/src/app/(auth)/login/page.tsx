'use client'

import { useState } from 'react'
import type { FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useAuth } from '@/lib/auth'
import SocialAuthButtons from '@/components/social-auth/SocialAuthButtons'
import { LinkRequiredError, LinkRequiredPayload, SocialExchangeRequest } from '@/lib/api'
import styles from '../auth.module.css'
import socialStyles from '@/components/social-auth/social-auth.module.css'

export default function LoginPage() {
    const router = useRouter()
    const { login, socialAuthenticate, linkSocialAccount } = useAuth()
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [error, setError] = useState('')
    const [isLoading, setIsLoading] = useState(false)
    const [socialError, setSocialError] = useState('')
    const [linkContext, setLinkContext] = useState<LinkRequiredPayload | null>(null)
    const [linkState, setLinkState] = useState({
        email: '',
        password: '',
        error: '',
        isLoading: false,
    })

    const handleSocialSuccess = () => {
        router.push('/map')
    }

    const handleSocialError = (err: Error) => {
        if (err instanceof LinkRequiredError) {
            setLinkContext(err.payload)
            setLinkState((prev) => ({
                ...prev,
                email: '',
                password: '',
                error: '',
                isLoading: false,
            }))
            return
        }
        setSocialError(err.message || 'Erro ao autenticar com redes sociais.')
    }

    const handleSocialSignIn = async (payload: SocialExchangeRequest) => {
        setSocialError('')
        try {
            await socialAuthenticate(payload)
            handleSocialSuccess()
        } catch (err: any) {
            handleSocialError(err)
        }
    }

    const handleLinkSubmit = async (event: FormEvent) => {
        event.preventDefault()
        if (!linkContext) return
        setLinkState((prev) => ({ ...prev, isLoading: true, error: '' }))
        try {
            await linkSocialAccount({
                linkToken: linkContext.linkToken,
                email: linkState.email,
                password: linkState.password,
            })
            handleSocialSuccess()
        } catch (err: any) {
            setLinkState((prev) => ({
                ...prev,
                error: err?.message || 'Erro ao vincular conta.',
            }))
        } finally {
            setLinkState((prev) => ({ ...prev, isLoading: false }))
        }
    }

    const handleLinkCancel = () => {
        setLinkContext(null)
        setLinkState({ email: '', password: '', error: '', isLoading: false })
    }

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

                    <div className={socialStyles.wrapper}>
                        <SocialAuthButtons
                            onSocialSignIn={handleSocialSignIn}
                            onError={handleSocialError}
                        />
                        {socialError && <div className={styles.error}>{socialError}</div>}
                        {linkContext && (
                            <div className={socialStyles.linkBox}>
                                <p>
                                    Ja existe uma conta com {linkContext.emailMasked ?? 'este email'}.
                                    Insira a senha para vincular as identidades.
                                </p>
                                {linkState.error && <p className={socialStyles.linkError}>{linkState.error}</p>}
                                <form className={socialStyles.linkForm} onSubmit={handleLinkSubmit}>
                                    <input
                                        type="email"
                                        className={socialStyles.linkInput}
                                        placeholder="Email"
                                        value={linkState.email}
                                        onChange={(e) =>
                                            setLinkState((prev) => ({ ...prev, email: e.target.value }))
                                        }
                                        required
                                    />
                                    <input
                                        type="password"
                                        className={socialStyles.linkInput}
                                        placeholder="Senha"
                                        value={linkState.password}
                                        onChange={(e) =>
                                            setLinkState((prev) => ({ ...prev, password: e.target.value }))
                                        }
                                        required
                                    />
                                    <div className={socialStyles.linkActions}>
                                        <button
                                            type="submit"
                                            className="btn btn-primary btn-sm"
                                            disabled={linkState.isLoading}
                                        >
                                            {linkState.isLoading ? 'Vinculando...' : 'Vincular conta'}
                                        </button>
                                        <button
                                            type="button"
                                            className="btn btn-secondary btn-sm"
                                            onClick={handleLinkCancel}
                                        >
                                            Cancelar
                                        </button>
                                    </div>
                                </form>
                            </div>
                        )}
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

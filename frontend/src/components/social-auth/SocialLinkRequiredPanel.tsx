'use client'

import { FormEvent, useEffect, useRef } from 'react'
import { LinkRequiredPayload } from '@/lib/api'
import styles from './social-auth.module.css'

interface LinkState {
    email: string
    password: string
    error: string
    isLoading: boolean
}

interface SocialLinkRequiredPanelProps {
    linkContext: LinkRequiredPayload
    linkState: LinkState
    providerLabel: string
    onSubmit: (event: FormEvent<HTMLFormElement>) => Promise<void> | void
    onCancel: () => void
    onEmailChange: (value: string) => void
    onPasswordChange: (value: string) => void
}

export default function SocialLinkRequiredPanel({
    linkContext,
    linkState,
    providerLabel,
    onSubmit,
    onCancel,
    onEmailChange,
    onPasswordChange,
}: SocialLinkRequiredPanelProps) {
    const containerRef = useRef<HTMLDivElement | null>(null)
    const emailInputRef = useRef<HTMLInputElement | null>(null)

    useEffect(() => {
        containerRef.current?.scrollIntoView?.({ behavior: 'smooth', block: 'center' })
        emailInputRef.current?.focus()
    }, [])

    return (
        <section
            ref={containerRef}
            className={styles.linkBox}
            role="alert"
            aria-live="assertive"
        >
            <div className={styles.linkBadge}>Acao necessaria</div>
            <div className={styles.linkHeader}>
                <h3>Confirme sua conta para continuar com {providerLabel}</h3>
                <p>
                    Encontramos uma conta RunWar existente em{' '}
                    <strong>{linkContext.emailMasked ?? 'este email'}</strong>.
                    Informe o email completo e a senha dessa conta para liberar o login social.
                </p>
            </div>

            <div className={styles.linkChecklist}>
                <div className={styles.linkChecklistItem}>1. Digite o email da conta existente.</div>
                <div className={styles.linkChecklistItem}>2. Informe a senha atual dessa conta.</div>
                <div className={styles.linkChecklistItem}>3. Clique em Vincular e entrar.</div>
            </div>

            {linkState.error && <p className={styles.linkError}>{linkState.error}</p>}

            <form className={styles.linkForm} onSubmit={onSubmit}>
                <input
                    ref={emailInputRef}
                    type="email"
                    className={styles.linkInput}
                    placeholder="Email da conta existente"
                    value={linkState.email}
                    onChange={(event) => onEmailChange(event.target.value)}
                    required
                />
                <input
                    type="password"
                    className={styles.linkInput}
                    placeholder="Senha atual da conta"
                    value={linkState.password}
                    onChange={(event) => onPasswordChange(event.target.value)}
                    required
                />
                <div className={styles.linkActions}>
                    <button
                        type="submit"
                        className={`${styles.linkButton} ${styles.linkButtonPrimary}`}
                        disabled={linkState.isLoading}
                    >
                        {linkState.isLoading ? 'Vinculando...' : 'Vincular e entrar'}
                    </button>
                    <button
                        type="button"
                        className={`${styles.linkButton} ${styles.linkButtonSecondary}`}
                        onClick={onCancel}
                    >
                        Cancelar
                    </button>
                </div>
            </form>
        </section>
    )
}

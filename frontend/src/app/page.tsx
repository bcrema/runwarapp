'use client'

import Link from 'next/link'
import styles from './page.module.css'

export default function Home() {
    return (
        <main className={styles.main}>
            {/* Hero Section */}
            <section className={styles.hero}>
                <div className={styles.heroBackground}>
                    <div className={styles.hexGrid}></div>
                </div>

                <div className={styles.heroContent}>
                    <h1 className={styles.title}>
                        <span className={styles.titleAccent}>Run</span>War
                    </h1>
                    <p className={styles.tagline}>
                        Conquiste territórios correndo
                    </p>
                    <p className={styles.description}>
                        Transforme suas corridas em batalhas épicas. Conquiste tiles hexagonais,
                        defenda seu território e domine Curitiba com sua bandeira.
                    </p>

                    <div className={styles.cta}>
                        <Link href="/register" className="btn btn-primary btn-lg">
                            Começar Agora
                        </Link>
                        <Link href="/login" className="btn btn-secondary btn-lg">
                            Entrar
                        </Link>
                    </div>
                </div>
            </section>

            {/* Features Section */}
            <section className={styles.features}>
                <h2 className={styles.sectionTitle}>Como Funciona</h2>

                <div className={styles.featureGrid}>
                    <div className={`card ${styles.featureCard}`}>
                        <div className={styles.featureIcon}>🏃</div>
                        <h3>Corra Loops</h3>
                        <p>
                            Complete circuitos de pelo menos 1.2km para ganhar ações territoriais.
                            Quanto mais você corre, mais você conquista.
                        </p>
                    </div>

                    <div className={`card ${styles.featureCard}`}>
                        <div className={styles.featureIcon}>🗺️</div>
                        <h3>Conquiste Tiles</h3>
                        <p>
                            O mapa é dividido em hexágonos de ~250m. Corra dentro de um tile
                            para conquistá-lo ou atacar territórios rivais.
                        </p>
                    </div>

                    <div className={`card ${styles.featureCard}`}>
                        <div className={styles.featureIcon}>🛡️</div>
                        <h3>Defenda Território</h3>
                        <p>
                            Seus tiles têm um escudo que diminui com ataques. Corra para
                            defendê-los antes que sejam tomados.
                        </p>
                    </div>

                    <div className={`card ${styles.featureCard}`}>
                        <div className={styles.featureIcon}>🚩</div>
                        <h3>Junte-se a uma Bandeira</h3>
                        <p>
                            Entre para uma assessoria, academia ou grupo de corrida.
                            Conquiste território em equipe e domine o ranking.
                        </p>
                    </div>
                </div>
            </section>

            {/* Stats Preview */}
            <section className={styles.stats}>
                <div className={styles.statsGrid}>
                    <div className="stat">
                        <div className="stat-value">6.847</div>
                        <div className="stat-label">Tiles em Curitiba</div>
                    </div>
                    <div className="stat">
                        <div className="stat-value">250m</div>
                        <div className="stat-label">Raio do Tile</div>
                    </div>
                    <div className="stat">
                        <div className="stat-value">6</div>
                        <div className="stat-label">Semanas por Temporada</div>
                    </div>
                    <div className="stat">
                        <div className="stat-value">3</div>
                        <div className="stat-label">Ações por Dia</div>
                    </div>
                </div>
            </section>

            {/* Game Rules Preview */}
            <section className={styles.rules}>
                <h2 className={styles.sectionTitle}>Regras do Jogo</h2>

                <div className={styles.rulesGrid}>
                    <div className={styles.ruleCard}>
                        <span className="badge badge-conquest">Conquista</span>
                        <p>Tile neutro → Seu com <strong>100 de escudo</strong></p>
                    </div>

                    <div className={styles.ruleCard}>
                        <span className="badge badge-attack">Ataque</span>
                        <p>Tile rival → <strong>-35 de escudo</strong></p>
                    </div>

                    <div className={styles.ruleCard}>
                        <span className="badge badge-defense">Defesa</span>
                        <p>Seu tile → <strong>+20 de escudo</strong></p>
                    </div>

                    <div className={styles.ruleCard}>
                        <span className="badge badge-dispute">Disputa</span>
                        <p>Escudo abaixo de <strong>70</strong> = Em disputa!</p>
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer className={styles.footer}>
                <p>RunWar © 2026 - Conquiste seu território</p>
            </footer>
        </main>
    )
}

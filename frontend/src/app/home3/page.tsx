import Link from 'next/link'
import styles from './page.module.css'

export default function Home3() {
    return (
        <main className={styles.main}>
            <section className={styles.hero}>
                <div className={styles.heroBackground}></div>
                <div className={styles.heroContent}>
                    <span className={styles.kicker}>LigaRun Home 3</span>
                    <h1>Corrida, saúde e desafio em um mapa vivo.</h1>
                    <p>
                        LigaRun transforma suas rotas em áreas conquistadas. Você
                        corre, ganha ações diárias e disputa território com sua
                        bandeira em tempo real.
                    </p>
                    <div className={styles.heroActions}>
                        <Link href="/register" className="btn btn-primary btn-lg">
                            Começar agora
                        </Link>
                        <Link href="/login" className="btn btn-secondary btn-lg">
                            Entrar
                        </Link>
                        <Link href="/map" className="btn btn-secondary btn-lg">
                            Ver mapa
                        </Link>
                    </div>
                    <div className={styles.heroMetrics}>
                        <div>
                            <strong>3</strong>
                            <span>Ações por dia</span>
                        </div>
                        <div>
                            <strong>6</strong>
                            <span>Semanas por temporada</span>
                        </div>
                        <div>
                            <strong>6.847</strong>
                            <span>Áreas em Curitiba</span>
                        </div>
                    </div>
                </div>
            </section>

            <section className={styles.pillars}>
                <div className={styles.pillarGrid}>
                    <div className={styles.pillarCard}>
                        <span>🏃</span>
                        <h3>Corrida com propósito</h3>
                        <p>
                            Cada treino vira avanço real no mapa e incentiva
                            consistência.
                        </p>
                    </div>
                    <div className={styles.pillarCard}>
                        <span>⚡</span>
                        <h3>Desafio diário</h3>
                        <p>
                            Ações renovadas todos os dias para manter a disputa
                            ativa.
                        </p>
                    </div>
                    <div className={styles.pillarCard}>
                        <span>💚</span>
                        <h3>Saúde e bem-estar</h3>
                        <p>
                            Motivação extra para treinar e cuidar do corpo com
                            metas divertidas.
                        </p>
                    </div>
                    <div className={styles.pillarCard}>
                        <span>🤝</span>
                        <h3>Interação social</h3>
                        <p>
                            Jogue em equipe, convide amigos e fortaleça sua
                            bandeira.
                        </p>
                    </div>
                </div>
            </section>

            <section className={styles.steps}>
                <div className={styles.stepHeader}>
                    <h2>Um loop simples, um impacto gigante</h2>
                    <p>
                        Planeje suas rotas, registre o treino e veja o mapa mudar
                        em tempo real.
                    </p>
                </div>
                <div className={styles.stepGrid}>
                    <div>
                        <span className={styles.stepIndex}>01</span>
                        <h3>Escolha a área</h3>
                        <p>Defina onde atacar ou defender com sua bandeira.</p>
                    </div>
                    <div>
                        <span className={styles.stepIndex}>02</span>
                        <h3>Corra o loop</h3>
                        <p>Complete o circuito para ganhar ações territoriais.</p>
                    </div>
                    <div>
                        <span className={styles.stepIndex}>03</span>
                        <h3>Conquiste o mapa</h3>
                        <p>Capture áreas, aumente escudo e suba no ranking.</p>
                    </div>
                </div>
            </section>

            <section className={styles.map}>
                <div className={styles.mapCard}>
                    <div>
                        <h2>Mapa limpo, decisões rápidas</h2>
                        <p>
                            Um visual simples que mostra rapidamente onde sua
                            equipe está forte e onde o ataque é urgente.
                        </p>
                        <Link href="/map" className="btn btn-secondary btn-lg">
                            Explorar mapa
                        </Link>
                    </div>
                    <div className={styles.mapPreview}>
                        <div className={styles.mapLines}></div>
                        <div className={styles.mapDot}></div>
                        <div className={styles.mapDot}></div>
                        <div className={styles.mapDot}></div>
                        <span>Área em disputa</span>
                    </div>
                </div>
            </section>

            <section className={styles.cta}>
                <div className={styles.ctaCard}>
                    <h2>Pronto para mover a cidade?</h2>
                    <p>
                        Comece agora e transforme suas corridas em conquistas de
                        verdade.
                    </p>
                    <Link href="/register" className="btn btn-primary btn-lg">
                        Criar conta
                    </Link>
                </div>
            </section>
        </main>
    )
}

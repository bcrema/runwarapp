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
                    <span className={styles.kicker}>Temporada ativa em Curitiba</span>
                    <h1 className={styles.title}>
                        <span className={styles.titleAccent}>Liga</span>Run
                    </h1>
                    <p className={styles.tagline}>
                        Transforme cada corrida em território
                    </p>
                    <p className={styles.description}>
                        LigaRun é um jogo de estratégia em tempo real que usa suas rotas para
                        conquistar o mapa. Corra, ataque e defenda áreas com sua bandeira,
                        ganhe ações diárias e suba no ranking da cidade.
                    </p>

                    <ul className={styles.heroHighlights}>
                        <li><span>📍</span> Mapa vivo em áreas com disputas locais.</li>
                        <li><span>🤝</span> Jogue solo ou com sua assessoria.</li>
                        <li><span>🏆</span> Temporadas curtas e rankings semanais.</li>
                    </ul>

                    <div className={styles.cta}>
                        <Link href="/register" className="btn btn-primary btn-lg">
                            Começar Agora
                        </Link>
                        <Link href="/login" className="btn btn-secondary btn-lg">
                            Entrar
                        </Link>
                        <Link href="/map" className="btn btn-secondary btn-lg">
                            Ver Mapa
                        </Link>
                    </div>

                    <p className={styles.heroMeta}>
                        Sem sensores extras. Só correr, registrar e disputar.
                    </p>
                </div>
            </section>

            <section className={styles.story}>
                <div className={styles.storyGrid}>
                    <div>
                        <h2 className={styles.sectionTitle}>O produto em uma frase</h2>
                        <p className={styles.storyText}>
                            LigaRun transforma a sua rotina de treino em uma guerra territorial.
                            Cada loop vira ações para conquistar áreas, defender sua área e
                            avançar junto da sua bandeira.
                        </p>
                        <p className={styles.storyText}>
                            O resultado é um jogo social, estratégico e viciante que incentiva
                            consistência e cria rivalidades saudáveis entre bairros e equipes.
                        </p>
                    </div>
                    <div className={styles.storyCards}>
                        <div className={`card ${styles.storyCard}`}>
                            <h3>Corridas com propósito</h3>
                            <p>Treine mais porque cada quilômetro muda o mapa.</p>
                        </div>
                        <div className={`card ${styles.storyCard}`}>
                            <h3>Disputa em tempo real</h3>
                            <p>Atacou? Seu rival vê. Defendeu? O escudo sobe na hora.</p>
                        </div>
                        <div className={`card ${styles.storyCard}`}>
                            <h3>Comunidade em campo</h3>
                            <p>Assessorias, academias e grupos com poder de dominar regiões.</p>
                        </div>
                    </div>
                </div>
            </section>

            {/* Features Section */}
            <section className={styles.features}>
                <h2 className={styles.sectionTitle}>Como Funciona</h2>

                <div className={styles.featureGrid}>
                    <div className={`card ${styles.featureCard}`}>
                        <div className={styles.featureIcon}>🏃</div>
                        <h3>Complete Loops</h3>
                        <p>
                            Faça circuitos com pelo menos 1.2km para ganhar ações
                            territoriais. Mais corrida = mais controle no mapa.
                        </p>
                    </div>

                    <div className={`card ${styles.featureCard}`}>
                        <div className={styles.featureIcon}>🗺️</div>
                        <h3>Conquiste Tiles</h3>
                        <p>
                            O mapa é dividido em áreas de ~250m. Corra dentro de uma área
                            para conquistá-la ou atacar territórios rivais.
                        </p>
                    </div>

                    <div className={`card ${styles.featureCard}`}>
                        <div className={styles.featureIcon}>🛡️</div>
                        <h3>Defenda Território</h3>
                        <p>
                            Suas áreas têm um escudo que diminui com ataques. Corra para
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

            <section className={styles.loop}>
                <h2 className={styles.sectionTitle}>O Loop do Jogo</h2>
                <div className={styles.loopGrid}>
                    <div className={styles.loopStep}>
                        <span className={styles.loopNumber}>01</span>
                        <h3>Planeje sua rota</h3>
                        <p>Veja o mapa e escolha onde atacar ou defender.</p>
                    </div>
                    <div className={styles.loopStep}>
                        <span className={styles.loopNumber}>02</span>
                        <h3>Corra e registre</h3>
                        <p>Complete o loop e ganhe ações diárias.</p>
                    </div>
                    <div className={styles.loopStep}>
                        <span className={styles.loopNumber}>03</span>
                        <h3>Conquiste áreas</h3>
                        <p>Capture áreas neutras ou reduza o escudo rival.</p>
                    </div>
                    <div className={styles.loopStep}>
                        <span className={styles.loopNumber}>04</span>
                        <h3>Suba no ranking</h3>
                        <p>Some pontos para você e para sua bandeira.</p>
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

            <section className={styles.community}>
                <div className={styles.communityGrid}>
                    <div className={styles.communityCopy}>
                        <h2 className={styles.sectionTitle}>Bandeiras que movem cidades</h2>
                        <p className={styles.storyText}>
                            Crie a sua bandeira, convide amigos e conquiste regiões inteiras.
                            Quanto mais organizada a sua equipe, mais estratégico fica o mapa.
                        </p>
                        <div className={styles.communityStats}>
                            <div>
                                <span className={styles.communityValue}>+40</span>
                                <span className={styles.communityLabel}>Grupos ativos</span>
                            </div>
                            <div>
                                <span className={styles.communityValue}>3</span>
                                <span className={styles.communityLabel}>Ações diárias</span>
                            </div>
                            <div>
                                <span className={styles.communityValue}>6</span>
                                <span className={styles.communityLabel}>Semanas por temporada</span>
                            </div>
                        </div>
                    </div>
                    <div className={styles.communityCard}>
                        <h3>Convide sua assessoria</h3>
                        <p>
                            Monte um esquadrão, distribua as rotas e proteja os pontos-chave.
                            Estratégia coletiva vira território garantido.
                        </p>
                        <div className={styles.communityBadges}>
                            <span className="badge badge-conquest">Conquista</span>
                            <span className="badge badge-defense">Defesa</span>
                            <span className="badge badge-attack">Ataque</span>
                        </div>
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
                        <p>Sua área → <strong>+20 de escudo</strong></p>
                    </div>

                    <div className={styles.ruleCard}>
                        <span className="badge badge-dispute">Disputa</span>
                        <p>Escudo abaixo de <strong>70</strong> = Em disputa!</p>
                    </div>
                </div>
            </section>

            <section className={styles.ctaPanel}>
                <div className={styles.ctaCard}>
                    <h2>Comece a conquistar hoje</h2>
                    <p>
                        Entre para o LigaRun, conecte sua corrida ao mapa e lidere sua bandeira
                        na próxima temporada.
                    </p>
                    <div className={styles.cta}>
                        <Link href="/register" className="btn btn-primary btn-lg">
                            Criar Conta
                        </Link>
                        <Link href="/login" className="btn btn-secondary btn-lg">
                            Já tenho conta
                        </Link>
                    </div>
                </div>
            </section>

            {/* Footer */}
            <footer className={styles.footer}>
                <p>LigaRun © 2026 - Conquiste seu território</p>
            </footer>
        </main>
    )
}

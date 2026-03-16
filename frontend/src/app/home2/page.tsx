'use client'

import Link from 'next/link'
import styles from './page.module.css'

const focusAreas = [
    {
        title: 'Painel do corredor',
        description:
            'Distancia, consistencia, ritmo e impacto territorial ficam organizados numa visao pronta para decisao.',
    },
    {
        title: 'Painel da bandeira',
        description:
            'Veja membros ativos, presenca da equipe e oportunidades de crescimento por categoria e regiao.',
    },
    {
        title: 'Painel de aquisicao',
        description:
            'Atraia novos corredores, groups e assessorias com um produto mais claro, social e orientado a performance.',
    },
]

const audiences = [
    {
        kicker: 'Para corredores',
        title: 'Entenda o seu momento sem abrir varias telas.',
        description:
            'A web vira um cockpit: historico recente, tendencia semanal, bandeira atual e proximos movimentos.',
        metrics: ['Consistencia semanal', 'Ritmo medio', 'Ultimas sessoes'],
    },
    {
        kicker: 'Para grupos',
        title: 'Mostre presenca e mantenha a crew engajada.',
        description:
            'As bandeiras deixam de ser apenas um nome. Elas passam a ter narrativa, ranking, membros e crescimento visivel.',
        metrics: ['Radar competitivo', 'Times em destaque', 'Distribuicao por categoria'],
    },
    {
        kicker: 'Para assessorias',
        title: 'Transforme alunos em comunidade acionavel.',
        description:
            'A assessoria consegue apresentar performance coletiva, presenca territorial e valor de marca em uma camada unica.',
        metrics: ['Leads de comunidade', 'Narrativa de marca', 'Escala de membros'],
    },
]

const productSteps = [
    'Sincronize os treinos no app e acompanhe tudo no painel web.',
    'Leia o momento do corredor, da bandeira e do mapa com blocos analiticos.',
    'Use o radar para atrair novos membros, crews e assessorias para a plataforma.',
]

export default function Home2() {
    return (
        <main className={styles.main}>
            <section className={styles.hero}>
                <div className={styles.heroBackdrop}></div>
                <div className={styles.topBar}>
                    <Link href="/" className={styles.logo}>
                        <span>Liga</span>Run
                    </Link>
                    <div className={styles.topActions}>
                        <Link href="/login" className="btn btn-secondary btn-sm">
                            Entrar
                        </Link>
                        <Link href="/register" className="btn btn-primary btn-sm">
                            Criar conta
                        </Link>
                    </div>
                </div>

                <div className={styles.heroGrid}>
                    <div className={styles.heroCopy}>
                        <span className="section-kicker">Runner Control Center</span>
                        <h1>
                            A interface web agora trabalha para o corredor e
                            para a bandeira.
                        </h1>
                        <p className={styles.heroText}>
                            LigaRun passa a ser um painel de leitura,
                            consistencia e crescimento. O app captura a corrida.
                            A web organiza performance, comunidade e expansao.
                        </p>

                        <div className={styles.heroActions}>
                            <Link href="/register" className="btn btn-primary btn-lg">
                                Abrir painel
                            </Link>
                            <Link href="/map" className="btn btn-secondary btn-lg">
                                Ver produto logado
                            </Link>
                        </div>

                        <div className={styles.heroMetrics}>
                            <div className="panel metric-card">
                                <span className="metric-label">Visao do corredor</span>
                                <strong className="metric-value">360</strong>
                                <span className="metric-detail">Historico, ritmo e consistencia em uma leitura unica.</span>
                            </div>
                            <div className="panel metric-card">
                                <span className="metric-label">Visao da bandeira</span>
                                <strong className="metric-value">1 painel</strong>
                                <span className="metric-detail">Membros, ranking, tiles e categorias lado a lado.</span>
                            </div>
                        </div>
                    </div>

                    <div className={styles.heroPreview}>
                        <div className={`${styles.previewShell} panel panel-strong`}>
                            <div className={styles.previewHeader}>
                                <div>
                                    <span className={styles.previewKicker}>Painel Central</span>
                                    <h2>Corredor + bandeira + crescimento</h2>
                                </div>
                                <span className="tag tag-accent">Analitico</span>
                            </div>

                            <div className={styles.previewGrid}>
                                <div className={styles.previewCard}>
                                    <span className="metric-label">Semana</span>
                                    <strong className="metric-value">28,4 km</strong>
                                    <span className="metric-detail">4 dias ativos e ritmo estavel.</span>
                                </div>
                                <div className={styles.previewCard}>
                                    <span className="metric-label">Bandeira</span>
                                    <strong className="metric-value">#2 no radar</strong>
                                    <span className="metric-detail">42 membros, 118 tiles e alta recorrencia.</span>
                                </div>
                                <div className={styles.previewCardWide}>
                                    <span className="metric-label">Oportunidade</span>
                                    <strong className={styles.previewOpportunity}>
                                        Assessoria com boa escala, mas pouca presenca territorial.
                                    </strong>
                                    <span className="metric-detail">
                                        O web passa a gerar argumento para novas parcerias e novos usuarios.
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section className={styles.focusSection}>
                <div className="page-shell">
                    <div className={`${styles.focusIntro} section-header`}>
                        <span className="section-kicker">Reposicionamento</span>
                        <h2 className="section-title">
                            O produto deixa de pedir corrida no navegador e
                            passa a entregar leitura de negocio e performance.
                        </h2>
                        <p className="section-copy">
                            O ganho aqui nao e so visual. E de clareza de uso:
                            corredor entende sua evolucao, bandeira entende sua
                            operacao, e a plataforma comunica melhor valor para
                            grupos e assessorias.
                        </p>
                    </div>

                    <div className={styles.focusGrid}>
                        {focusAreas.map((area) => (
                            <article key={area.title} className="panel">
                                <h3>{area.title}</h3>
                                <p>{area.description}</p>
                            </article>
                        ))}
                    </div>
                </div>
            </section>

            <section className={styles.audienceSection}>
                <div className="page-shell">
                    <div className={`${styles.audienceIntro} section-header`}>
                        <span className="section-kicker">Publicos</span>
                        <h2 className="section-title">Uma home que conversa com quem decide e com quem corre.</h2>
                    </div>

                    <div className={styles.audienceGrid}>
                        {audiences.map((audience) => (
                            <article key={audience.title} className="panel">
                                <span className={styles.audienceKicker}>{audience.kicker}</span>
                                <h3>{audience.title}</h3>
                                <p>{audience.description}</p>
                                <ul className={styles.metricList}>
                                    {audience.metrics.map((metric) => (
                                        <li key={metric}>{metric}</li>
                                    ))}
                                </ul>
                            </article>
                        ))}
                    </div>
                </div>
            </section>

            <section className={styles.workflowSection}>
                <div className="page-shell">
                    <div className={styles.workflowCard}>
                        <div className="section-header">
                            <span className="section-kicker">Fluxo recomendado</span>
                            <h2 className="section-title">App para capturar. Web para decidir.</h2>
                        </div>

                        <div className={styles.workflowSteps}>
                            {productSteps.map((step, index) => (
                                <div key={step} className={styles.workflowStep}>
                                    <span>{String(index + 1).padStart(2, '0')}</span>
                                    <p>{step}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </section>

            <section className={styles.finalSection}>
                <div className="page-shell">
                    <div className={`${styles.finalCard} panel panel-dark`}>
                        <div className="section-header">
                            <span className="section-kicker">Proxima versao da marca</span>
                            <h2 className="section-title">
                                Mais util para o corredor. Mais atraente para crews e assessorias.
                            </h2>
                            <p className="section-copy">
                                Essa refatoracao web posiciona a plataforma como
                                um centro de controle e relacionamento. E isso
                                aumenta recorrencia, clareza e potencial de
                                captacao.
                            </p>
                        </div>

                        <div className={styles.finalActions}>
                            <Link href="/register" className="btn btn-primary btn-lg">
                                Criar acesso
                            </Link>
                            <Link href="/login" className="btn btn-secondary btn-lg">
                                Entrar no painel
                            </Link>
                        </div>
                    </div>
                </div>
            </section>
        </main>
    )
}

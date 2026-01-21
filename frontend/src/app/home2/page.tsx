'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import styles from './page.module.css'

type Slide = {
    kicker: string
    title: string
    description: string
    stat: string
    statLabel: string
}

const slides: Slide[] = [
    {
        kicker: 'Conquista em tempo real',
        title: 'Corra e capture areas',
        description:
            'Suas rotas viram influencia no mapa. Cada loop aumenta o controle da sua bandeira.',
        stat: '250m',
        statLabel: 'Raio medio de cada area'
    },
    {
        kicker: 'Defesa inteligente',
        title: 'Proteja sua zona',
        description:
            'Areas conquistadas ganham escudo. Defenda com corridas rapidas para nao perder terreno.',
        stat: '+20',
        statLabel: 'Escudo em cada defesa'
    },
    {
        kicker: 'Comunidade em movimento',
        title: 'Equipe domina regioes',
        description:
            'Junte sua assessoria ou grupo. A estrategia coletiva muda o ranking semanal.',
        stat: '6',
        statLabel: 'Semanas por temporada'
    }
]

export default function Home2() {
    const [activeIndex, setActiveIndex] = useState(0)

    const maxIndex = slides.length - 1

    useEffect(() => {
        if (typeof window === 'undefined') return
        if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
        const interval = window.setInterval(() => {
            setActiveIndex((prev) => (prev >= maxIndex ? 0 : prev + 1))
        }, 6000)
        return () => window.clearInterval(interval)
    }, [maxIndex])

    const goPrev = () => {
        setActiveIndex((prev) => (prev <= 0 ? maxIndex : prev - 1))
    }

    const goNext = () => {
        setActiveIndex((prev) => (prev >= maxIndex ? 0 : prev + 1))
    }

    return (
        <main className={styles.main}>
            <section className={styles.hero}>
                <div className={styles.heroGlow}></div>
                <div className={styles.heroGrid}>
                    <div className={styles.heroCopy}>
                        <span className={styles.kicker}>LigaRun Home 2</span>
                        <h1>
                            O mapa da cidade virou o seu campo de treino.
                        </h1>
                        <p>
                            Em LigaRun, cada corrida conquista areas, fortalece
                            sua bandeira e movimenta o ranking local em tempo
                            real. Tudo em um loop simples: planeje, corra,
                            capture e defenda.
                        </p>
                        <div className={styles.heroCta}>
                            <Link
                                href="/register"
                                className="btn btn-primary btn-lg"
                            >
                                Criar Conta
                            </Link>
                            <Link
                                href="/login"
                                className="btn btn-secondary btn-lg"
                            >
                                Entrar
                            </Link>
                            <Link
                                href="/map"
                                className="btn btn-secondary btn-lg"
                            >
                                Ver Mapa
                            </Link>
                        </div>
                    </div>

                    <div className={styles.carousel}>
                        <div className={styles.carouselViewport}>
                            <div
                                className={styles.carouselTrack}
                                style={{
                                    transform: `translateX(-${
                                        activeIndex * 100
                                    }%)`
                                }}
                            >
                                {slides.map((slide, index) => (
                                    <div
                                        className={styles.carouselSlide}
                                        key={slide.title}
                                        aria-hidden={activeIndex !== index}
                                    >
                                        <span className={styles.slideKicker}>
                                            {slide.kicker}
                                        </span>
                                        <h2>{slide.title}</h2>
                                        <p>{slide.description}</p>
                                        <div className={styles.slideStat}>
                                            <span>{slide.stat}</span>
                                            <small>{slide.statLabel}</small>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>

                        <div className={styles.carouselControls}>
                            <button
                                type="button"
                                onClick={goPrev}
                                aria-label="Slide anterior"
                            >
                                ←
                            </button>
                            <button
                                type="button"
                                onClick={goNext}
                                aria-label="Proximo slide"
                            >
                                →
                            </button>
                        </div>

                        <div className={styles.carouselDots}>
                            {slides.map((slide, index) => (
                                <button
                                    key={slide.title}
                                    type="button"
                                    onClick={() => setActiveIndex(index)}
                                    className={
                                        index === activeIndex
                                            ? styles.dotActive
                                            : undefined
                                    }
                                    aria-label={`Ir para slide ${index + 1}`}
                                />
                            ))}
                        </div>
                    </div>
                </div>
            </section>

            <section className={styles.benefits}>
                <div className={styles.benefitGrid}>
                    <div className={styles.benefitCard}>
                        <h3>Acoes diarias</h3>
                        <p>
                            Ganhe novas acoes a cada dia e mantenha a disputa
                            viva mesmo com treinos curtos.
                        </p>
                    </div>
                    <div className={styles.benefitCard}>
                        <h3>Bandeiras ativas</h3>
                        <p>
                            Crie uma bandeira para sua assessoria e domine os
                            tiles mais estrategicos.
                        </p>
                    </div>
                    <div className={styles.benefitCard}>
                        <h3>Ranking dinamico</h3>
                        <p>
                            Acompanhe a evolucao do seu desempenho por
                            temporada e mostre consistencia.
                        </p>
                    </div>
                </div>
            </section>

            <section className={styles.finalCta}>
                <div className={styles.finalCard}>
                    <h2>Pronto para correr com proposito?</h2>
                    <p>
                        Entre no LigaRun e transforme suas rotas em territorio
                        conquistado.
                    </p>
                    <Link href="/register" className="btn btn-primary btn-lg">
                        Comecar agora
                    </Link>
                </div>
            </section>
        </main>
    )
}

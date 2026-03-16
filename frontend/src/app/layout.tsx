import '@/styles/globals.css'
import type { Metadata } from 'next'
import { Fraunces, IBM_Plex_Mono, Space_Grotesk } from 'next/font/google'

const fraunces = Fraunces({
    subsets: ['latin'],
    weight: ['600', '700'],
    variable: '--font-display-ui',
})

const ibmPlexMono = IBM_Plex_Mono({
    subsets: ['latin'],
    weight: ['400', '500'],
    variable: '--font-mono-ui',
})

const spaceGrotesk = Space_Grotesk({
    subsets: ['latin'],
    weight: ['400', '500', '700'],
    variable: '--font-sans-ui',
})

const metadataBase =
    process.env.NEXT_PUBLIC_SITE_URL != null &&
    process.env.NEXT_PUBLIC_SITE_URL.trim().length > 0
        ? new URL(process.env.NEXT_PUBLIC_SITE_URL)
        : new URL('http://localhost:3000')

export const metadata: Metadata = {
    metadataBase,
    title: 'LigaRun | Painel do Corredor e da Bandeira',
    description:
        'Painel analitico para corredores, grupos e assessorias acompanharem performance, territorio e crescimento da comunidade.',
    keywords: [
        'corrida',
        'painel do corredor',
        'bandeira',
        'assessoria esportiva',
        'grupo de corrida',
        'analytics running',
    ],
    authors: [{ name: 'LigaRun' }],
    openGraph: {
        title: 'LigaRun | Painel do Corredor e da Bandeira',
        description:
            'Controle corridas, territorio, consistencia e crescimento da sua bandeira em um painel unico.',
        type: 'website',
    },
}

export default function RootLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return (
        <html lang="pt-BR">
            <head>
                <link
                    href="https://api.mapbox.com/mapbox-gl-js/v3.0.1/mapbox-gl.css"
                    rel="stylesheet"
                />
            </head>
            <body
                className={`${fraunces.variable} ${ibmPlexMono.variable} ${spaceGrotesk.variable}`}
            >
                {children}
            </body>
        </html>
    )
}

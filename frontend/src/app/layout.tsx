import '@/styles/globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
    title: 'LigaRun - Conquiste Territórios Correndo',
    description: 'Um jogo de conquista territorial no mundo real para corredores. Conquiste, ataque e defenda tiles hexagonais com suas corridas.',
    keywords: ['corrida', 'GPS', 'território', 'jogo', 'running', 'fitness'],
    authors: [{ name: 'LigaRun' }],
    openGraph: {
        title: 'LigaRun - Conquiste Territórios Correndo',
        description: 'Um jogo de conquista territorial no mundo real para corredores.',
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
                <link rel="preconnect" href="https://fonts.googleapis.com" />
                <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
                <link
                    href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
                    rel="stylesheet"
                />
                <link
                    href="https://api.mapbox.com/mapbox-gl-js/v3.0.1/mapbox-gl.css"
                    rel="stylesheet"
                />
            </head>
            <body>{children}</body>
        </html>
    )
}

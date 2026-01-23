/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: true,
    output: 'standalone',

    // Environment variables exposed to the browser
    env: {
        NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL ?? '',
        NEXT_PUBLIC_MAPBOX_TOKEN: process.env.NEXT_PUBLIC_MAPBOX_TOKEN || '',
    },

    // Transpile mapbox-gl for server-side rendering
    transpilePackages: ['mapbox-gl'],

    // Image optimization domains
    images: {
        domains: ['localhost'],
    },
}

module.exports = nextConfig

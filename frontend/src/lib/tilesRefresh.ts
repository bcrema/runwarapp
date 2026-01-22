export const TILES_REFRESH_EVENT = 'runwar:tiles:refresh'

export function requestTilesRefresh() {
    if (typeof window === 'undefined') return
    window.dispatchEvent(new Event(TILES_REFRESH_EVENT))
}

export function onTilesRefresh(handler: () => void) {
    if (typeof window === 'undefined') return () => {}
    window.addEventListener(TILES_REFRESH_EVENT, handler)
    return () => window.removeEventListener(TILES_REFRESH_EVENT, handler)
}

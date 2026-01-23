import { onTilesRefresh, requestTilesRefresh, TILES_REFRESH_EVENT } from './tilesRefresh'

describe('tilesRefresh', () => {
    test('requestTilesRefresh dispatches the event', () => {
        const handler = jest.fn()
        window.addEventListener(TILES_REFRESH_EVENT, handler)

        requestTilesRefresh()

        expect(handler).toHaveBeenCalledTimes(1)
        window.removeEventListener(TILES_REFRESH_EVENT, handler)
    })

    test('onTilesRefresh subscribes and unsubscribes', () => {
        const handler = jest.fn()
        const off = onTilesRefresh(handler)

        requestTilesRefresh()
        expect(handler).toHaveBeenCalledTimes(1)

        off()
        requestTilesRefresh()
        expect(handler).toHaveBeenCalledTimes(1)
    })
})


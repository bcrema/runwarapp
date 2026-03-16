import React from 'react'
import { render, screen } from '@testing-library/react'

jest.mock('next/link', () => ({
    __esModule: true,
    default: ({ href, children, ...props }: any) => (
        <a href={href} {...props}>
            {children}
        </a>
    ),
}))

import Home2 from './page'

describe('Home2', () => {
    test('renders the new analytics-focused positioning', () => {
        render(<Home2 />)

        expect(
            screen.getByRole('heading', {
                name: /A interface web agora trabalha para o corredor e para a bandeira/i,
            })
        ).toBeInTheDocument()
        expect(
            screen.getByRole('link', { name: 'Abrir painel' })
        ).toHaveAttribute('href', '/register')
        expect(
            screen.getByText(/App para capturar\. Web para decidir\./i)
        ).toBeInTheDocument()
    })
})

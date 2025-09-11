import { render, screen } from '@testing-library/react'
import { Card, CardHeader, CardContent, CardFooter } from '../ui/Card'

describe('Card Components', () => {
  it('renders Card with children', () => {
    render(
      <Card>
        <div>Card content</div>
      </Card>
    )
    expect(screen.getByText('Card content')).toBeInTheDocument()
  })

  it('renders Card with custom className', () => {
    const { container } = render(
      <Card className="custom-card">
        <div>Custom card</div>
      </Card>
    )
    const outer = container.firstElementChild as HTMLElement | null
    expect(outer).not.toBeNull()
    expect(outer).toHaveClass('custom-card')
  })

  it('renders CardHeader with title and description', () => {
    render(
      <Card>
        <CardHeader>
          <div>Header content</div>
        </CardHeader>
      </Card>
    )
    expect(screen.getByText('Header content')).toBeInTheDocument()
  })

  it('renders CardContent', () => {
    render(
      <Card>
        <CardContent>
          <div>Content</div>
        </CardContent>
      </Card>
    )
    expect(screen.getByText('Content')).toBeInTheDocument()
  })

  it('renders CardFooter', () => {
    render(
      <Card>
        <CardFooter>
          <div>Footer</div>
        </CardFooter>
      </Card>
    )
    expect(screen.getByText('Footer')).toBeInTheDocument()
  })

  it('renders complete card structure', () => {
    render(
      <Card>
        <CardHeader>
          <div>Header</div>
        </CardHeader>
        <CardContent>
          <div>Body</div>
        </CardContent>
        <CardFooter>
          <div>Footer</div>
        </CardFooter>
      </Card>
    )
    expect(screen.getByText('Header')).toBeInTheDocument()
    expect(screen.getByText('Body')).toBeInTheDocument()
    expect(screen.getByText('Footer')).toBeInTheDocument()
  })
})

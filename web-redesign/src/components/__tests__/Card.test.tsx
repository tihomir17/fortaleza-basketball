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
    render(
      <Card className="custom-card">
        <div>Custom card</div>
      </Card>
    )
    const card = screen.getByText('Custom card').closest('div')
    expect(card).toHaveClass('custom-card')
  })

  it('renders CardHeader with title and description', () => {
    render(
      <Card>
        <CardHeader>
          <h3>Card Title</h3>
          <p>Card description</p>
        </CardHeader>
      </Card>
    )
    expect(screen.getByText('Card Title')).toBeInTheDocument()
    expect(screen.getByText('Card description')).toBeInTheDocument()
  })

  it('renders CardContent', () => {
    render(
      <Card>
        <CardContent>
          <p>Card body content</p>
        </CardContent>
      </Card>
    )
    expect(screen.getByText('Card body content')).toBeInTheDocument()
  })

  it('renders CardFooter', () => {
    render(
      <Card>
        <CardFooter>
          <button>Action</button>
        </CardFooter>
      </Card>
    )
    expect(screen.getByRole('button', { name: /action/i })).toBeInTheDocument()
  })

  it('renders complete card structure', () => {
    render(
      <Card>
        <CardHeader>
          <h3>Complete Card</h3>
          <p>This is a complete card</p>
        </CardHeader>
        <CardContent>
          <p>Main content goes here</p>
        </CardContent>
        <CardFooter>
          <button>Save</button>
          <button>Cancel</button>
        </CardFooter>
      </Card>
    )
    
    expect(screen.getByText('Complete Card')).toBeInTheDocument()
    expect(screen.getByText('This is a complete card')).toBeInTheDocument()
    expect(screen.getByText('Main content goes here')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /save/i })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /cancel/i })).toBeInTheDocument()
  })
})

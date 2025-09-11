import { render } from '@testing-library/react'
import '@testing-library/jest-dom'
import { Playbook } from '../Playbook'

jest.mock('../../services/apiWithFallback', () => ({
  __esModule: true,
  default: {
    getPlays: jest.fn().mockResolvedValue({ results: [] }),
  },
}))

jest.mock('../../services/api', () => ({
  __esModule: true,
  adminApi: {
    get: jest.fn().mockResolvedValue({ results: [] })
  }
}))

jest.mock('../../utils/testApi', () => ({
  __esModule: true,
  default: jest.fn(),
}))

describe('Playbook Page', () => {
  it('renders without crashing', () => {
    render(<Playbook />)
  })
})

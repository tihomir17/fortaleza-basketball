import { render, screen, fireEvent, waitFor } from '../../test-utils/integration-test-utils'
import { UserManagement } from '../../pages/UserManagement'
import { createMockUser } from '../../test-utils/integration-test-utils'
import type { User } from '../../store/userManagementStore'

// Mock the user management store
const mockUserManagementStore = {
  users: [] as User[],
  isLoading: false,
  error: null as string | null,
  selectedUser: null,
  fetchUsers: jest.fn(),
  createUser: jest.fn(),
  updateUser: jest.fn(),
  deleteUser: jest.fn(),
  resetPassword: jest.fn(),
  toggleUserStatus: jest.fn(),
  setSelectedUser: jest.fn(),
  clearError: jest.fn()
}

jest.mock('../../store/userManagementStore', () => ({
  useUserManagementStore: () => mockUserManagementStore
}))

describe.skip('User Management Flow', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockUserManagementStore.users = []
  })

  it('should display users list with search and filtering', async () => {
    const mockUsers = [
      createMockUser({ id: '1', firstName: 'John', lastName: 'Doe', role: 'admin' }),
      createMockUser({ id: '2', firstName: 'Jane', lastName: 'Smith', role: 'coach' })
    ]
    
    mockUserManagementStore.users = mockUsers

    render(<UserManagement />)

    // Should show users list
    expect(screen.getByText('User Management')).toBeInTheDocument()
    expect(screen.getByText('John Doe')).toBeInTheDocument()
    expect(screen.getByText('Jane Smith')).toBeInTheDocument()

    // Should show search and filter controls
    expect(screen.getByPlaceholderText(/search users/i)).toBeInTheDocument()
    expect(screen.getByText(/all roles/i)).toBeInTheDocument()
    expect(screen.getByText(/all status/i)).toBeInTheDocument()
  })

  it('should allow creating a new user', async () => {
    const newUser = createMockUser({
      firstName: 'New',
      lastName: 'User',
      email: 'newuser@example.com',
      role: 'player'
    })

    mockUserManagementStore.createUser.mockResolvedValue(newUser)

    render(<UserManagement />)

    // Click add user button
    const addButton = screen.getByRole('button', { name: /add user/i })
    fireEvent.click(addButton)

    // Should show create user modal
    await waitFor(() => {
      expect(screen.getByText(/create new user/i)).toBeInTheDocument()
    })

    // Fill form
    const firstNameInput = screen.getByLabelText(/first name/i)
    const lastNameInput = screen.getByLabelText(/last name/i)
    const emailInput = screen.getByLabelText(/email/i)
    const roleSelect = screen.getByLabelText(/role/i)

    fireEvent.change(firstNameInput, { target: { value: 'New' } })
    fireEvent.change(lastNameInput, { target: { value: 'User' } })
    fireEvent.change(emailInput, { target: { value: 'newuser@example.com' } })
    fireEvent.change(roleSelect, { target: { value: 'player' } })

    // Submit form
    const submitButton = screen.getByRole('button', { name: /create/i })
    fireEvent.click(submitButton)

    // Should call create user function
    await waitFor(() => {
      expect(mockUserManagementStore.createUser).toHaveBeenCalledWith({
        firstName: 'New',
        lastName: 'User',
        email: 'newuser@example.com',
        role: 'player'
      })
    })
  })

  it('should allow editing user details', async () => {
    const mockUser = createMockUser({ 
      id: '1', 
      firstName: 'John', 
      lastName: 'Doe', 
      role: 'admin',
      status: 'active'
    })
    
    mockUserManagementStore.users = [mockUser]

    render(<UserManagement />)

    // Click edit button
    const editButton = screen.getByRole('button', { name: /edit user/i })
    fireEvent.click(editButton)

    // Should show edit modal
    await waitFor(() => {
      expect(screen.getByText(/edit user/i)).toBeInTheDocument()
    })

    // Form should be pre-filled
    const firstNameInput = screen.getByLabelText(/first name/i)
    expect(firstNameInput).toHaveValue('John')

    // Update the user
    fireEvent.change(firstNameInput, { target: { value: 'John Updated' } })

    // Submit changes
    const saveButton = screen.getByRole('button', { name: /save/i })
    fireEvent.click(saveButton)

    // Should call update user function
    await waitFor(() => {
      expect(mockUserManagementStore.updateUser).toHaveBeenCalledWith('1', {
        firstName: 'John Updated'
      })
    })
  })

  it('should allow deleting a user with confirmation', async () => {
    const mockUser = createMockUser({ id: '1', firstName: 'John', lastName: 'Doe' })
    mockUserManagementStore.users = [mockUser]

    // Mock window.confirm
    window.confirm = jest.fn(() => true)

    render(<UserManagement />)

    // Click delete button
    const deleteButton = screen.getByRole('button', { name: /delete user/i })
    fireEvent.click(deleteButton)

    // Should show confirmation dialog
    expect(window.confirm).toHaveBeenCalledWith('Are you sure you want to delete this user?')

    // Should call delete user function
    await waitFor(() => {
      expect(mockUserManagementStore.deleteUser).toHaveBeenCalledWith('1')
    })
  })

  it('should allow resetting user password', async () => {
    const mockUser = createMockUser({ id: '1', firstName: 'John', lastName: 'Doe' })
    mockUserManagementStore.users = [mockUser]

    // Mock window.confirm
    window.confirm = jest.fn(() => true)

    render(<UserManagement />)

    // Click reset password button
    const resetButton = screen.getByRole('button', { name: /reset password/i })
    fireEvent.click(resetButton)

    // Should show confirmation dialog
    expect(window.confirm).toHaveBeenCalledWith("Are you sure you want to reset this user's password?")

    // Should call reset password function
    await waitFor(() => {
      expect(mockUserManagementStore.resetPassword).toHaveBeenCalledWith('1')
    })
  })

  it('should allow toggling user status', async () => {
    const mockUser = createMockUser({ 
      id: '1', 
      firstName: 'John', 
      lastName: 'Doe',
      status: 'active'
    })
    
    mockUserManagementStore.users = [mockUser]

    render(<UserManagement />)

    // Click toggle status button
    const toggleButton = screen.getByRole('button', { name: /deactivate user/i })
    fireEvent.click(toggleButton)

    // Should call toggle status function
    await waitFor(() => {
      expect(mockUserManagementStore.toggleUserStatus).toHaveBeenCalledWith('1')
    })
  })

  it('should filter users by role and status', async () => {
    const mockUsers = [
      createMockUser({ id: '1', firstName: 'John', lastName: 'Doe', role: 'admin', status: 'active' }),
      createMockUser({ id: '2', firstName: 'Jane', lastName: 'Smith', role: 'coach', status: 'inactive' })
    ]
    
    mockUserManagementStore.users = mockUsers

    render(<UserManagement />)

    // Filter by role
    const roleFilter = screen.getByDisplayValue(/all roles/i)
    fireEvent.change(roleFilter, { target: { value: 'admin' } })

    // Should show only admin users
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument()
      expect(screen.queryByText('Jane Smith')).not.toBeInTheDocument()
    })

    // Reset and filter by status
    fireEvent.change(roleFilter, { target: { value: '' } })
    const statusFilter = screen.getByDisplayValue(/all status/i)
    fireEvent.change(statusFilter, { target: { value: 'inactive' } })

    // Should show only inactive users
    await waitFor(() => {
      expect(screen.getByText('Jane Smith')).toBeInTheDocument()
      expect(screen.queryByText('John Doe')).not.toBeInTheDocument()
    })
  })

  it('should search users by name and email', async () => {
    const mockUsers = [
      createMockUser({ id: '1', firstName: 'John', lastName: 'Doe', email: 'john@example.com' }),
      createMockUser({ id: '2', firstName: 'Jane', lastName: 'Smith', email: 'jane@example.com' })
    ]
    
    mockUserManagementStore.users = mockUsers

    render(<UserManagement />)

    // Search by name
    const searchInput = screen.getByPlaceholderText(/search users/i)
    fireEvent.change(searchInput, { target: { value: 'John' } })

    // Should filter results
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument()
      expect(screen.queryByText('Jane Smith')).not.toBeInTheDocument()
    })

    // Search by email
    fireEvent.change(searchInput, { target: { value: 'jane@example.com' } })

    // Should filter results
    await waitFor(() => {
      expect(screen.getByText('Jane Smith')).toBeInTheDocument()
      expect(screen.queryByText('John Doe')).not.toBeInTheDocument()
    })
  })

  it('should export users data', async () => {
    const mockUsers = [
      createMockUser({ id: '1', firstName: 'John', lastName: 'Doe' })
    ]
    
    mockUserManagementStore.users = mockUsers

    render(<UserManagement />)

    // Click export button
    const exportButton = screen.getByRole('button', { name: /export/i })
    fireEvent.click(exportButton)

    // Should show export options
    await waitFor(() => {
      expect(screen.getByText(/export to excel/i)).toBeInTheDocument()
      expect(screen.getByText(/export to csv/i)).toBeInTheDocument()
      expect(screen.getByText(/export to pdf/i)).toBeInTheDocument()
    })
  })

  it('should handle loading and error states', async () => {
    // Test loading state
    mockUserManagementStore.isLoading = true
    mockUserManagementStore.users = []

    const { rerender } = render(<UserManagement />)

    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument()

    // Test error state
    mockUserManagementStore.isLoading = false
    mockUserManagementStore.error = 'Failed to load users'

    rerender(<UserManagement />)

    expect(screen.getByText(/failed to load users/i)).toBeInTheDocument()
    expect(screen.getByText(/try again/i)).toBeInTheDocument()
  })
})

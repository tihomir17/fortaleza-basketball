import { create } from 'zustand'

export interface Notification {
  id: string
  type: 'success' | 'error' | 'warning' | 'info'
  title: string
  message: string
  timestamp: Date
  read: boolean
  action?: {
    label: string
    onClick: () => void
  }
}

interface NotificationsState {
  notifications: Notification[]
  unreadCount: number

  // Actions
  addNotification: (notification: Omit<Notification, 'id' | 'timestamp' | 'read'>) => void
  markAsRead: (id: string) => void
  markAllAsRead: () => void
  removeNotification: (id: string) => void
  clearAll: () => void
}

export const useNotificationsStore = create<NotificationsState>((set, get) => ({
  notifications: [],
  unreadCount: 0,

  addNotification: (notification) => {
    const newNotification: Notification = {
      ...notification,
      id: Math.random().toString(36).substr(2, 9),
      timestamp: new Date(),
      read: false,
    }

    set((state) => ({
      notifications: [newNotification, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    }))

    // Auto-remove after 5 seconds for success/info notifications
    if (notification.type === 'success' || notification.type === 'info') {
      setTimeout(() => {
        get().removeNotification(newNotification.id)
      }, 5000)
    }
  },

  markAsRead: (id) => {
    set((state) => ({
      notifications: state.notifications.map((notification) =>
        notification.id === id
          ? { ...notification, read: true }
          : notification
      ),
      unreadCount: Math.max(0, state.unreadCount - 1),
    }))
  },

  markAllAsRead: () => {
    set((state) => ({
      notifications: state.notifications.map((notification) => ({
        ...notification,
        read: true,
      })),
      unreadCount: 0,
    }))
  },

  removeNotification: (id) => {
    set((state) => {
      const notification = state.notifications.find((n) => n.id === id)
      return {
        notifications: state.notifications.filter((n) => n.id !== id),
        unreadCount: notification && !notification.read 
          ? Math.max(0, state.unreadCount - 1) 
          : state.unreadCount,
      }
    })
  },

  clearAll: () => {
    set({
      notifications: [],
      unreadCount: 0,
    })
  },
}))

// Notification helper functions
export const notify = {
  success: (title: string, message: string, action?: Notification['action']) => {
    useNotificationsStore.getState().addNotification({
      type: 'success',
      title,
      message,
      action,
    })
  },

  error: (title: string, message: string, action?: Notification['action']) => {
    useNotificationsStore.getState().addNotification({
      type: 'error',
      title,
      message,
      action,
    })
  },

  warning: (title: string, message: string, action?: Notification['action']) => {
    useNotificationsStore.getState().addNotification({
      type: 'warning',
      title,
      message,
      action,
    })
  },

  info: (title: string, message: string, action?: Notification['action']) => {
    useNotificationsStore.getState().addNotification({
      type: 'info',
      title,
      message,
      action,
    })
  },
}

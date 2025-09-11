import { create } from 'zustand'

export interface Notification {
  id: string
  type: 'success' | 'error' | 'warning' | 'info'
  title: string
  message: string
  duration?: number
  timestamp: number
  read: boolean
}

interface NotificationsState {
  notifications: Notification[]
  unreadCount: number
  
  // Actions
  addNotification: (notification: Omit<Notification, 'id' | 'timestamp' | 'read'>) => void
  removeNotification: (id: string) => void
  markAsRead: (id: string) => void
  markAllAsRead: () => void
  clearAll: () => void
}

export const useNotificationsStore = create<NotificationsState>((set, get) => ({
  notifications: [],
  unreadCount: 0,

  addNotification: (notification) => {
    const newNotification: Notification = {
      ...notification,
      id: Date.now().toString(),
      timestamp: Date.now(),
      read: false
    }
    
    set((state) => ({
      notifications: [newNotification, ...state.notifications],
      unreadCount: state.unreadCount + 1
    }))

    // Auto-remove after duration
    if (notification.duration) {
      setTimeout(() => {
        get().removeNotification(newNotification.id)
      }, notification.duration)
    }
  },

  removeNotification: (id) => {
    set((state) => {
      const notification = state.notifications.find(n => n.id === id)
      const wasUnread = notification && !notification.read
      
      return {
        notifications: state.notifications.filter(n => n.id !== id),
        unreadCount: wasUnread ? state.unreadCount - 1 : state.unreadCount
      }
    })
  },

  markAsRead: (id) => {
    set((state) => ({
      notifications: state.notifications.map(n => 
        n.id === id ? { ...n, read: true } : n
      ),
      unreadCount: Math.max(0, state.unreadCount - 1)
    }))
  },

  markAllAsRead: () => {
    set((state) => ({
      notifications: state.notifications.map(n => ({ ...n, read: true })),
      unreadCount: 0
    }))
  },

  clearAll: () => {
    set({
      notifications: [],
      unreadCount: 0
    })
  }
}))

// Export a convenience function for notifications
export const notify = {
  success: (title: string, message: string, duration = 5000) => {
    useNotificationsStore.getState().addNotification({ type: 'success', title, message, duration })
  },
  error: (title: string, message: string, duration = 7000) => {
    useNotificationsStore.getState().addNotification({ type: 'error', title, message, duration })
  },
  warning: (title: string, message: string, duration = 6000) => {
    useNotificationsStore.getState().addNotification({ type: 'warning', title, message, duration })
  },
  info: (title: string, message: string, duration = 5000) => {
    useNotificationsStore.getState().addNotification({ type: 'info', title, message, duration })
  }
}
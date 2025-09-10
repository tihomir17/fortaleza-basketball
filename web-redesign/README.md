# Fortaleza Basketball Analytics - Web Redesign

A modern, responsive web application built with React + TypeScript for basketball analytics and team management.

## 🚀 **Features**

### ✅ **Completed**
- **Responsive Layout**: Works perfectly on mobile, tablet, and desktop
- **Working Mobile Menu**: Smooth slide-out navigation that actually works
- **Authentication System**: Login/logout with JWT tokens
- **Modern UI**: Clean, professional design with Tailwind CSS
- **TypeScript**: Full type safety throughout the application
- **State Management**: Zustand for clean state management

### 🔄 **In Progress**
- Backend API integration
- Real-time data updates
- Advanced analytics

### 📋 **Planned**
- Live game tracking
- Scouting reports
- Team management
- Performance analytics

## 🛠 **Technology Stack**

- **Frontend**: React 18 + TypeScript
- **Styling**: Tailwind CSS + Headless UI
- **State Management**: Zustand
- **Routing**: React Router v6
- **HTTP Client**: Axios
- **Icons**: Heroicons
- **Build Tool**: Vite

## 🚀 **Getting Started**

### Prerequisites
- Node.js 18+ 
- npm or yarn

### Installation

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Start development server**:
   ```bash
   npm run dev
   ```

3. **Open your browser**:
   Navigate to `http://localhost:5173`

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## 📱 **Mobile-First Design**

The application is designed mobile-first with:
- **Touch-optimized** interactions
- **Responsive breakpoints**: Mobile (< 768px), Tablet (768px - 1024px), Desktop (> 1024px)
- **Working mobile menu** with smooth animations
- **Optimized performance** for mobile devices

## 🔐 **Authentication**

The app includes a complete authentication system:
- JWT token-based authentication
- Automatic token refresh
- Protected routes
- User profile management
- Secure logout

## 🎨 **Design System**

### Colors
- **Primary Blue**: `#1e3a8a` (Fortaleza Blue)
- **Accent Gold**: `#f59e0b` (Fortaleza Gold)
- **Gray Scale**: Tailwind's gray palette

### Components
- **Layout**: Responsive grid system
- **Navigation**: Collapsible sidebar with mobile drawer
- **Forms**: Consistent styling with validation
- **Cards**: Clean, shadowed containers

## 🔌 **Backend Integration**

The app is designed to work with your existing Django backend:
- **API Base URL**: Configurable via environment variables
- **Authentication**: JWT token integration
- **Error Handling**: Comprehensive error management
- **Type Safety**: Full TypeScript interfaces

## 📁 **Project Structure**

```
src/
├── components/          # Reusable UI components
│   ├── ui/             # Base UI components
│   ├── forms/          # Form components
│   └── layout/         # Layout components
├── pages/              # Page components
├── hooks/              # Custom React hooks
├── services/           # API services
├── store/              # State management
├── utils/              # Utility functions
└── types/              # TypeScript types
```

## 🚀 **Deployment**

### Development
```bash
npm run dev
```

### Production Build
```bash
npm run build
```

### Docker Deployment
The app can be deployed using Docker with the existing backend infrastructure.

## 🎯 **Key Improvements Over Flutter Web**

1. **Perfect Mobile Menu**: Actually works on all devices
2. **Native Performance**: No Flutter web overhead
3. **Better Responsive Design**: True CSS responsive design
4. **Easier Maintenance**: Standard web technologies
5. **Better SEO**: Server-side rendering capability
6. **Touch Optimization**: Designed for mobile-first

## 📞 **Support**

For questions or issues, please refer to the main project documentation or contact the development team.

---

**Status**: ✅ **Ready for Development** - Core infrastructure complete, ready for feature implementation.
import { Sidebar } from './Sidebar'
import { Header } from './Header'

interface LayoutProps {
  children: React.ReactNode
}

export function Layout({ children }: LayoutProps) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900">
      {/* Background Pattern */}
      <div className="fixed inset-0 opacity-40" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%239C92AC' fill-opacity='0.03'%3E%3Ccircle cx='30' cy='30' r='2'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`
      }}></div>
      
      <Header onMenuClick={() => {}} />
      <div className="pt-16 relative z-10 min-h-screen">
        <main className="pb-16">
          <div className="p-4 sm:p-6 lg:p-8 xl:p-10">
            <div className="max-w-none">
              {children}
            </div>
          </div>
        </main>
      </div>
      <Sidebar isOpen={true} onClose={() => {}} />
    </div>
  )
}

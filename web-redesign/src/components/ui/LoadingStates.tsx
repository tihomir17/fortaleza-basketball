import { Skeleton, SkeletonCard, SkeletonTable, SkeletonList } from './Skeleton'

export function DashboardLoading() {
  return (
    <div className="max-w-7xl mx-auto">
      {/* Page Header Skeleton */}
      <div className="mb-8">
        <Skeleton className="h-8 w-48 mb-2" />
        <Skeleton className="h-4 w-96 mb-2" />
        <Skeleton className="h-3 w-40" />
      </div>

      {/* Stats Cards Skeleton */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {Array.from({ length: 4 }).map((_, i) => (
          <SkeletonCard key={i} />
        ))}
      </div>

      {/* Recent Games Skeleton */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 mb-8">
        <div className="px-6 py-5 border-b border-gray-100">
          <Skeleton className="h-6 w-32" />
        </div>
        <div className="p-6">
          <SkeletonList />
        </div>
      </div>

      {/* Recent Activity Skeleton */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100">
        <div className="px-6 py-5 border-b border-gray-100">
          <Skeleton className="h-6 w-32" />
        </div>
        <div className="p-6">
          <SkeletonList />
        </div>
      </div>
    </div>
  )
}

export function GamesLoading() {
  return (
    <div className="max-w-7xl mx-auto">
      {/* Page Header Skeleton */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <Skeleton className="h-8 w-32 mb-2" />
            <Skeleton className="h-4 w-64" />
          </div>
          <Skeleton className="h-10 w-32 rounded-lg" />
        </div>
      </div>

      {/* Tabs Skeleton */}
      <div className="mb-6">
        <div className="flex space-x-8">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-8 w-24" />
          ))}
        </div>
      </div>

      {/* Games Table Skeleton */}
      <SkeletonTable />
    </div>
  )
}

export function TeamsLoading() {
  return (
    <div className="max-w-7xl mx-auto">
      {/* Page Header Skeleton */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <Skeleton className="h-8 w-32 mb-2" />
            <Skeleton className="h-4 w-64" />
          </div>
          <Skeleton className="h-10 w-32 rounded-lg" />
        </div>
      </div>

      {/* Teams Grid Skeleton */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <div className="flex items-center mb-4">
              <Skeleton className="w-12 h-12 rounded-full" />
              <div className="ml-4 flex-1">
                <Skeleton className="h-5 w-32 mb-2" />
                <Skeleton className="h-4 w-24" />
              </div>
            </div>
            <div className="space-y-2">
              <Skeleton className="h-4 w-full" />
              <Skeleton className="h-4 w-3/4" />
              <Skeleton className="h-4 w-1/2" />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

export function GameTrackingLoading() {
  return (
    <div className="max-w-7xl mx-auto">
      {/* Page Header Skeleton */}
      <div className="mb-8">
        <Skeleton className="h-8 w-48 mb-2" />
        <Skeleton className="h-4 w-96" />
      </div>

      {/* Game Controls Skeleton */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 mb-8">
        <div className="flex items-center justify-between mb-6">
          <Skeleton className="h-6 w-32" />
          <div className="flex space-x-4">
            {Array.from({ length: 3 }).map((_, i) => (
              <Skeleton key={i} className="h-10 w-20 rounded-lg" />
            ))}
          </div>
        </div>
        
        {/* Score Display Skeleton */}
        <div className="text-center mb-6">
          <Skeleton className="h-12 w-48 mx-auto mb-2" />
          <Skeleton className="h-6 w-32 mx-auto" />
        </div>
      </div>

      {/* Game Log Skeleton */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100">
        <div className="px-6 py-5 border-b border-gray-100">
          <Skeleton className="h-6 w-32" />
        </div>
        <div className="p-6">
          <SkeletonList />
        </div>
      </div>
    </div>
  )
}

export function AnalyticsLoading() {
  return (
    <div className="max-w-7xl mx-auto">
      {/* Page Header Skeleton */}
      <div className="mb-8">
        <Skeleton className="h-8 w-48 mb-2" />
        <Skeleton className="h-4 w-96" />
      </div>

      {/* Tabs Skeleton */}
      <div className="mb-6">
        <div className="flex space-x-8">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-8 w-24" />
          ))}
        </div>
      </div>

      {/* Analytics Content Skeleton */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <Skeleton className="h-6 w-32 mb-4" />
          <Skeleton className="h-64 w-full rounded-lg" />
        </div>
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <Skeleton className="h-6 w-32 mb-4" />
          <Skeleton className="h-64 w-full rounded-lg" />
        </div>
      </div>
    </div>
  )
}

export function ScoutingLoading() {
  return (
    <div className="max-w-7xl mx-auto">
      {/* Page Header Skeleton */}
      <div className="mb-8">
        <Skeleton className="h-8 w-48 mb-2" />
        <Skeleton className="h-4 w-96" />
      </div>

      {/* Scouting Reports Skeleton */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <Skeleton className="h-5 w-32 mb-4" />
            <div className="space-y-3">
              <Skeleton className="h-4 w-full" />
              <Skeleton className="h-4 w-3/4" />
              <Skeleton className="h-4 w-1/2" />
            </div>
            <div className="mt-4 flex justify-between">
              <Skeleton className="h-8 w-20 rounded-lg" />
              <Skeleton className="h-8 w-16 rounded-lg" />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

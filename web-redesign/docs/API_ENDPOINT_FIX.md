# API Endpoint Fix - Admin Endpoints

## 🐛 **Issue Identified**

The frontend was trying to access admin endpoints with the wrong URL structure:
- **❌ Frontend was calling**: `http://localhost:8000/api/admin/plays/playdefinition/` (404 Not Found)
- **✅ Backend endpoints are at**: `http://localhost:8000/admin/plays/playdefinition/`

## 🔧 **Root Cause**

The issue was that the main API client uses `/api/` prefix, but the admin endpoints are directly under the root domain without the `/api/` prefix.

## ✅ **Solution Implemented**

### **1. Created Separate Admin API Client**
- **Main API Client**: `http://localhost:8000/api/` (for regular endpoints)
- **Admin API Client**: `http://localhost:8000/` (for admin endpoints)

### **2. Updated API Configuration**
```typescript
// API Configuration
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api'
const ADMIN_API_BASE_URL = import.meta.env.VITE_ADMIN_API_BASE_URL || 'http://localhost:8000'

// Create separate axios instances
const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,  // http://localhost:8000/api
  // ...
})

const adminApiClient: AxiosInstance = axios.create({
  baseURL: ADMIN_API_BASE_URL,  // http://localhost:8000
  // ...
})
```

### **3. Exported Admin API Methods**
```typescript
export const adminApi = {
  get: <T = unknown>(url: string, config?: AxiosRequestConfig): Promise<T> =>
    retryNetworkOperation(() => 
      adminApiClient.get(url, config).then(response => response.data)
    ),
  // ... other methods
}
```

### **4. Updated Playbook Service**
- **Before**: Used `api.get('/admin/plays/playdefinition/')` → `http://localhost:8000/api/admin/plays/playdefinition/` ❌
- **After**: Uses `adminApi.get('/admin/plays/playdefinition/')` → `http://localhost:8000/admin/plays/playdefinition/` ✅

## 📁 **Files Updated**

- ✅ `src/services/api.ts` - Added admin API client and methods
- ✅ `src/services/playbook.ts` - Updated to use adminApi instead of api
- ✅ `src/services/apiWithFallback.ts` - Updated fallback methods to use adminApi

## 🎯 **Current Endpoint Structure**

### **Regular API Endpoints** (using `api` client)
```
GET    http://localhost:8000/api/games/
GET    http://localhost:8000/api/teams/
GET    http://localhost:8000/api/players/
GET    http://localhost:8000/api/users/
```

### **Admin API Endpoints** (using `adminApi` client)
```
GET    http://localhost:8000/admin/plays/playdefinition/
GET    http://localhost:8000/admin/plays/playcategory/
POST   http://localhost:8000/admin/plays/playdefinition/
PUT    http://localhost:8000/admin/plays/playdefinition/{id}/
DELETE http://localhost:8000/admin/plays/playdefinition/{id}/
```

## 🧪 **Testing**

1. **Navigate to Playbook** (`/playbook`)
2. **Check Browser Console** (F12) for:
   - `🎯 Loading plays from database...`
   - `✅ Plays fetched successfully from backend`
   - OR: `⚠️ Backend unavailable, using mock plays data` (if backend is down)

3. **Verify Network Tab**:
   - Should see requests to `http://localhost:8000/admin/plays/playdefinition/`
   - Should NOT see 404 errors anymore

## 🔧 **Environment Variables**

You can now configure the admin API base URL separately:
```env
VITE_API_BASE_URL=http://localhost:8000/api
VITE_ADMIN_API_BASE_URL=http://localhost:8000
```

## 📝 **Notes**

- **Authentication**: Both API clients use the same authentication interceptors
- **Error Handling**: Both clients have the same error handling and retry logic
- **Fallback**: Mock data fallback still works if backend is unavailable
- **Type Safety**: Full TypeScript support maintained

The playbook should now successfully connect to your existing backend endpoints! 🏀✨

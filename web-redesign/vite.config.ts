import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'
import { visualizer } from 'rollup-plugin-visualizer'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const isProduction = mode === 'production'
  
  return {
    plugins: [
      react(),
      // Bundle analyzer for production builds
      isProduction && visualizer({
        filename: 'dist/stats.html',
        open: false,
        gzipSize: true,
        brotliSize: true,
      }),
    ].filter(Boolean),
    resolve: {
      alias: {
        '@': resolve(__dirname, './src'),
      },
    },
    build: {
      target: 'es2015',
      outDir: 'dist',
      assetsDir: 'assets',
      sourcemap: isProduction ? false : true,
      minify: isProduction ? 'terser' : false,
      cssCodeSplit: true,
      rollupOptions: {
        input: {
          main: resolve(__dirname, 'index.html'),
        },
        output: {
          manualChunks: (id) => {
            // Vendor chunks
            if (id.includes('node_modules')) {
              if (id.includes('react') || id.includes('react-dom')) {
                return 'react-vendor'
              }
              if (id.includes('react-router')) {
                return 'router-vendor'
              }
              if (id.includes('@heroicons')) {
                return 'icons-vendor'
              }
              if (id.includes('axios') || id.includes('zustand')) {
                return 'utils-vendor'
              }
              if (id.includes('jspdf') || id.includes('html2canvas') || id.includes('xlsx')) {
                return 'export-vendor'
              }
              if (id.includes('recharts')) {
                return 'charts-vendor'
              }
              return 'vendor'
            }
            
            // App chunks
            if (id.includes('/src/pages/')) {
              return 'pages'
            }
            if (id.includes('/src/components/')) {
              return 'components'
            }
            if (id.includes('/src/hooks/')) {
              return 'hooks'
            }
            if (id.includes('/src/services/')) {
              return 'services'
            }
            if (id.includes('/src/utils/')) {
              return 'utils'
            }
          },
          chunkFileNames: (_chunkInfo) => {
            return `js/[name]-[hash].js`
          },
          entryFileNames: 'js/[name]-[hash].js',
          assetFileNames: (assetInfo) => {
            if (!assetInfo.name) return 'assets/[name]-[hash].[ext]'
            const info = assetInfo.name.split('.')
            const ext = info[info.length - 1]
            if (/\.(css)$/.test(assetInfo.name)) {
              return `css/[name]-[hash].${ext}`
            }
            if (/\.(png|jpe?g|svg|gif|tiff|bmp|ico)$/i.test(assetInfo.name)) {
              return `images/[name]-[hash].${ext}`
            }
            if (/\.(woff2?|eot|ttf|otf)$/i.test(assetInfo.name)) {
              return `fonts/[name]-[hash].${ext}`
            }
            return `assets/[name]-[hash].${ext}`
          },
        },
      },
      // terserOptions: isProduction ? {
      //   compress: {
      //     drop_console: true,
      //     drop_debugger: true,
      //     pure_funcs: ['console.log', 'console.info', 'console.debug', 'console.warn'],
      //   },
      //   mangle: {
      //     safari10: true,
      //   },
      //   format: {
      //     comments: false,
      //   },
      // } : undefined,
      chunkSizeWarningLimit: 1000,
    },
    optimizeDeps: {
      include: [
        'react',
        'react-dom',
        'react-router-dom',
        '@heroicons/react/24/outline',
        'axios',
        'zustand',
      ],
      exclude: ['@vite/client', '@vite/env'],
    },
    server: {
      port: 5173,
      host: true,
      open: true,
    },
    preview: {
      port: 4173,
      host: true,
    },
    define: {
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
    },
  }
})

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        'fortaleza-blue': '#1e3a8a',
        'fortaleza-gold': '#f59e0b',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}

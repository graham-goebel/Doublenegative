import type { Config } from 'tailwindcss'

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        panel: '#1a1a1a',
        surface: '#242424',
        border: '#333333',
        accent: '#e8a838',
      },
    },
  },
  plugins: [],
} satisfies Config

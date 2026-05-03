/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,jsx,ts,tsx}', './src/**/*.{js,jsx,ts,tsx}'],
  presets: [require('nativewind/preset')],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Modern Craft palette — LIGHT mode (default).
        background: '#FAF6F0',
        foreground: '#1C1612',
        primary: {
          DEFAULT: '#A1602F',
          foreground: '#FAF6F0',
        },
        muted: {
          DEFAULT: '#EAE0D3',
          foreground: '#5C4E40',
        },
        accent: {
          DEFAULT: '#5C7548', // WCAG AA: 4.7:1 vs cream foreground
          foreground: '#FAF6F0',
        },
        border: '#DCD0C0',
        input: '#EAE0D3',
        ring: '#A1602F',
        danger: {
          DEFAULT: '#B23832',
          foreground: '#FAF6F0',
        },
        success: {
          DEFAULT: '#456236', // WCAG AA: 6.4:1 vs cream foreground
          foreground: '#FAF6F0',
        },
        waiting: '#C88226',
        shorn: '#5C7548',

        // Modern Craft palette — DARK mode counterparts (suffix `-dark`).
        // Use via `dark:` variant: className="bg-background dark:bg-background-dark"
        'background-dark': '#16120F',
        'foreground-dark': '#F0E8DC',
        'primary-dark': {
          DEFAULT: '#C68A58',
          foreground: '#16120F',
        },
        'muted-dark': {
          DEFAULT: '#302820',
          foreground: '#B4A490',
        },
        'accent-dark': {
          DEFAULT: '#98B282',
          foreground: '#16120F',
        },
        'border-dark': '#3C322A',
        'input-dark': '#302820',
        'ring-dark': '#C68A58',
        'danger-dark': {
          DEFAULT: '#DC605A',
          foreground: '#16120F',
        },
        'success-dark': {
          DEFAULT: '#98B882',
          foreground: '#16120F',
        },
        'waiting-dark': '#DC9E4E',
        'shorn-dark': '#98B282',
      },
    },
  },
  plugins: [],
};

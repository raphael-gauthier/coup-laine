import { vars } from 'nativewind';

/**
 * Modern Craft palette — values are space-separated RGB triplets so they can
 * be consumed by tailwind's `rgb(var(--color-x) / <alpha-value>)` form.
 *
 * On native, these are applied via `vars()` as an inline style on a root view.
 * On web, the same values are duplicated in `global.css` under `:root` and
 * `.dark` rules so the CSS class strategy works there too.
 */

export const lightTokens = {
  '--color-background': '250 246 240',
  '--color-foreground': '28 22 18',
  '--color-primary': '161 96 47',
  '--color-primary-foreground': '250 246 240',
  '--color-muted': '234 224 211',
  '--color-muted-foreground': '92 78 64',
  '--color-accent': '116 142 96',
  '--color-accent-foreground': '250 246 240',
  '--color-border': '220 208 192',
  '--color-input': '234 224 211',
  '--color-ring': '161 96 47',
  '--color-danger': '178 56 50',
  '--color-danger-foreground': '250 246 240',
  '--color-success': '84 122 70',
  '--color-success-foreground': '250 246 240',
  '--color-waiting': '200 130 38',
  '--color-shorn': '116 142 96',
} as const;

export const darkTokens = {
  '--color-background': '22 18 15',
  '--color-foreground': '240 232 220',
  '--color-primary': '198 138 88',
  '--color-primary-foreground': '22 18 15',
  '--color-muted': '48 40 32',
  '--color-muted-foreground': '180 164 144',
  '--color-accent': '152 178 130',
  '--color-accent-foreground': '22 18 15',
  '--color-border': '60 50 42',
  '--color-input': '48 40 32',
  '--color-ring': '198 138 88',
  '--color-danger': '220 96 90',
  '--color-danger-foreground': '22 18 15',
  '--color-success': '152 184 130',
  '--color-success-foreground': '22 18 15',
  '--color-waiting': '220 158 78',
  '--color-shorn': '152 178 130',
} as const;

export const lightTheme = vars(lightTokens);
export const darkTheme = vars(darkTokens);

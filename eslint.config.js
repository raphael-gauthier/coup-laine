// https://docs.expo.dev/guides/using-eslint/
const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');
const tsPlugin = require('@typescript-eslint/eslint-plugin');

module.exports = defineConfig([
  expoConfig,
  {
    ignores: ['dist/*'],
  },
  {
    plugins: { '@typescript-eslint': tsPlugin },
    rules: {
      // Underscore-prefixed args/vars are intentional placeholders.
      '@typescript-eslint/no-unused-vars': [
        'warn',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' },
      ],
    },
  },
  {
    // Zod schemas use `export const X = z.object(...)` paired with
    // `export type X = z.infer<typeof X>`. The intentional name reuse trips
    // no-redeclare even though the runtime value and the type are distinct.
    files: ['src/domain/models/**/*.ts'],
    plugins: { '@typescript-eslint': tsPlugin },
    rules: {
      '@typescript-eslint/no-redeclare': 'off',
    },
  },
]);

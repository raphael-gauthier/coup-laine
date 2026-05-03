import type { ClientStatus } from '@/domain/use-cases/client-status';

export interface StatusTokens {
  /** Full bg class string with `dark:` variant baked in. Use as-is. */
  bgClass: string;
  /** Full text class string with `dark:` variant baked in. Use as-is. */
  textClass: string;
}

/**
 * Maps a client status to themed Tailwind class strings. Each value is a
 * **complete static literal** (light + dark together) so Tailwind's content
 * scanner picks them up at build time. Don't concatenate `dark:` at runtime —
 * Tailwind would not generate the corresponding CSS.
 */
export function clientStatusColor(status: ClientStatus): StatusTokens {
  switch (status) {
    case 'waiting':
      return {
        bgClass: 'bg-waiting dark:bg-waiting-dark',
        textClass: 'text-primary-foreground dark:text-primary-dark-foreground',
      };
    case 'shorn-recent':
      return {
        bgClass: 'bg-shorn dark:bg-shorn-dark',
        textClass: 'text-primary-foreground dark:text-primary-dark-foreground',
      };
    case 'shorn-old':
      return {
        bgClass: 'bg-muted dark:bg-muted-dark',
        textClass: 'text-muted-foreground dark:text-muted-dark-foreground',
      };
    case 'never':
      return {
        bgClass: 'bg-transparent',
        textClass: 'text-muted-foreground dark:text-muted-dark-foreground',
      };
  }
}

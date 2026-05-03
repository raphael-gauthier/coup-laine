import type { ClientStatus } from '@/domain/use-cases/client-status';

export interface StatusTokens {
  bgClass: string;
  textClass: string;
  /** Settings key whose value is the hex colour, used when reading from settings. */
  settingsKey: 'marker_default_color' | 'marker_waiting_color' | 'marker_scheduled_color' | 'marker_done_color' | 'marker_no_animals_color' | 'marker_banned_color';
}

export function clientStatusColor(status: ClientStatus): StatusTokens {
  switch (status) {
    case 'waiting':
      return {
        bgClass: 'bg-waiting dark:bg-waiting-dark',
        textClass: 'text-primary-foreground dark:text-primary-dark-foreground',
        settingsKey: 'marker_waiting_color',
      };
    case 'scheduled':
      return {
        bgClass: 'bg-primary dark:bg-primary-dark',
        textClass: 'text-primary-foreground dark:text-primary-dark-foreground',
        settingsKey: 'marker_scheduled_color',
      };
    case 'done':
      return {
        bgClass: 'bg-shorn dark:bg-shorn-dark',
        textClass: 'text-primary-foreground dark:text-primary-dark-foreground',
        settingsKey: 'marker_done_color',
      };
    case 'noAnimals':
      return {
        bgClass: 'bg-muted dark:bg-muted-dark',
        textClass: 'text-muted-foreground dark:text-muted-dark-foreground',
        settingsKey: 'marker_no_animals_color',
      };
    case 'banned':
      return {
        bgClass: 'bg-danger dark:bg-danger-dark',
        textClass: 'text-danger-foreground dark:text-danger-dark-foreground',
        settingsKey: 'marker_banned_color',
      };
    case 'default':
      return {
        bgClass: 'bg-transparent',
        textClass: 'text-muted-foreground dark:text-muted-dark-foreground',
        settingsKey: 'marker_default_color',
      };
  }
}

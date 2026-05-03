import type { ClientStatus } from '@/domain/use-cases/client-status';

export interface StatusTokens {
  bg: string;
  bgDark: string;
  text: string;
  textDark: string;
}

export function clientStatusColor(status: ClientStatus): StatusTokens {
  switch (status) {
    case 'waiting':
      return {
        bg: 'bg-waiting',
        bgDark: 'bg-waiting-dark',
        text: 'text-primary-foreground',
        textDark: 'text-primary-dark-foreground',
      };
    case 'shorn-recent':
      return {
        bg: 'bg-shorn',
        bgDark: 'bg-shorn-dark',
        text: 'text-primary-foreground',
        textDark: 'text-primary-dark-foreground',
      };
    case 'shorn-old':
      return {
        bg: 'bg-muted',
        bgDark: 'bg-muted-dark',
        text: 'text-muted-foreground',
        textDark: 'text-muted-dark-foreground',
      };
    case 'never':
      return {
        bg: 'bg-transparent',
        bgDark: 'bg-transparent',
        text: 'text-muted-foreground',
        textDark: 'text-muted-dark-foreground',
      };
  }
}

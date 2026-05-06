export const LEGAL_URLS = {
  legalNotices:    'https://ravnkode.com/coup-laine/legal/mentions-legales.html',
  privacyPolicy:   'https://ravnkode.com/coup-laine/legal/politique-confidentialite.html',
  terms:           'https://ravnkode.com/coup-laine/legal/cgu.html',
} as const;

export type LegalUrlKey = keyof typeof LEGAL_URLS;

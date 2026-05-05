import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import { getLocales } from 'expo-localization';
import fr from './locales/fr.json';

const deviceLocale = getLocales()[0]?.languageCode ?? 'fr';

// eslint-disable-next-line import/no-named-as-default-member
i18n.use(initReactI18next).init({
  resources: { fr: { translation: fr } },
  lng: deviceLocale === 'fr' ? 'fr' : 'fr',
  fallbackLng: 'fr',
  interpolation: { escapeValue: false },
  returnNull: false,
});

export default i18n;

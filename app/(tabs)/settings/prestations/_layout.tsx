import { Stack } from 'expo-router';

export default function PrestationsLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: true,
        headerStyle: { backgroundColor: 'transparent' },
        animation: 'slide_from_right',
      }}
    />
  );
}

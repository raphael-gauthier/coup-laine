import { Stack } from 'expo-router';

export default function ProximityLayout() {
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

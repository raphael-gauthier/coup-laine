import { Redirect } from 'expo-router';
import { ActivityIndicator, View } from 'react-native';
import { useOnboardingComplete } from '@/state/queries/settings';

export default function Index() {
  const { data: complete, isLoading } = useOnboardingComplete();

  if (isLoading) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator />
      </View>
    );
  }

  return <Redirect href={complete ? '/(tabs)/clients' : '/onboarding/welcome' as never} />;
}

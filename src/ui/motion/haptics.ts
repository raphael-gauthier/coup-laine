import * as Haptics from 'expo-haptics';

export const haptics = {
  selection: () => Haptics.selectionAsync(),
  lightTap: () => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light),
  mediumTap: () => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium),
  heavyTap: () => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy),
  success: () => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success),
  warning: () => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning),
  error: () => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error),
};

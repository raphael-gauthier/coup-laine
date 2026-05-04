import { useContext, type ReactElement, type ComponentType } from 'react';
import { StyleSheet, type StyleProp, type ViewStyle } from 'react-native';
import { BottomTabBarHeightContext } from '@react-navigation/bottom-tabs';
import DraggableFlatList, {
  type RenderItemParams,
  ScaleDecorator,
} from 'react-native-draggable-flatlist';

interface Props<T> {
  data: T[];
  keyExtractor: (item: T) => string;
  onReorder: (next: T[]) => void;
  renderItem: (params: { item: T; index: number; drag: () => void; isActive: boolean }) => ReactElement;
  /**
   * Use these to embed surrounding content (form fields, totals, save buttons)
   * inside the same scroll surface as the draggable items. This is the only
   * way to avoid the "VirtualizedLists nested in ScrollView" RN error.
   */
  ListHeaderComponent?: ComponentType | ReactElement | null;
  ListFooterComponent?: ComponentType | ReactElement | null;
  contentContainerStyle?: StyleProp<ViewStyle>;
}

export function DraggableList<T>({
  data,
  keyExtractor,
  onReorder,
  renderItem,
  ListHeaderComponent,
  ListFooterComponent,
  contentContainerStyle,
}: Props<T>) {
  // Unlike RN's ScrollView, DraggableFlatList doesn't auto-inset for the
  // bottom tab bar — its footer ends up half-hidden behind the bar. Read the
  // tab bar height directly from the context (returns undefined outside a
  // tab navigator, so the wrapper is safe to use anywhere) and bake it into
  // contentContainerStyle.paddingBottom so callers don't have to think
  // about it.
  const tabBarHeight = useContext(BottomTabBarHeightContext) ?? 0;
  const flat = StyleSheet.flatten(contentContainerStyle) ?? {};
  const callerPaddingBottom = typeof flat.paddingBottom === 'number' ? flat.paddingBottom : 0;
  const mergedStyle = {
    ...flat,
    paddingBottom: callerPaddingBottom + tabBarHeight,
  };

  return (
    <DraggableFlatList
      data={data}
      keyExtractor={keyExtractor}
      onDragEnd={({ data: next }) => onReorder(next)}
      ListHeaderComponent={ListHeaderComponent}
      ListFooterComponent={ListFooterComponent}
      contentContainerStyle={mergedStyle}
      renderItem={({ item, getIndex, drag, isActive }: RenderItemParams<T>) => (
        <ScaleDecorator>
          {renderItem({ item, index: getIndex() ?? 0, drag, isActive })}
        </ScaleDecorator>
      )}
    />
  );
}

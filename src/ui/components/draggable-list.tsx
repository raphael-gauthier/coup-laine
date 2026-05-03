import type { ReactElement, ComponentType } from 'react';
import type { StyleProp, ViewStyle } from 'react-native';
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
  return (
    <DraggableFlatList
      data={data}
      keyExtractor={keyExtractor}
      onDragEnd={({ data: next }) => onReorder(next)}
      ListHeaderComponent={ListHeaderComponent}
      ListFooterComponent={ListFooterComponent}
      contentContainerStyle={contentContainerStyle}
      renderItem={({ item, getIndex, drag, isActive }: RenderItemParams<T>) => (
        <ScaleDecorator>
          {renderItem({ item, index: getIndex() ?? 0, drag, isActive })}
        </ScaleDecorator>
      )}
    />
  );
}

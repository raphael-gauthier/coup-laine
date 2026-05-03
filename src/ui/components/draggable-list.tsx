import type { ReactElement } from 'react';
import DraggableFlatList, {
  type RenderItemParams,
  ScaleDecorator,
} from 'react-native-draggable-flatlist';

interface Props<T> {
  data: T[];
  keyExtractor: (item: T) => string;
  onReorder: (next: T[]) => void;
  renderItem: (params: { item: T; index: number; drag: () => void; isActive: boolean }) => ReactElement;
}

export function DraggableList<T>({ data, keyExtractor, onReorder, renderItem }: Props<T>) {
  return (
    <DraggableFlatList
      data={data}
      keyExtractor={keyExtractor}
      onDragEnd={({ data: next }) => onReorder(next)}
      renderItem={({ item, getIndex, drag, isActive }: RenderItemParams<T>) => (
        <ScaleDecorator>
          {renderItem({ item, index: getIndex() ?? 0, drag, isActive })}
        </ScaleDecorator>
      )}
    />
  );
}

interface Input {
  stopIds: string[];
  distanceKm: (from: string, to: string) => number;
  twoOpt?: boolean;
}

export function optimizeTourOrder({ stopIds, distanceKm, twoOpt = true }: Input): string[] {
  if (stopIds.length <= 1) return [...stopIds];

  const remaining = new Set(stopIds);
  const order: string[] = [];
  let current = 'BASE';
  while (remaining.size > 0) {
    let best: string | null = null;
    let bestD = Infinity;
    for (const id of remaining) {
      const d = distanceKm(current, id);
      if (d < bestD) {
        bestD = d;
        best = id;
      }
    }
    if (best == null) break;
    order.push(best);
    remaining.delete(best);
    current = best;
  }

  if (!twoOpt) return order;

  const totalCost = (route: string[]): number => {
    let cost = distanceKm('BASE', route[0]!);
    for (let i = 0; i < route.length - 1; i++) {
      cost += distanceKm(route[i]!, route[i + 1]!);
    }
    cost += distanceKm(route[route.length - 1]!, 'BASE');
    return cost;
  };

  let improved = true;
  while (improved) {
    improved = false;
    for (let i = 0; i < order.length - 1; i++) {
      for (let j = i + 1; j < order.length; j++) {
        const candidate = [
          ...order.slice(0, i),
          ...order.slice(i, j + 1).reverse(),
          ...order.slice(j + 1),
        ];
        if (totalCost(candidate) < totalCost(order)) {
          order.splice(0, order.length, ...candidate);
          improved = true;
        }
      }
    }
  }

  return order;
}

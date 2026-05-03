export function countBrackets(distanceKm: number, bracketSizeKm: number): number {
  if (bracketSizeKm <= 0) {
    throw new Error('bracketSizeKm must be positive');
  }
  if (distanceKm <= 0) return 0;
  return Math.ceil(distanceKm / bracketSizeKm);
}

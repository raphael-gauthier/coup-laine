import { countBrackets } from './bracket-counter';

interface Input {
  totalDistanceKm: number;
  stopCount: number;
  pricePerBracket: number;
  bracketSizeKm: number;
}

interface Output {
  totalEuros: number;
  perStop: number[];
}

export function splitTravelCost(input: Input): Output {
  const { totalDistanceKm, stopCount, pricePerBracket, bracketSizeKm } = input;

  const brackets = countBrackets(totalDistanceKm, bracketSizeKm);
  const totalEuros = brackets * pricePerBracket;

  if (stopCount === 0) {
    return { totalEuros, perStop: [] };
  }
  if (stopCount === 1) {
    return { totalEuros, perStop: [totalEuros] };
  }

  const baseShare = Math.floor(totalEuros / stopCount);
  let remainder = totalEuros - baseShare * stopCount;
  const perStop: number[] = [];
  for (let i = 0; i < stopCount; i++) {
    if (remainder > 0) {
      perStop.push(baseShare + 1);
      remainder--;
    } else {
      perStop.push(baseShare);
    }
  }
  return { totalEuros, perStop };
}

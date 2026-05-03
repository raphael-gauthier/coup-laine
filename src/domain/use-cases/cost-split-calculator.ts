import { countBrackets } from './bracket-counter';

interface Input {
  /** Base-to-each-stop distance, in km. Used to find the farthest stop. */
  baseToStopDistancesKm: number[];
  /** Inter-stop distances (n-1 entries for n stops). */
  interStopDistancesKm: number[];
  pricePerBracket: number;
  bracketSizeKm: number;
}

interface Output {
  totalEuros: number;
  farthestEuros: number;
  interEuros: number;
  perStop: number[];
}

export function splitTravelCost(input: Input): Output {
  const { baseToStopDistancesKm, interStopDistancesKm, pricePerBracket, bracketSizeKm } = input;
  const stopCount = baseToStopDistancesKm.length;
  if (stopCount === 0) {
    return { totalEuros: 0, perStop: [], farthestEuros: 0, interEuros: 0 };
  }

  const maxBase = Math.max(...baseToStopDistancesKm);
  const sumInter = interStopDistancesKm.reduce((a, b) => a + b, 0);

  const farthestBrackets = countBrackets(maxBase, bracketSizeKm);
  const interBrackets = countBrackets(sumInter, bracketSizeKm);
  const farthestEuros = farthestBrackets * pricePerBracket;
  const interEuros = interBrackets * pricePerBracket;
  const totalEuros = farthestEuros + interEuros;

  if (stopCount === 1) {
    return { totalEuros, perStop: [totalEuros], farthestEuros, interEuros };
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
  return { totalEuros, perStop, farthestEuros, interEuros };
}

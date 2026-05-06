import { countBrackets } from './bracket-counter';

interface Input {
  /** Distance from base to client in kilometers (>= 0). */
  distanceKm: number;
  /** Size of one bracket in km (e.g. 10). */
  bracketKm: number;
  /** Price per bracket in euros (e.g. 8). */
  feePerBracket: number;
}

/** Returns the fee in integer cents. */
export function computeClientTravelFee(input: Input): number {
  const brackets = countBrackets(input.distanceKm, input.bracketKm);
  return Math.round(brackets * input.feePerBracket * 100);
}

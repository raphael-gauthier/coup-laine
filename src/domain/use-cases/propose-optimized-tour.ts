import { haversineDistanceKm } from '@/lib/haversine-distance';
import { optimizeTourOrder } from './tour-order-optimizer';
import { estimateTourDuration } from './tour-duration-estimator';

interface ClientLite {
  id: string;
  addressCity: string | null;
  latitude: number | null;
  longitude: number | null;
}

interface Input {
  communeName: string;
  targetMinutes: number;
  waitingClients: ClientLite[];
  distanceKm: (from: string, to: string) => number;
  travelMinutesBetween: (from: string, to: string) => number;
  toleranceMinutes?: number;
}

export interface OptimizedProposal {
  selectedClientIds: string[];
  estimatedDurationMinutes: number;
  isUnderTarget: boolean;
  isOverTarget: boolean;
}

const EMPTY_PROPOSAL: OptimizedProposal = {
  selectedClientIds: [],
  estimatedDurationMinutes: 0,
  isUnderTarget: false,
  isOverTarget: false,
};

export function proposeOptimizedTour({
  communeName,
  targetMinutes,
  waitingClients,
  distanceKm,
  travelMinutesBetween,
  toleranceMinutes = 30,
}: Input): OptimizedProposal {
  const eligible = waitingClients.filter(
    (c) => c.latitude != null && c.longitude != null
  );
  const seedIds = eligible.filter((c) => c.addressCity === communeName).map((c) => c.id);
  if (seedIds.length === 0) return EMPTY_PROPOSAL;

  const byId = new Map(eligible.map((c) => [c.id, c]));

  const seedClients = seedIds.map((id) => byId.get(id)!);
  const bary = {
    lat: seedClients.reduce((s, c) => s + c.latitude!, 0) / seedClients.length,
    lon: seedClients.reduce((s, c) => s + c.longitude!, 0) / seedClients.length,
  };
  const distSqToBary = (id: string): number => {
    const c = byId.get(id)!;
    const d = haversineDistanceKm({ lat: c.latitude!, lon: c.longitude! }, bary);
    return d * d;
  };

  const computeOrderAndDuration = (ids: string[]): { ordered: string[]; minutes: number } => {
    const ordered = optimizeTourOrder({ stopIds: ids, distanceKm });
    const minutes = estimateTourDuration({
      stops: ordered.map((id) => ({ clientId: id, plannedServices: [] })),
      travelMinutesBetween,
    });
    return { ordered, minutes };
  };

  let { ordered: current, minutes: duration } = computeOrderAndDuration(seedIds);

  const lower = targetMinutes - toleranceMinutes;
  const upper = targetMinutes + toleranceMinutes;

  if (duration < lower) {
    // EXTENSION: add nearest-to-barycentre non-commune clients until inside the target band.
    const extras = eligible
      .filter((c) => c.addressCity !== communeName && !seedIds.includes(c.id))
      .sort((a, b) => distSqToBary(a.id) - distSqToBary(b.id));
    for (const cand of extras) {
      const next = [...current, cand.id];
      const { ordered, minutes } = computeOrderAndDuration(next);
      if (minutes > upper) break;
      current = ordered;
      duration = minutes;
    }
  } else if (duration > upper) {
    // CONTRACTION: drop farthest-from-barycentre stop until inside the band (or 1 stop left).
    while (current.length > 1 && duration > upper) {
      let farthestId = current[0]!;
      let farthestD = -Infinity;
      for (const id of current) {
        const d = distSqToBary(id);
        if (d > farthestD) {
          farthestD = d;
          farthestId = id;
        }
      }
      const next = current.filter((id) => id !== farthestId);
      const { ordered, minutes } = computeOrderAndDuration(next);
      current = ordered;
      duration = minutes;
    }
  }

  return {
    selectedClientIds: current,
    estimatedDurationMinutes: duration,
    isUnderTarget: duration < lower,
    isOverTarget: duration > upper,
  };
}

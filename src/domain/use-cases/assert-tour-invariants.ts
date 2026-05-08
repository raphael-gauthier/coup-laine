import type { Tour } from '@/domain/models/tour';

export function assertTourInvariants(tour: Tour): void {
  if (tour.status === 'planned' || tour.status === 'completed') {
    if (tour.scheduledDate == null || tour.departureTime == null) {
      throw new Error(
        `Tour ${tour.id} status=${tour.status} requires scheduledDate and departureTime`,
      );
    }
  }
  if (tour.status === 'draft') {
    if (tour.scheduledDate != null || tour.departureTime != null) {
      throw new Error(
        `Tour ${tour.id} status=draft must not carry scheduledDate or departureTime`,
      );
    }
  }
}

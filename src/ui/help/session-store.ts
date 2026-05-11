// Module-level mutable flag tracking whether ANY discovery coach-mark has
// already fired in the current process lifetime. Reset implicit at cold
// start (module re-evaluated). Resume after backgrounding preserves the
// flag. Used by useCoachMark to enforce the "at most 1 discovery per
// session" policy described in the Phase 2 spec.

let discoveryFiredThisSession = false;

export function hasDiscoveryFiredThisSession(): boolean {
  return discoveryFiredThisSession;
}

export function markDiscoveryFired(): void {
  discoveryFiredThisSession = true;
}

export function resetSessionDiscoveryFlag(): void {
  discoveryFiredThisSession = false;
}

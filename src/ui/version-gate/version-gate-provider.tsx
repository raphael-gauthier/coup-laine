import type { ReactNode } from 'react';
import { useVersionGate } from '@/state/hooks/use-version-gate';
import { useSoftUpdateSnooze } from '@/state/hooks/use-soft-update-snooze';
import { ForceUpdateScreen } from './force-update-screen';
import { SoftUpdateModal } from './soft-update-modal';

export function VersionGateProvider({ children }: { children: ReactNode }) {
  const gate = useVersionGate();
  const { loaded: snoozeLoaded, isSnoozed, snoozeFor } = useSoftUpdateSnooze();

  // While the snooze record is loading (a fast SecureStore read), render
  // nothing. We don't block on the gate query though — the network call can
  // take seconds on cold start and we don't want a black screen after the
  // splash hides. If a force-update decision arrives later, we swap the UI.
  if (!snoozeLoaded) return null;
  if (gate.kind === 'loading') return <>{children}</>;

  const decision = gate.decision;

  if (decision.kind === 'force-update') {
    return (
      <ForceUpdateScreen storeUrl={decision.storeUrl} security={decision.security} />
    );
  }

  if (decision.kind === 'soft-update' && !isSnoozed(decision.latest)) {
    return (
      <>
        {children}
        <SoftUpdateModal
          visible
          latestVersion={decision.latest}
          releaseNotesFr={decision.releaseNotesFr}
          security={decision.security}
          storeUrl={decision.storeUrl}
          onSnooze={() => void snoozeFor(decision.latest)}
        />
      </>
    );
  }

  return <>{children}</>;
}

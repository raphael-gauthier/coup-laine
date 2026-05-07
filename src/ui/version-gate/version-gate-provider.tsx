import type { ReactNode } from 'react';
import { useVersionGate } from '@/state/hooks/use-version-gate';
import { useSoftUpdateSnooze } from '@/state/hooks/use-soft-update-snooze';
import { ForceUpdateScreen } from './force-update-screen';
import { SoftUpdateModal } from './soft-update-modal';

export function VersionGateProvider({ children }: { children: ReactNode }) {
  const gate = useVersionGate();
  const { loaded: snoozeLoaded, isSnoozed, snoozeFor } = useSoftUpdateSnooze();

  // While the gate query is in-flight or the snooze record is loading, render
  // nothing. The Expo splash screen is still visible, so the user sees a
  // single static splash instead of a flash of UI.
  if (gate.kind === 'loading' || !snoozeLoaded) return null;

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

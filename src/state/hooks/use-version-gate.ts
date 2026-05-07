import { useEffect, useMemo } from 'react';
import { AppState, Platform as RNPlatform } from 'react-native';
import * as Application from 'expo-application';
import * as Sentry from '@sentry/react-native';
import { useVersionStatusQuery } from '@/state/queries/version-status';
import { evaluateVersionStatus } from '@/domain/use-cases/evaluate-version-status';
import type { Platform, VersionDecision } from '@/domain/models/version-status';

const SIX_HOURS_MS = 6 * 60 * 60 * 1000;

function resolvePlatform(): Platform | null {
  if (RNPlatform.OS === 'ios') return 'ios';
  if (RNPlatform.OS === 'android') return 'android';
  return null;
}

export type GateState =
  | { kind: 'loading' }
  | { kind: 'decided'; decision: VersionDecision };

export function useVersionGate(): GateState {
  const platform = resolvePlatform();
  const installed = Application.nativeApplicationVersion ?? '0.0.0';
  const query = useVersionStatusQuery(platform);

  // AppState listener: refetch when returning to foreground after staleTime.
  useEffect(() => {
    if (!platform) return;
    const sub = AppState.addEventListener('change', (next) => {
      if (next !== 'active') return;
      const updatedAt = query.dataUpdatedAt;
      if (!updatedAt || Date.now() - updatedAt > SIX_HOURS_MS) {
        void query.refetch();
      }
    });
    return () => sub.remove();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [platform, query.dataUpdatedAt]);

  const state = useMemo<GateState>(() => {
    if (!platform) return { kind: 'decided', decision: { kind: 'ok' } };
    if (query.isPending) return { kind: 'loading' };

    const result = query.data;
    if (!result || result.status === 'unavailable' || result.config === null) {
      return { kind: 'decided', decision: { kind: 'ok' } };
    }
    return {
      kind: 'decided',
      decision: evaluateVersionStatus(installed, result.config),
    };
  }, [platform, installed, query.isPending, query.data]);

  // Emit success breadcrumb once per decision change.
  useEffect(() => {
    if (state.kind !== 'decided' || !platform) return;
    const result = query.data;
    Sentry.addBreadcrumb({
      category: 'version-gate',
      level: 'info',
      message: 'version-gate.check.success',
      data: {
        platform,
        installed,
        latest: result?.config?.latestVersion,
        decision: state.decision.kind,
        fromCache: result?.status === 'stale',
      },
    });
  }, [state, platform, installed, query.data]);

  return state;
}

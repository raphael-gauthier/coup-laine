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

  return useMemo<GateState>(() => {
    // Web build or other non-mobile target → never gate.
    if (!platform) return { kind: 'decided', decision: { kind: 'ok' } };

    if (query.isPending) return { kind: 'loading' };

    const result = query.data;
    if (!result || result.status === 'unavailable' || result.config === null) {
      // Fail open.
      Sentry.addBreadcrumb({
        category: 'version-gate',
        level: 'info',
        message: 'version-gate.check.success',
        data: { platform, installed, decision: 'ok-fail-open', fromCache: false },
      });
      return { kind: 'decided', decision: { kind: 'ok' } };
    }

    const decision = evaluateVersionStatus(installed, result.config);
    Sentry.addBreadcrumb({
      category: 'version-gate',
      level: 'info',
      message: 'version-gate.check.success',
      data: {
        platform,
        installed,
        latest: result.config.latestVersion,
        decision: decision.kind,
        fromCache: result.status === 'stale',
      },
    });
    return { kind: 'decided', decision };
  }, [platform, installed, query.isPending, query.data]);
}

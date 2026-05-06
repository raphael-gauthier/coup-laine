import { renderHook, waitFor } from '@testing-library/react-native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import React from 'react';

const mockInvoke = jest.fn();
const mockSignOut = jest.fn();
const mockWipe = jest.fn();
const mockBootstrap = jest.fn();
const mockEnsureAnon = jest.fn();

jest.mock('@/infra/services/supabase', () => ({
  supabase: {
    functions: { invoke: (...args: unknown[]) => mockInvoke(...args) },
    auth: {
      signOut: () => mockSignOut(),
      onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => {} } } }),
      getSession: () => Promise.resolve({ data: { session: null } }),
    },
  },
}));
jest.mock('@/infra/db/wipe', () => ({ wipeLocalDatabase: () => mockWipe() }));
jest.mock('@/infra/db/bootstrap', () => ({ bootstrapDatabase: () => mockBootstrap() }));
jest.mock('@/infra/services/ensure-session', () => ({
  ensureAnonymousSession: () => mockEnsureAnon(),
}));
jest.mock('@/ui/components/error-toast', () => ({
  mutationErrorToast: jest.fn(),
  errorToast: jest.fn(),
  successToast: jest.fn(),
}));
jest.mock('@/i18n', () => ({ __esModule: true, default: { t: (k: string) => k } }));

import { useDeleteAccount } from '@/state/queries/auth';

function wrapper({ children }: { children: React.ReactNode }) {
  const qc = new QueryClient({ defaultOptions: { mutations: { retry: false } } });
  return <QueryClientProvider client={qc}>{children}</QueryClientProvider>;
}

beforeEach(() => {
  mockInvoke.mockReset();
  mockSignOut.mockReset();
  mockWipe.mockReset();
  mockBootstrap.mockReset();
  mockEnsureAnon.mockReset();
});

describe('useDeleteAccount', () => {
  it('happy path: invokes EF, wipes, bootstraps, ensures anon session', async () => {
    mockInvoke.mockResolvedValue({ data: { ok: true }, error: null });
    mockSignOut.mockResolvedValue({ error: null });
    mockWipe.mockResolvedValue(undefined);
    mockBootstrap.mockResolvedValue(undefined);
    mockEnsureAnon.mockResolvedValue(undefined);

    const { result } = renderHook(() => useDeleteAccount(), { wrapper });
    result.current.mutate();
    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(mockInvoke).toHaveBeenCalledWith('delete-account', { method: 'POST' });
    expect(mockWipe).toHaveBeenCalledTimes(1);
    expect(mockBootstrap).toHaveBeenCalledTimes(1);
    expect(mockEnsureAnon).toHaveBeenCalledTimes(1);
  });

  it('does not wipe local when Edge Function fails', async () => {
    mockInvoke.mockResolvedValue({ data: null, error: new Error('boom') });

    const { result } = renderHook(() => useDeleteAccount(), { wrapper });
    result.current.mutate();
    await waitFor(() => expect(result.current.isError).toBe(true));

    expect(mockWipe).not.toHaveBeenCalled();
    expect(mockBootstrap).not.toHaveBeenCalled();
  });

  it('signOut failure is swallowed (best-effort)', async () => {
    mockInvoke.mockResolvedValue({ data: { ok: true }, error: null });
    mockSignOut.mockRejectedValue(new Error('jwt invalid'));
    mockWipe.mockResolvedValue(undefined);
    mockBootstrap.mockResolvedValue(undefined);
    mockEnsureAnon.mockResolvedValue(undefined);

    const { result } = renderHook(() => useDeleteAccount(), { wrapper });
    result.current.mutate();
    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(mockEnsureAnon).toHaveBeenCalledTimes(1);
  });
});

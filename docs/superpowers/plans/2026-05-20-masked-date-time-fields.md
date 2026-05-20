# Masked Date/Time Fields Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 7 inline `DateTimePicker` blocks with editable masked `DateField`/`TimeField` components (keyboard entry + picker button), and fix the `onChange` deprecation warning by centralizing the picker behind the new `onValueChange`/`onDismiss` API.

**Architecture:** Two presentational components (`DateField`, `TimeField`) own a masked text buffer + a picker button. A pure, unit-tested module (`parse-date-input.ts`) holds the parsing/validation. Hosts pass `value`/`onChange`; components emit `onChange` only on a valid commit and surface validity via `onValidityChange` so single-form hosts can disable their Save button.

**Tech Stack:** React Native, Expo Router, `react-native-mask-input@1.2.3`, `@react-native-community/datetimepicker@9.1.0`, `date-fns@4`, react-hook-form, i18next, vitest.

**Scope note (validity gating):** `DateField`/`TimeField` never emit `onChange` for an invalid buffer, so a host's committed value is always valid. Explicit Save-button disabling via `onValidityChange` is wired in the standalone single-form hosts: `season.tsx`, `schedule-tour-sheet.tsx`, `manual-history-form.tsx`, `manual-entry-payment-sheet.tsx`, `stop-payment-sheet.tsx`. The multi-stop completion screen (`complete.tsx`, which renders N `PaymentEditor`s under one CTA) is intentionally **not** aggregate-gated — the inline error + no-invalid-commit guarantee already prevents bad data there. `tour-draft-editor.tsx`'s inline fields feed the schedule sheet's initial values (no direct commit), so they need no gating.

---

## File Structure

**Create:**
- `src/domain/use-cases/parse-date-input.ts` — pure parse/validate for `dd/MM/yyyy` and `HH:mm`.
- `tests/domain/parse-date-input.test.ts` — vitest tests for the above.
- `src/ui/components/date-field.tsx` — masked date input + calendar picker.
- `src/ui/components/time-field.tsx` — masked time input + clock picker.

**Modify:**
- `src/i18n/locales/fr.json` — add `dateField`/`timeField` keys.
- `src/ui/components/payment-editor.tsx` — paidAt → `DateField`, add `onPaidAtValidityChange`.
- `src/ui/components/manual-history-form.tsx` — date → `DateField`, gate Save buttons.
- `src/ui/components/manual-entry-payment-sheet.tsx` — gate Save via paidAt validity.
- `src/ui/components/stop-payment-sheet.tsx` — gate Save via paidAt validity.
- `src/ui/components/schedule-tour-sheet.tsx` — date/time → `DateField`/`TimeField`, gate Confirm.
- `src/ui/components/tour-draft-editor.tsx` — inline date/time → `DateField`/`TimeField`.
- `app/(tabs)/settings/season.tsx` — date → `DateField`, gate Save.

---

## Task 1: i18n keys

**Files:**
- Modify: `src/i18n/locales/fr.json`

- [ ] **Step 1: Add the `dateField` and `timeField` blocks**

Locate the `"statuses": { … }` block (around line 627) and insert these two blocks immediately before it (sibling top-level keys, valid JSON — mind the trailing comma):

```json
  "dateField": {
    "placeholder": "JJ/MM/AAAA",
    "invalid": "Date invalide (JJ/MM/AAAA)",
    "open_picker": "Ouvrir le calendrier"
  },
  "timeField": {
    "placeholder": "HH:MM",
    "invalid": "Heure invalide (HH:MM)",
    "open_picker": "Ouvrir le sélecteur d'heure"
  },
```

- [ ] **Step 2: Verify JSON is valid**

Run: `node -e "JSON.parse(require('fs').readFileSync('src/i18n/locales/fr.json','utf8')); console.log('OK')"`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add src/i18n/locales/fr.json
git commit -m "i18n(date-fields): add dateField/timeField strings"
```

---

## Task 2: Pure parse/validate logic

**Files:**
- Create: `src/domain/use-cases/parse-date-input.ts`
- Test: `tests/domain/parse-date-input.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/domain/parse-date-input.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { parseDateInput, parseTimeInput } from '@/domain/use-cases/parse-date-input';

describe('parseDateInput', () => {
  it('parses a valid date', () => {
    const r = parseDateInput('05/05/2026');
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.date.getFullYear()).toBe(2026);
      expect(r.date.getMonth()).toBe(4); // May = index 4
      expect(r.date.getDate()).toBe(5);
    }
  });

  it('rejects an empty string as empty', () => {
    expect(parseDateInput('')).toEqual({ ok: false, reason: 'empty' });
    expect(parseDateInput('   ')).toEqual({ ok: false, reason: 'empty' });
  });

  it('rejects an incomplete date as invalid', () => {
    expect(parseDateInput('05/05')).toEqual({ ok: false, reason: 'invalid' });
    expect(parseDateInput('5/5/26')).toEqual({ ok: false, reason: 'invalid' });
  });

  it('rejects an out-of-range date as invalid', () => {
    expect(parseDateInput('32/13/2026')).toEqual({ ok: false, reason: 'invalid' });
  });

  it('rejects a non-existent calendar date as invalid', () => {
    expect(parseDateInput('31/02/2026')).toEqual({ ok: false, reason: 'invalid' });
  });
});

describe('parseTimeInput', () => {
  it('parses a valid time', () => {
    expect(parseTimeInput('08:30')).toEqual({ ok: true, value: '08:30' });
    expect(parseTimeInput('23:59')).toEqual({ ok: true, value: '23:59' });
  });

  it('rejects empty as empty', () => {
    expect(parseTimeInput('')).toEqual({ ok: false, reason: 'empty' });
  });

  it('rejects out-of-range times as invalid', () => {
    expect(parseTimeInput('24:00')).toEqual({ ok: false, reason: 'invalid' });
    expect(parseTimeInput('25:70')).toEqual({ ok: false, reason: 'invalid' });
    expect(parseTimeInput('8:5')).toEqual({ ok: false, reason: 'invalid' });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pnpm vitest run tests/domain/parse-date-input.test.ts`
Expected: FAIL — cannot resolve `@/domain/use-cases/parse-date-input`.

- [ ] **Step 3: Write the implementation**

Create `src/domain/use-cases/parse-date-input.ts`:

```ts
import { parse, isValid, format } from 'date-fns';

const DATE_RE = /^\d{2}\/\d{2}\/\d{4}$/;
const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;

export type DateParseResult =
  | { ok: true; date: Date }
  | { ok: false; reason: 'empty' | 'invalid' };

export type TimeParseResult =
  | { ok: true; value: string }
  | { ok: false; reason: 'empty' | 'invalid' };

/** Parse a `JJ/MM/AAAA` string into a Date, rejecting incomplete or
 *  non-existent calendar dates (e.g. 31/02). */
export function parseDateInput(text: string): DateParseResult {
  const trimmed = text.trim();
  if (trimmed === '') return { ok: false, reason: 'empty' };
  if (!DATE_RE.test(trimmed)) return { ok: false, reason: 'invalid' };
  const parsed = parse(trimmed, 'dd/MM/yyyy', new Date());
  // Round-trip guards against date-fns rolling over impossible dates.
  if (!isValid(parsed) || format(parsed, 'dd/MM/yyyy') !== trimmed) {
    return { ok: false, reason: 'invalid' };
  }
  return { ok: true, date: parsed };
}

/** Parse a `HH:MM` (24h) string, validating hour/minute ranges. */
export function parseTimeInput(text: string): TimeParseResult {
  const trimmed = text.trim();
  if (trimmed === '') return { ok: false, reason: 'empty' };
  if (!TIME_RE.test(trimmed)) return { ok: false, reason: 'invalid' };
  return { ok: true, value: trimmed };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pnpm vitest run tests/domain/parse-date-input.test.ts`
Expected: PASS (8 tests).

- [ ] **Step 5: Commit**

```bash
git add src/domain/use-cases/parse-date-input.ts tests/domain/parse-date-input.test.ts
git commit -m "feat(date-fields): pure parse/validate for masked date & time input"
```

---

## Task 3: `DateField` component

**Files:**
- Create: `src/ui/components/date-field.tsx`

- [ ] **Step 1: Write the component**

Create `src/ui/components/date-field.tsx`:

```tsx
import { useEffect, useState } from 'react';
import { Platform, View, useColorScheme } from 'react-native';
import MaskInput from 'react-native-mask-input';
import DateTimePicker from '@react-native-community/datetimepicker';
import { Calendar } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format } from 'date-fns';

import { PressScale } from '@/ui/motion/press-scale';
import { FormField } from '@/ui/components/form-field';
import { useForegroundColor, useMutedForegroundColor } from '@/ui/theme/colors';
import { parseDateInput } from '@/domain/use-cases/parse-date-input';

const DATE_MASK = [/\d/, /\d/, '/', /\d/, /\d/, '/', /\d/, /\d/, /\d/, /\d/];

interface Props {
  label: string;
  value: Date | null;
  onChange: (date: Date | null) => void;
  onValidityChange?: (valid: boolean) => void;
  /** When false, an empty field is valid and emits `onChange(null)`. Default: true. */
  required?: boolean;
  accessibilityLabel?: string;
}

export function DateField({
  label, value, onChange, onValidityChange, required = true, accessibilityLabel,
}: Props) {
  const { t } = useTranslation();
  const fg = useForegroundColor();
  const mutedFg = useMutedForegroundColor();
  const isDark = useColorScheme() === 'dark';
  const [text, setText] = useState(value ? format(value, 'dd/MM/yyyy') : '');
  const [error, setError] = useState<string | null>(null);
  const [pickerOpen, setPickerOpen] = useState(false);

  // Resync the buffer when the committed value changes from outside
  // (e.g. the season screen's "Aujourd'hui" reset button).
  useEffect(() => {
    setText(value ? format(value, 'dd/MM/yyyy') : '');
    setError(null);
    onValidityChange?.(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  const handleText = (masked: string) => {
    setText(masked);
    const result = parseDateInput(masked);
    if (result.ok) {
      setError(null);
      onValidityChange?.(true);
      onChange(result.date);
    } else if (result.reason === 'empty' && !required) {
      setError(null);
      onValidityChange?.(true);
      onChange(null);
    } else {
      setError(t('dateField.invalid'));
      onValidityChange?.(false);
    }
  };

  const handlePicked = (d: Date) => {
    setText(format(d, 'dd/MM/yyyy'));
    setError(null);
    onValidityChange?.(true);
    onChange(d);
  };

  return (
    <FormField label={label} error={error ?? undefined}>
      <View className="flex-row items-center rounded-2xl border border-border dark:border-border-dark bg-input dark:bg-input-dark px-4">
        <MaskInput
          value={text}
          onChangeText={handleText}
          mask={DATE_MASK}
          keyboardType="number-pad"
          placeholder={t('dateField.placeholder')}
          placeholderTextColor={isDark ? '#B4A490' : '#5C4E40'}
          style={{ flex: 1, paddingVertical: 12, fontSize: 16, color: fg }}
          accessibilityLabel={accessibilityLabel ?? label}
        />
        <PressScale
          onPress={() => setPickerOpen(true)}
          accessibilityLabel={t('dateField.open_picker')}
          className="pl-2 py-2"
        >
          <Calendar size={20} color={mutedFg} />
        </PressScale>
      </View>
      {pickerOpen ? (
        <DateTimePicker
          value={value ?? new Date()}
          mode="date"
          onValueChange={(_, d) => {
            setPickerOpen(Platform.OS === 'ios');
            handlePicked(d);
          }}
          onDismiss={() => setPickerOpen(false)}
        />
      ) : null}
    </FormField>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `pnpm typecheck`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add src/ui/components/date-field.tsx
git commit -m "feat(date-fields): DateField masked input with calendar picker"
```

---

## Task 4: `TimeField` component

**Files:**
- Create: `src/ui/components/time-field.tsx`

- [ ] **Step 1: Write the component**

Create `src/ui/components/time-field.tsx`:

```tsx
import { useEffect, useState } from 'react';
import { Platform, View, useColorScheme } from 'react-native';
import MaskInput from 'react-native-mask-input';
import DateTimePicker from '@react-native-community/datetimepicker';
import { Clock } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format } from 'date-fns';

import { PressScale } from '@/ui/motion/press-scale';
import { FormField } from '@/ui/components/form-field';
import { useForegroundColor, useMutedForegroundColor } from '@/ui/theme/colors';
import { parseTimeInput } from '@/domain/use-cases/parse-date-input';

const TIME_MASK = [/\d/, /\d/, ':', /\d/, /\d/];

function timeToDate(value: string | null): Date {
  const [h, m] = (value ?? '08:00').split(':').map(Number);
  const d = new Date();
  d.setHours(h ?? 0, m ?? 0, 0, 0);
  return d;
}

interface Props {
  label: string;
  value: string | null; // 'HH:mm'
  onChange: (value: string | null) => void;
  onValidityChange?: (valid: boolean) => void;
  /** When false, an empty field is valid and emits `onChange(null)`. Default: true. */
  required?: boolean;
  accessibilityLabel?: string;
}

export function TimeField({
  label, value, onChange, onValidityChange, required = true, accessibilityLabel,
}: Props) {
  const { t } = useTranslation();
  const fg = useForegroundColor();
  const mutedFg = useMutedForegroundColor();
  const isDark = useColorScheme() === 'dark';
  const [text, setText] = useState(value ?? '');
  const [error, setError] = useState<string | null>(null);
  const [pickerOpen, setPickerOpen] = useState(false);

  useEffect(() => {
    setText(value ?? '');
    setError(null);
    onValidityChange?.(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  const handleText = (masked: string) => {
    setText(masked);
    const result = parseTimeInput(masked);
    if (result.ok) {
      setError(null);
      onValidityChange?.(true);
      onChange(result.value);
    } else if (result.reason === 'empty' && !required) {
      setError(null);
      onValidityChange?.(true);
      onChange(null);
    } else {
      setError(t('timeField.invalid'));
      onValidityChange?.(false);
    }
  };

  const handlePicked = (d: Date) => {
    const next = format(d, 'HH:mm');
    setText(next);
    setError(null);
    onValidityChange?.(true);
    onChange(next);
  };

  return (
    <FormField label={label} error={error ?? undefined}>
      <View className="flex-row items-center rounded-2xl border border-border dark:border-border-dark bg-input dark:bg-input-dark px-4">
        <MaskInput
          value={text}
          onChangeText={handleText}
          mask={TIME_MASK}
          keyboardType="number-pad"
          placeholder={t('timeField.placeholder')}
          placeholderTextColor={isDark ? '#B4A490' : '#5C4E40'}
          style={{ flex: 1, paddingVertical: 12, fontSize: 16, color: fg }}
          accessibilityLabel={accessibilityLabel ?? label}
        />
        <PressScale
          onPress={() => setPickerOpen(true)}
          accessibilityLabel={t('timeField.open_picker')}
          className="pl-2 py-2"
        >
          <Clock size={20} color={mutedFg} />
        </PressScale>
      </View>
      {pickerOpen ? (
        <DateTimePicker
          value={timeToDate(value)}
          mode="time"
          is24Hour
          onValueChange={(_, d) => {
            setPickerOpen(Platform.OS === 'ios');
            handlePicked(d);
          }}
          onDismiss={() => setPickerOpen(false)}
        />
      ) : null}
    </FormField>
  );
}
```

- [ ] **Step 2: Typecheck**

Run: `pnpm typecheck`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add src/ui/components/time-field.tsx
git commit -m "feat(date-fields): TimeField masked input with time picker"
```

---

## Task 5: Migrate `season.tsx`

**Files:**
- Modify: `app/(tabs)/settings/season.tsx`

- [ ] **Step 1: Replace imports**

Remove these imports:

```tsx
import { ScrollView, View, Platform } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { PressScale } from '@/ui/motion/press-scale';
```

Replace with:

```tsx
import { ScrollView, View } from 'react-native';
import { format, parseISO } from 'date-fns';
import { DateField } from '@/ui/components/date-field';
```

(`Text` and `Surface` stay imported; the help-text Surface still uses them.)

- [ ] **Step 2: Replace picker state with validity state**

Replace:

```tsx
  const [date, setDate] = useState<Date>(savedDate);
  const [showPicker, setShowPicker] = useState(false);
```

with:

```tsx
  const [date, setDate] = useState<Date>(savedDate);
  const [dateValid, setDateValid] = useState(true);
```

- [ ] **Step 3: Replace the date field JSX**

Replace the whole `<View className="gap-2"> … </View>` block containing the date `PressScale` + `DateTimePicker` (the block between the help-text Surface and the reset Button) with:

```tsx
        <DateField
          label={t('settings.season.date_label')}
          value={date}
          onChange={(d) => { if (d) setDate(d); }}
          onValidityChange={setDateValid}
        />
```

- [ ] **Step 4: Gate the Save button**

Replace:

```tsx
        <Button onPress={onSave} loading={setSettingMutation.isPending}>
          {t('common.save')}
        </Button>
```

with:

```tsx
        <Button onPress={onSave} loading={setSettingMutation.isPending} disabled={!dateValid}>
          {t('common.save')}
        </Button>
```

- [ ] **Step 5: Typecheck & lint**

Run: `pnpm typecheck && pnpm lint`
Expected: no errors, no unused-import warnings.

- [ ] **Step 6: Commit**

```bash
git add "app/(tabs)/settings/season.tsx"
git commit -m "refactor(season): use DateField for season start date"
```

---

## Task 6: Migrate `schedule-tour-sheet.tsx`

**Files:**
- Modify: `src/ui/components/schedule-tour-sheet.tsx`

- [ ] **Step 1: Replace imports**

Remove:

```tsx
import { Modal, Platform, TouchableOpacity, View } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
```

Replace with:

```tsx
import { Modal, TouchableOpacity, View } from 'react-native';
import { format } from 'date-fns';
import { DateField } from '@/ui/components/date-field';
import { TimeField } from '@/ui/components/time-field';
```

(`PressScale` import stays — still used by the close button.)

- [ ] **Step 2: Replace picker state with validity state**

Replace:

```tsx
  const [date, setDate] = useState<Date>(initialDate ?? new Date());
  const [time, setTime] = useState<string>(initialTime ?? '08:00');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);
```

with:

```tsx
  const [date, setDate] = useState<Date>(initialDate ?? new Date());
  const [time, setTime] = useState<string>(initialTime ?? '08:00');
  const [dateValid, setDateValid] = useState(true);
  const [timeValid, setTimeValid] = useState(true);
```

- [ ] **Step 3: Replace the date block**

Replace the `<View className="gap-2 mb-4">` block containing the date `PressScale` + `DateTimePicker` with:

```tsx
        <View className="mb-4">
          <DateField
            label={t('tours.scheduled_date')}
            value={date}
            onChange={(d) => { if (d) setDate(d); }}
            onValidityChange={setDateValid}
          />
        </View>
```

- [ ] **Step 4: Replace the time block**

Replace the `<View className="gap-2 mb-4">` block containing the time `PressScale` + `DateTimePicker` with:

```tsx
        <View className="mb-4">
          <TimeField
            label={t('tours.departure_time')}
            value={time}
            onChange={(v) => { if (v) setTime(v); }}
            onValidityChange={setTimeValid}
          />
        </View>
```

- [ ] **Step 5: Gate the Confirm button**

Replace:

```tsx
          <Button className="flex-1" onPress={confirm}>
            {t('tours.schedule_sheet_confirm')}
          </Button>
```

with:

```tsx
          <Button className="flex-1" onPress={confirm} disabled={!dateValid || !timeValid}>
            {t('tours.schedule_sheet_confirm')}
          </Button>
```

- [ ] **Step 6: Typecheck & lint**

Run: `pnpm typecheck && pnpm lint`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add src/ui/components/schedule-tour-sheet.tsx
git commit -m "refactor(schedule-sheet): use DateField/TimeField with validity gating"
```

---

## Task 7: Migrate `tour-draft-editor.tsx` (inline fields)

**Files:**
- Modify: `src/ui/components/tour-draft-editor.tsx`

Note: these inline fields only render for non-draft tours and feed `ScheduleTourSheet`'s initial values; no button gating is required (invalid input never updates `date`/`time`).

- [ ] **Step 1: Replace imports**

Remove:

```tsx
import { TextInput, View, Platform } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
```

Replace with:

```tsx
import { TextInput, View } from 'react-native';
import { parseISO } from 'date-fns';
import { DateField } from '@/ui/components/date-field';
import { TimeField } from '@/ui/components/time-field';
```

(`format` is no longer used in this file after this change; confirm via lint in Step 5. `parseISO` is still used for `initialDate`.)

- [ ] **Step 2: Remove the inline picker visibility state**

Remove:

```tsx
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);
```

- [ ] **Step 3: Replace the date + time blocks**

Replace the two `<View className="gap-2">` blocks (the scheduled-date `PressScale`+`DateTimePicker` and the departure-time `PressScale`+`DateTimePicker`, inside the `tourStatus !== 'draft'` fragment) with:

```tsx
          <DateField
            label={t('tours.scheduled_date')}
            value={date}
            onChange={setDate}
            required={false}
          />

          <TimeField
            label={t('tours.departure_time')}
            value={time}
            onChange={setTime}
            required={false}
          />
```

- [ ] **Step 4: Typecheck & lint**

Run: `pnpm typecheck && pnpm lint`
Expected: no errors. If lint flags `format` as unused, remove it from the `date-fns` import (leaving only `parseISO`).

- [ ] **Step 5: Commit**

```bash
git add src/ui/components/tour-draft-editor.tsx
git commit -m "refactor(tour-draft-editor): use DateField/TimeField for inline schedule"
```

---

## Task 8: Migrate `payment-editor.tsx` + gate its sheet hosts

**Files:**
- Modify: `src/ui/components/payment-editor.tsx`
- Modify: `src/ui/components/manual-entry-payment-sheet.tsx`
- Modify: `src/ui/components/stop-payment-sheet.tsx`

- [ ] **Step 1: Update `payment-editor.tsx` imports**

Remove:

```tsx
import { Platform, View } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
```

Replace with:

```tsx
import { View } from 'react-native';
import { parseISO } from 'date-fns';
import { DateField } from '@/ui/components/date-field';
```

- [ ] **Step 2: Add the validity prop**

Replace the `Props` interface:

```tsx
interface Props {
  value: Payment;
  onChange: (next: Payment) => void;
  methodError?: string | null;
  // When true, the form requires a methodId regardless of isPaid (manual history).
  requireMethodAlways?: boolean;
}
```

with:

```tsx
interface Props {
  value: Payment;
  onChange: (next: Payment) => void;
  methodError?: string | null;
  // When true, the form requires a methodId regardless of isPaid (manual history).
  requireMethodAlways?: boolean;
  /** Bubbles paid-at field validity so a host can disable its Save button. */
  onPaidAtValidityChange?: (valid: boolean) => void;
}
```

and the function signature:

```tsx
export function PaymentEditor({ value, onChange, methodError, requireMethodAlways }: Props) {
```

with:

```tsx
export function PaymentEditor({ value, onChange, methodError, requireMethodAlways, onPaidAtValidityChange }: Props) {
```

- [ ] **Step 3: Remove the date picker state**

Remove:

```tsx
  const [datePickerOpen, setDatePickerOpen] = useState(false);
```

- [ ] **Step 4: Replace the paidAt block**

Replace:

```tsx
      {value.isPaid ? (
        <View className="gap-2">
          <Text className="text-sm">{t('payments.paid_at')}</Text>
          <PressScale onPress={() => setDatePickerOpen(true)} accessibilityLabel={t('payments.paid_at')}>
            <Surface className="rounded-2xl px-4 py-3">
              <Text>{value.paidAt ? format(parseISO(value.paidAt), 'PPP', { locale: fr }) : '—'}</Text>
            </Surface>
          </PressScale>
          {datePickerOpen ? (
            <DateTimePicker
              value={value.paidAt ? parseISO(value.paidAt) : new Date()}
              mode="date"
              onChange={(_, d) => {
                setDatePickerOpen(Platform.OS === 'ios');
                if (d) onChange({ ...value, paidAt: d.toISOString() });
              }}
            />
          ) : null}
        </View>
      ) : null}
```

with:

```tsx
      {value.isPaid ? (
        <DateField
          label={t('payments.paid_at')}
          value={value.paidAt ? parseISO(value.paidAt) : null}
          onChange={(d) => onChange({ ...value, paidAt: d ? d.toISOString() : null })}
          onValidityChange={onPaidAtValidityChange}
        />
      ) : null}
```

Note: `View` is still used by the method picker rows above, so its import stays. `Text`, `Surface`, `PressScale` also remain used elsewhere in the component.

- [ ] **Step 5: Typecheck**

Run: `pnpm typecheck`
Expected: no errors.

- [ ] **Step 6: Gate `manual-entry-payment-sheet.tsx`**

Add a validity state. Replace:

```tsx
  const [error, setError] = useState<string | null>(null);
  const mark = useMarkManualEntryPayment();
```

with:

```tsx
  const [error, setError] = useState<string | null>(null);
  const [paidAtValid, setPaidAtValid] = useState(true);
  const mark = useMarkManualEntryPayment();
```

Replace:

```tsx
        <PaymentEditor value={draft} onChange={setDraft} methodError={error} />
        <Button className="mt-4" onPress={onSave} loading={mark.isPending}>
          {t('common.save')}
        </Button>
```

with:

```tsx
        <PaymentEditor value={draft} onChange={setDraft} methodError={error} onPaidAtValidityChange={setPaidAtValid} />
        <Button className="mt-4" onPress={onSave} loading={mark.isPending} disabled={!paidAtValid}>
          {t('common.save')}
        </Button>
```

- [ ] **Step 7: Gate `stop-payment-sheet.tsx`**

Replace:

```tsx
  const [error, setError] = useState<string | null>(null);
  const mark = useMarkStopPayment();
```

with:

```tsx
  const [error, setError] = useState<string | null>(null);
  const [paidAtValid, setPaidAtValid] = useState(true);
  const mark = useMarkStopPayment();
```

Replace:

```tsx
        <PaymentEditor value={draft} onChange={setDraft} methodError={error} />
        <Button className="mt-4" onPress={onSave} loading={mark.isPending}>
          {t('common.save')}
        </Button>
```

with:

```tsx
        <PaymentEditor value={draft} onChange={setDraft} methodError={error} onPaidAtValidityChange={setPaidAtValid} />
        <Button className="mt-4" onPress={onSave} loading={mark.isPending} disabled={!paidAtValid}>
          {t('common.save')}
        </Button>
```

- [ ] **Step 8: Typecheck & lint**

Run: `pnpm typecheck && pnpm lint`
Expected: no errors.

- [ ] **Step 9: Commit**

```bash
git add src/ui/components/payment-editor.tsx src/ui/components/manual-entry-payment-sheet.tsx src/ui/components/stop-payment-sheet.tsx
git commit -m "refactor(payment-editor): use DateField for paidAt, gate sheet hosts"
```

---

## Task 9: Migrate `manual-history-form.tsx`

**Files:**
- Modify: `src/ui/components/manual-history-form.tsx`

- [ ] **Step 1: Replace imports**

Remove:

```tsx
import { ScrollView, View, Platform } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
```

Replace with:

```tsx
import { ScrollView, View } from 'react-native';
import { format, parseISO } from 'date-fns';
import { DateField } from '@/ui/components/date-field';
```

(`Controller` import stays — still used for the date field plumbing. `PressScale` is no longer used; remove it from its import line. `FormField` and `Surface`/`Text` stay used elsewhere.)

- [ ] **Step 2: Replace picker state with validity state**

Replace:

```tsx
  const [showDatePicker, setShowDatePicker] = useState(false);
```

with:

```tsx
  const [dateValid, setDateValid] = useState(true);
  const [paidAtValid, setPaidAtValid] = useState(true);
```

- [ ] **Step 3: Replace the date `Controller` body**

Replace:

```tsx
      <Controller
        control={control}
        name="date"
        render={({ field, fieldState }) => (
          <FormField label={t('history.manual.date')} error={fieldState.error?.message}>
            <PressScale onPress={() => setShowDatePicker(true)} accessibilityLabel={t('history.manual.date')}>
              <Surface variant="muted" className="rounded-2xl px-4 py-3">
                <Text>{format(field.value, 'PPP', { locale: fr })}</Text>
              </Surface>
            </PressScale>
            {showDatePicker && (
              <DateTimePicker
                value={field.value}
                mode="date"
                onChange={(_, d) => {
                  setShowDatePicker(Platform.OS === 'ios');
                  if (d) field.onChange(d);
                }}
              />
            )}
          </FormField>
        )}
      />
```

with:

```tsx
      <Controller
        control={control}
        name="date"
        render={({ field }) => (
          <DateField
            label={t('history.manual.date')}
            value={field.value}
            onChange={(d) => { if (d) field.onChange(d); }}
            onValidityChange={setDateValid}
          />
        )}
      />
```

- [ ] **Step 4: Pass validity from PaymentEditor**

Replace:

```tsx
      <PaymentEditor
        value={payment}
        onChange={setPayment}
        methodError={methodError}
        requireMethodAlways
      />
```

with:

```tsx
      <PaymentEditor
        value={payment}
        onChange={setPayment}
        methodError={methodError}
        requireMethodAlways
        onPaidAtValidityChange={setPaidAtValid}
      />
```

- [ ] **Step 5: Gate both Save buttons**

Replace:

```tsx
        <Button className="flex-1" onPress={submit(false)} loading={saving}>
          {t('common.save')}
        </Button>
```

with:

```tsx
        <Button className="flex-1" onPress={submit(false)} loading={saving} disabled={!dateValid || !paidAtValid}>
          {t('common.save')}
        </Button>
```

and replace:

```tsx
        <Button variant="secondary" onPress={submit(true)} disabled={saving}>
          {t('history.manual.save_and_add_another')}
        </Button>
```

with:

```tsx
        <Button variant="secondary" onPress={submit(true)} disabled={saving || !dateValid || !paidAtValid}>
          {t('history.manual.save_and_add_another')}
        </Button>
```

- [ ] **Step 6: Typecheck & lint**

Run: `pnpm typecheck && pnpm lint`
Expected: no errors. If lint flags `Surface`/`Text` as unused, remove them from imports (verify they aren't used elsewhere in the file first — they are, in the services summary block, so they should stay).

- [ ] **Step 7: Commit**

```bash
git add src/ui/components/manual-history-form.tsx
git commit -m "refactor(manual-history-form): use DateField, gate Save on validity"
```

---

## Task 10: Final verification

**Files:** none (verification only)

- [ ] **Step 1: No leftover deprecated picker usage**

Run: `pnpm exec grep -rn "onChange=" src/ui/components/date-field.tsx src/ui/components/time-field.tsx` (PowerShell: `Select-String`)
Expected: no matches (both use `onValueChange`).

Run a repo-wide check that no `DateTimePicker` is wired with the deprecated `onChange` anymore:
Use Grep tool: pattern `mode="(date|time)"` across `src/` and `app/` — expected matches only inside `date-field.tsx` and `time-field.tsx`.

- [ ] **Step 2: Full typecheck, lint, tests**

Run: `pnpm typecheck && pnpm lint && pnpm test`
Expected: typecheck clean, lint exit 0, all tests pass (including the new `parse-date-input.test.ts`).

- [ ] **Step 3: Manual smoke (dev client)**

Boot the dev client and verify on at least: season screen, schedule-tour sheet, a manual history entry. For each: type a date by hand (e.g. `05/05/2026`), confirm it commits; type garbage (`32/13/2026`), confirm inline error appears and Save is disabled; open the picker via the icon, confirm selecting a date fills the field. Confirm no `onChange is deprecated` warning appears in the Metro logs.

- [ ] **Step 4: Final commit (if any verification fixups were needed)**

```bash
git add -A
git commit -m "chore(date-fields): verification fixups"
```

---

## Self-Review

**Spec coverage:**
- Masked editable date/time field + picker button → Tasks 3, 4. ✓
- All 7 sites migrated → Tasks 5 (season), 6 (schedule-sheet date+time), 7 (tour-draft date+time), 8 (payment-editor paidAt), 9 (manual-history date). ✓
- Invalid input → inline error + blocks save → DateField/TimeField error + `onValidityChange` gating in standalone hosts (Tasks 5, 6, 8, 9); scope note documents the multi-stop `complete.tsx` exception. ✓
- Pure logic tested in vitest → Task 2. ✓
- i18n `dateField`/`timeField` keys, no FR in JSX → Task 1. ✓
- Deprecation warning fixed (onValueChange/onDismiss, centralized) → Tasks 3, 4 + verification Task 10. ✓
- RGPD: no impact (UI-only) → no task needed. ✓

**Type consistency:** `parseDateInput`/`parseTimeInput` result shapes match between Task 2 (definition) and Tasks 3/4 (consumption). `DateField` value is `Date | null`, `TimeField` value is `string | null` — consistent across all host wirings. `onPaidAtValidityChange` defined in Task 8 and consumed in Tasks 8 (sheets) and 9 (manual-history-form).

**Placeholder scan:** none.

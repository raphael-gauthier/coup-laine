import type { TextInputProps } from 'react-native';
import {
  Controller,
  type Control,
  type FieldPath,
  type FieldValues,
} from 'react-hook-form';
import { Input } from '@/ui/primitives/input';
import { FormField } from '@/ui/components/form-field';

interface Props<T extends FieldValues> extends Omit<TextInputProps, 'value' | 'onChangeText' | 'onBlur' | 'accessibilityLabel'> {
  control: Control<T>;
  name: FieldPath<T>;
  label: string;
  /**
   * Optional override for the accessibility label. Defaults to `label`.
   */
  accessibilityLabel?: string;
  /**
   * Optional muted helper text rendered between the input and the error.
   */
  hint?: string;
}

/**
 * RHF-bound text input with FormField wrapping. Use for any single-line or
 * multi-line string field. For non-string fields (date pickers, switches,
 * pickers), drop down to `<Controller>` + `<FormField>` directly.
 */
export function RHFTextField<T extends FieldValues>({
  control,
  name,
  label,
  accessibilityLabel,
  hint,
  ...inputProps
}: Props<T>) {
  return (
    <Controller
      control={control}
      name={name}
      render={({ field, fieldState }) => (
        <FormField label={label} error={fieldState.error?.message} hint={hint}>
          <Input
            value={(field.value ?? '') as string}
            onChangeText={field.onChange}
            onBlur={field.onBlur}
            accessibilityLabel={accessibilityLabel ?? label}
            {...inputProps}
          />
        </FormField>
      )}
    />
  );
}

import React from 'react';
import { View, Text, TextInput, StyleSheet, useColorScheme } from 'react-native';
import { colors, fontSizes } from '../theme.js';
import Icon from 'react-native-vector-icons/Ionicons';

export default function InputView({
  label,
  value,
  onChangeText,
  placeholder,
  secureTextEntry = false,
  keyboardType = 'default',
  autoCapitalize = 'none',
  validationIcon, // 'checkmark-circle' | 'close-circle' | null
  validationColor, // color for icon
  style,
  ...props
}) {
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';
  return (
    <View style={[styles.container, style]}>
      <Text style={[
        styles.label,
        { color: isDark ? '#fff' : colors.gray },
      ]}>
        {label}
      </Text>
      <View style={{ flexDirection: 'row', alignItems: 'center' }}>
        <TextInput
          style={[
            styles.input,
            { color: isDark ? '#fff' : colors.text },
          ]}
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={colors.gray}
          secureTextEntry={secureTextEntry}
          keyboardType={keyboardType}
          autoCapitalize={autoCapitalize}
          {...props}
        />
        {validationIcon ? (
          <Icon
            name={validationIcon}
            size={22}
            color={validationColor || colors.gray}
            style={{ marginLeft: 8 }}
          />
        ) : null}
      </View>
      <View style={styles.divider} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: 16,
  },
  label: {
    fontWeight: '600',
    fontSize: fontSizes.footnote,
    marginBottom: 2,
  },
  input: {
    flex: 1,
    fontSize: 16,
    paddingVertical: 12,
    paddingHorizontal: 0,
    height: 48,
  },
  divider: {
    height: 2,
    backgroundColor: colors.divider,
    marginTop: 2,
    borderRadius: 1,
  },
}); 
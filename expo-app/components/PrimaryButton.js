import React from "react";
import { TouchableOpacity, Text, StyleSheet, View } from "react-native";
import { colors } from "../theme.js";

export default function PrimaryButton({
  title,
  onPress,
  disabled,
  icon,
  iconPosition = "left",
  style,
  textColor,
}) {
  return (
    <TouchableOpacity
      style={[styles.button, { opacity: disabled ? 0.5 : 1 }, style]}
      onPress={onPress}
      disabled={disabled}
      activeOpacity={0.8}
    >
      <View style={styles.contentRow}>
        {icon && iconPosition === "left" ? icon : null}
        <Text style={[styles.text, { color: textColor || "#fff" }]}>
          {title}
        </Text>
        {icon && iconPosition === "right" ? icon : null}
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    backgroundColor: colors.primary,
    height: 48,
    borderRadius: 10,
    alignItems: "center",
    justifyContent: "center",
    flexDirection: "row",
    width: "100%",
    marginVertical: 8,
  },
  contentRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
  },
  text: {
    fontWeight: "600",
    fontSize: 16,
    marginHorizontal: 8,
  },
});

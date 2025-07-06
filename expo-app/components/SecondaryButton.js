import React from "react";
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  useColorScheme,
} from "react-native";
import { colors } from "../theme.js";

export default function SecondaryButton({ text, actionText, onPress, style }) {
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";
  return (
    <TouchableOpacity onPress={onPress} style={[styles.container, style]}>
      <Text style={[styles.text, { color: isDark ? "#fff" : colors.text }]}>
        {text}{" "}
        <Text style={[styles.action, { color: colors.primary }]}>
          {actionText}
        </Text>
      </Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    alignSelf: "center",
    marginVertical: 8,
  },
  text: {
    fontSize: 14,
  },
  action: {
    fontWeight: "bold",
  },
});

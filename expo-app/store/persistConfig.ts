import AsyncStorage from "@react-native-async-storage/async-storage";
import { StateStorage } from "zustand/middleware";

export const zustandAsyncStorage: StateStorage = {
  getItem: async (name) => {
    const value = await AsyncStorage.getItem(name);
    return value ?? null;
  },
  setItem: async (name, value) => {
    // Always store as a string!
    await AsyncStorage.setItem(
      name,
      typeof value === "string" ? value : JSON.stringify(value),
    );
  },
  removeItem: async (name) => {
    await AsyncStorage.removeItem(name);
  },
};

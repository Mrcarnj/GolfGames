import { create } from "zustand";
import AsyncStorage from "@react-native-async-storage/async-storage";

interface FavoritesState {
  favoriteCourseIds: string[];
  addFavorite: (id: string) => void;
  removeFavorite: (id: string) => void;
  isFavorite: (id: string) => boolean;
}

export const useFavoritesStore = create<FavoritesState>((set, get) => ({
  favoriteCourseIds: [],
  addFavorite: (id) => {
    const updated = Array.from(new Set([...get().favoriteCourseIds, id]));
    set({ favoriteCourseIds: updated });
    AsyncStorage.setItem("favoriteCourseIds", JSON.stringify(updated));
  },
  removeFavorite: (id) => {
    const updated = get().favoriteCourseIds.filter((cid) => cid !== id);
    set({ favoriteCourseIds: updated });
    AsyncStorage.setItem("favoriteCourseIds", JSON.stringify(updated));
  },
  isFavorite: (id) => get().favoriteCourseIds.includes(id),
}));

// Load favorites from AsyncStorage on app start
AsyncStorage.getItem("favoriteCourseIds").then((data) => {
  if (data) {
    useFavoritesStore.setState({ favoriteCourseIds: JSON.parse(data) });
  }
}); 
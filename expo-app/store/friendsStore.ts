import { create } from "zustand";
import { persist } from "zustand/middleware";
import { zustandAsyncStorage } from "./persistConfig";

interface FriendsState {
  friends: any[];
  userId: string | null;
  setFriends: (friends: any[]) => void;
  setUserId: (id: string | null) => void;
}

export const useFriendsStore = create<FriendsState>()(
  persist(
    (set) => ({
      friends: [],
      userId: null,
      setFriends: (friends) => set({ friends }),
      setUserId: (id) => set({ userId: id }),
    }),
    {
      name: "friends-store",
      storage: zustandAsyncStorage,
      partialize: (state) => ({ friends: state.friends, userId: state.userId }),
    },
  ),
);

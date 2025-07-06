import { useAuthStore } from "./authStore";
import { useRoundStore } from "./roundStore";
import { useSharedStore } from "./sharedStore";
import { useFriendsStore } from "./friendsStore";
import { useLocationStore } from "./locationStore";
import { useMemo } from "react";

export function useCurrentUser() {
  return useAuthStore((state) => state.userSession);
}

export function useCurrentRound() {
  return useRoundStore((state) => ({
    selectedTee: state.selectedTee,
    selectedCourse: state.selectedCourse,
    currentHole: state.currentHole,
    roundType: state.roundType,
  }));
}

export function useFriendsList() {
  return useFriendsStore((state) => state.friends);
}

export function useLocationStatus() {
  return useLocationStore((state) => state.locationStatus);
}

export function useGolfers() {
  return useSharedStore((state) => state.golfers);
}

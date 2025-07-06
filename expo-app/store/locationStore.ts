import { create } from "zustand";
import { persist } from "zustand/middleware";
import { zustandAsyncStorage } from "./persistConfig";

interface LocationState {
  locationStatus: string | null;
  lastLocation: { latitude: number; longitude: number } | null;
  isLocationAvailable: boolean;
  setLocationStatus: (status: string | null) => void;
  setLastLocation: (location: { latitude: number; longitude: number } | null) => void;
  setIsLocationAvailable: (available: boolean) => void;
}

export const useLocationStore = create<LocationState>()(
  persist(
    (set, get) => ({
      locationStatus: null,
      lastLocation: null,
      isLocationAvailable: false,
      setLocationStatus: (status) => set({ locationStatus: status }),
      setLastLocation: (location) => set({ lastLocation: location }),
      setIsLocationAvailable: (available) => set({ isLocationAvailable: available }),
    }),
    {
      name: "location-store",
      storage: zustandAsyncStorage,
      partialize: (state) => ({
        locationStatus: state.locationStatus,
        lastLocation: state.lastLocation,
        isLocationAvailable: state.isLocationAvailable,
      }),
    },
  ),
);

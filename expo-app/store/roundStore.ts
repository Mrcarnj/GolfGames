import { create } from "zustand";
import { Golfer } from "../types/Golfer";

interface RoundState {
  golfers: Golfer[];
  setGolfers: (golfers: Golfer[]) => void;
  // Add more round state as needed (course, tee, etc.)
}

export const useRoundStore = create<RoundState>((set) => ({
  golfers: [],
  setGolfers: (golfers) => set({ golfers }),
}));

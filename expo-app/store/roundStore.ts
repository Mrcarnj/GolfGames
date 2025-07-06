import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { zustandAsyncStorage } from './persistConfig';

interface RoundState {
  selectedTee: string | null;
  selectedCourse: string | null;
  grossScores: Record<number, Record<string, number>>;
  netStrokePlayScores: Record<number, Record<string, number>>;
  pars: Record<number, number>;
  courseHandicaps: Record<string, number>;
  golfers: any[];
  currentHole: number;
  roundType: string;
  setSelectedTee: (tee: string | null) => void;
  setSelectedCourse: (course: string | null) => void;
  setGrossScores: (scores: Record<number, Record<string, number>>) => void;
  setNetStrokePlayScores: (scores: Record<number, Record<string, number>>) => void;
  setPars: (pars: Record<number, number>) => void;
  setCourseHandicaps: (handicaps: Record<string, number>) => void;
  setGolfers: (golfers: any[]) => void;
  setCurrentHole: (hole: number) => void;
  setRoundType: (type: string) => void;
}

export const useRoundStore = create<RoundState>()(
  persist(
    (set) => ({
      selectedTee: null,
      selectedCourse: null,
      grossScores: {},
      netStrokePlayScores: {},
      pars: {},
      courseHandicaps: {},
      golfers: [],
      currentHole: 1,
      roundType: 'full18',
      setSelectedTee: (tee) => set({ selectedTee: tee }),
      setSelectedCourse: (course) => set({ selectedCourse: course }),
      setGrossScores: (scores) => set({ grossScores: scores }),
      setNetStrokePlayScores: (scores) => set({ netStrokePlayScores: scores }),
      setPars: (pars) => set({ pars }),
      setCourseHandicaps: (handicaps) => set({ courseHandicaps: handicaps }),
      setGolfers: (golfers) => set({ golfers }),
      setCurrentHole: (hole) => set({ currentHole: hole }),
      setRoundType: (type) => set({ roundType: type }),
    }),
    {
      name: 'round-store',
      storage: zustandAsyncStorage,
      partialize: (state) => ({ selectedTee: state.selectedTee, selectedCourse: state.selectedCourse, grossScores: state.grossScores, netStrokePlayScores: state.netStrokePlayScores, pars: state.pars, courseHandicaps: state.courseHandicaps, golfers: state.golfers, currentHole: state.currentHole, roundType: state.roundType }),
    }
  )
); 
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { zustandAsyncStorage } from './persistConfig';

interface SharedState {
  golfers: any[];
  selectedTees: Record<string, string | null>;
  courseHandicaps: Record<string, number>;
  selectedCourse: string | null;
  roundId: string | null;
  setGolfers: (golfers: any[]) => void;
  setSelectedTees: (tees: Record<string, string | null>) => void;
  setCourseHandicaps: (handicaps: Record<string, number>) => void;
  setSelectedCourse: (course: string | null) => void;
  setRoundId: (id: string | null) => void;
}

export const useSharedStore = create<SharedState>()(
  persist(
    (set) => ({
      golfers: [],
      selectedTees: {},
      courseHandicaps: {},
      selectedCourse: null,
      roundId: null,
      setGolfers: (golfers) => set({ golfers }),
      setSelectedTees: (tees) => set({ selectedTees: tees }),
      setCourseHandicaps: (handicaps) => set({ courseHandicaps: handicaps }),
      setSelectedCourse: (course) => set({ selectedCourse: course }),
      setRoundId: (id) => set({ roundId: id }),
    }),
    {
      name: 'shared-store',
      storage: zustandAsyncStorage,
      partialize: (state) => ({ golfers: state.golfers, selectedTees: state.selectedTees, courseHandicaps: state.courseHandicaps, selectedCourse: state.selectedCourse, roundId: state.roundId }),
    }
  )
); 
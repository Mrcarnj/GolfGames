import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { zustandAsyncStorage } from './persistConfig';

export interface SharedState {
  golfers: any[];
  selectedTees: Record<string, any>;
  courseHandicaps: Record<string, any>;
  selectedCourse: any;
  roundId: string | null;
  recentCourseSearches: string[];
  setGolfers: (golfers: any[]) => void;
  setSelectedTees: (tees: Record<string, any>) => void;
  setCourseHandicaps: (handicaps: Record<string, any>) => void;
  setSelectedCourse: (course: any) => void;
  setRoundId: (id: string | null) => void;
  setRecentCourseSearch: (term: string) => void;
}

export const useSharedStore = create<SharedState>()(
  persist(
    (set) => ({
      golfers: [],
      selectedTees: {},
      courseHandicaps: {},
      selectedCourse: null,
      roundId: null,
      recentCourseSearches: [],
      setGolfers: (golfers) => set({ golfers }),
      setSelectedTees: (tees) => set({ selectedTees: tees }),
      setCourseHandicaps: (handicaps) => set({ courseHandicaps: handicaps }),
      setSelectedCourse: (course) => set({ selectedCourse: course }),
      setRoundId: (id) => set({ roundId: id }),
      setRecentCourseSearch: (term) => set((state) => {
        if (!term.trim()) return {};
        const filtered = state.recentCourseSearches.filter(t => t.toLowerCase() !== term.trim().toLowerCase());
        const updated = [term.trim(), ...filtered].slice(0, 5);
        return { recentCourseSearches: updated };
      }),
    }),
    {
      name: 'shared-store',
      storage: zustandAsyncStorage,
      partialize: (state) => ({ golfers: state.golfers, selectedTees: state.selectedTees, courseHandicaps: state.courseHandicaps, selectedCourse: state.selectedCourse, roundId: state.roundId, recentCourseSearches: state.recentCourseSearches }),
    }
  )
); 
import { create } from "zustand";
import { persist } from "zustand/middleware";
import { zustandAsyncStorage } from "./persistConfig";

export interface Favorite {
  courseId: string;
  courseName: string;
  teeId: string;
  teeName: string;
}
export interface SharedState {
  golfers: any[];
  selectedTees: Record<string, any>;
  courseHandicaps: Record<string, any>;
  selectedCourse: any;
  roundId: string | null;
  recentCourseSearches: string[];
  favorites: Favorite[];
  setGolfers: (golfers: any[]) => void;
  setSelectedTees: (tees: Record<string, any>) => void;
  setCourseHandicaps: (handicaps: Record<string, any>) => void;
  setSelectedCourse: (course: any) => void;
  setRoundId: (id: string | null) => void;
  setRecentCourseSearch: (term: string) => void;
  addFavorite: (
    courseId: string,
    courseName: string,
    teeId: string,
    teeName: string,
  ) => void;
  removeFavorite: (courseId: string, teeId: string) => void;
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
      favorites: [],
      setGolfers: (golfers) => set({ golfers }),
      setSelectedTees: (tees) => set({ selectedTees: tees }),
      setCourseHandicaps: (handicaps) => set({ courseHandicaps: handicaps }),
      setSelectedCourse: (course) => set({ selectedCourse: course }),
      setRoundId: (id) => set({ roundId: id }),
      setRecentCourseSearch: (term) =>
        set((state) => {
          if (!term.trim()) return {};
          const filtered = state.recentCourseSearches.filter(
            (t) => t.toLowerCase() !== term.trim().toLowerCase(),
          );
          const updated = [term.trim(), ...filtered].slice(0, 5);
          return { recentCourseSearches: updated };
        }),
      addFavorite: (courseId, courseName, teeId, teeName) =>
        set((state) => {
          const exists = state.favorites.some(
            (f) => f.courseId === courseId && f.teeId === teeId,
          );
          if (exists) return {};
          return {
            favorites: [
              { courseId, courseName, teeId, teeName },
              ...state.favorites,
            ],
          };
        }),
      removeFavorite: (courseId, teeId) =>
        set((state) => ({
          favorites: state.favorites.filter(
            (f) => !(f.courseId === courseId && f.teeId === teeId),
          ),
        })),
    }),
    {
      name: "shared-store",
      storage: zustandAsyncStorage,
      partialize: (state) => ({
        golfers: state.golfers,
        selectedTees: state.selectedTees,
        courseHandicaps: state.courseHandicaps,
        selectedCourse: state.selectedCourse,
        roundId: state.roundId,
        recentCourseSearches: state.recentCourseSearches,
        favorites: state.favorites,
      }),
    },
  ),
);

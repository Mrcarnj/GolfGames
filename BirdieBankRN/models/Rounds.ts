import type { Golfer } from './Golfer';
import type { GameTypesState } from './gameTypes';
import type { Tee } from './Tee';
import type { Course } from './Course';
import type { Hole } from './Hole';

export type RoundType = 'full18' | 'front9' | 'back9';

/**
 * Represents a score for a golfer on a specific hole.
 */
export interface Score {
  id?: string;
  golferId: string;
  holeNumber: number;
  score: number;
}

/**
 * Represents the main round structure.
 */
export interface RoundModel {
  id?: string;
  courseId: string;
  courseName: string;
  teeName: string;
  golfers: Golfer[];
  date: string; // ISO string
  roundType: RoundType;
  birdies?: Record<string, number>;
  eagles?: Record<string, number>;
  pars?: Record<string, number>;
  bogeys?: Record<string, number>;
  doubleBogeyPlus?: Record<string, number>;
}

/**
 * Represents the result of a golf round for a user.
 */
export interface RoundResult {
  id: string;
  course: string;
  date: string; // ISO string for date
  totalScore: number;
  tees: string;
  courseRating: number;
  slopeRating: number;
  scoreDifferential: number;
}

/**
 * Represents the state for recent rounds (for use with React state or context).
 */
export interface RecentRoundsState {
  recentRounds: RoundResult[];
}

/**
 * Shared view model state for global/shared app state.
 */
export interface SharedViewModelState {
  golfers: Golfer[];
  selectedTees: Record<string, Tee | undefined>;
  courseHandicaps: Record<string, number>;
  selectedCourse?: Course;
  roundId?: string;
  currentUserGolfer?: Golfer;
  golferTeeSelections: Record<string, string>; // [GolferID: TeeID]
  isMatchPlay: boolean;
  holes: Record<string, Hole[]>;
  matchPlayHandicap: number;
}

/**
 * State shape for a round view model.
 */
export interface RoundViewModelState extends GameTypesState {
  selectedTee?: Tee;
  selectedCourse?: Course;
  selectedLocation?: string;
  grossScores: Record<number, Record<string, number>>;
  netStrokePlayScores: Record<number, Record<string, number>>;
  pars: Record<number, number>;
  courseHandicaps: Record<string, number>;
  strokeHoles: Record<string, number[]>;
  roundId?: string;
  recentRounds: any[]; // Use Round[] if you define it
  golfers: Golfer[];
  currentHole: number;
  holes: Record<string, Hole[]>;
  roundType: RoundType;
  startingHole: number;
} 
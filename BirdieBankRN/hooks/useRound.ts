// useRound.ts
// React hook for managing round data, mimicking Swift RoundViewModel and SharedViewModel

import { useState, useCallback } from 'react';
import type { RoundViewModelState, SharedViewModelState, RoundType } from '../models/Rounds';
import type { ScorecardType } from '../models/gameTypes';
import type { Golfer } from '../models/Golfer';
import type { Tee } from '../models/Tee';
import type { Course } from '../models/Course';
import type { Hole } from '../models/Hole';
import type { User } from '../models/User';

// Placeholder for Firestore/database logic
// import { firestore } from '../firebase';

/**
 * React hook for managing round data and state, similar to Swift RoundViewModel and SharedViewModel.
 */
export function useRound(initialGolfers: Golfer[] = [], initialCourse?: Course, initialTee?: Tee) {
  // --- State ---
  const [selectedTee, setSelectedTee] = useState<Tee | undefined>(initialTee);
  const [selectedCourse, setSelectedCourse] = useState<Course | undefined>(initialCourse);
  const [selectedLocation, setSelectedLocation] = useState<string | undefined>(undefined);
  const [golfers, setGolfers] = useState<Golfer[]>(initialGolfers);
  const [currentUserGolfer, setCurrentUserGolfer] = useState<Golfer | undefined>(undefined);
  const [currentHole, setCurrentHole] = useState<number>(1);
  const [roundType, setRoundType] = useState<RoundType>('full18');
  const [grossScores, setGrossScores] = useState<Record<number, Record<string, number>>>({});
  const [netStrokePlayScores, setNetStrokePlayScores] = useState<Record<number, Record<string, number>>>({});
  const [pars, setPars] = useState<Record<number, number>>({});
  const [courseHandicaps, setCourseHandicaps] = useState<Record<string, number>>({});
  const [strokeHoles, setStrokeHoles] = useState<Record<string, number[]>>({});
  const [holes, setHoles] = useState<Record<string, Hole[]>>({});
  const [selectedTees, setSelectedTees] = useState<Record<string, Tee | undefined>>({});
  const [roundId, setRoundId] = useState<string | undefined>(undefined);
  const [golferTeeSelections, setGolferTeeSelections] = useState<Record<string, string>>({});
  const [isMatchPlay, setIsMatchPlay] = useState<boolean>(false);
  const [matchPlayHandicap, setMatchPlayHandicap] = useState<number>(0);

  // --- Methods ---
  /**
   * Adds a golfer if not already present, and sets as current user if none.
   */
  const addGolfer = useCallback((golfer: Golfer) => {
    setGolfers(prev => {
      if (prev.some(g => g.id === golfer.id)) return prev;
      if (!currentUserGolfer) setCurrentUserGolfer(golfer);
      return [...prev, golfer];
    });
  }, [currentUserGolfer]);

  /**
   * Removes a golfer by ID.
   */
  const removeGolfer = useCallback((golferId: string) => {
    setGolfers(prev => prev.filter(g => g.id !== golferId));
  }, []);

  /**
   * Resets all round-related state for a new round.
   */
  const resetForNewRound = useCallback(() => {
    setGolfers([]);
    setSelectedTees({});
    setCourseHandicaps({});
    setSelectedCourse(undefined);
    setRoundId(undefined);
    setGolferTeeSelections({});
    setIsMatchPlay(false);
    setHoles({});
    setMatchPlayHandicap(0);
    setCurrentUserGolfer(undefined);
    setCurrentHole(1);
    setGrossScores({});
    setNetStrokePlayScores({});
    setPars({});
    setStrokeHoles({});
    // Reset other round state as needed
  }, []);

  /**
   * Sets match play mode for a new round.
   */
  const createNewRound = useCallback((isMatch: boolean) => {
    setIsMatchPlay(isMatch);
  }, []);

  /**
   * Updates the holes mapping.
   */
  const updateHoles = useCallback((newHoles: Record<string, Hole[]>) => {
    setHoles(newHoles);
  }, []);

  /**
   * Returns a formatted name for a golfer, disambiguating by last initial if needed.
   */
  const formattedGolferName = useCallback(
    (golfer: Golfer) => {
      const sameFirstName = golfers.filter(g => g.firstName === golfer.firstName);
      if (sameFirstName.length > 1) {
        return `${golfer.firstName} ${golfer.lastName.charAt(0)}.`;
      } else {
        return golfer.firstName;
      }
    },
    [golfers]
  );

  /**
   * Returns formatted names for all golfers.
   */
  const formattedGolferNames = useCallback(() => {
    return golfers.map(formattedGolferName);
  }, [golfers, formattedGolferName]);

  /**
   * Set score for a golfer on a hole.
   */
  const setScore = useCallback((hole: number, golferId: string, score: number) => {
    setGrossScores(prev => ({
      ...prev,
      [hole]: {
        ...(prev[hole] || {}),
        [golferId]: score,
      },
    }));
  }, []);

  /**
   * Initializes a new round with the given user and additional golfers.
   * Placeholder for Firestore/database logic.
   */
  const beginRound = useCallback(
    (user: User, additionalGolfers: Golfer[], isMatchPlay: boolean, completion: (roundId?: string, error?: Error, additionalInfo?: any) => void) => {
      setGolfers([{
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        handicap: user.handicap ?? 0,
        isChecked: false,
      } as Golfer, ...additionalGolfers]);
      completion('mock-round-id', undefined, { courseId: selectedCourse?.id, teeId: selectedTee?.id });
    },
    [selectedCourse, selectedTee]
  );

  /**
   * Fetches pars and handicaps for a course/tee. Placeholder for Firestore/database logic.
   */
  const fetchPars = useCallback(
    async (courseId: string, teeId: string, user: User, completion: (pars: Record<number, number>) => void) => {
      const mockPars = { 1: 4, 2: 4, 3: 3, 4: 5, 5: 4, 6: 4, 7: 3, 8: 5, 9: 4 };
      setPars(mockPars);
      completion(mockPars);
    },
    []
  );

  /**
   * Fetches recent rounds for a user. Placeholder for Firestore/database logic.
   */
  const fetchRecentRounds = useCallback(
    async (user: User) => {
      // TODO: Replace with Firestore/database logic
    },
    []
  );

  /**
   * Gets the handicap for a specific hole and tee.
   */
  const getHoleHandicap = useCallback(
    (hole: number, teeId: string) => {
      const holesForTee = holes[teeId] || [];
      const found = holesForTee.find(h => h.holeNumber === hole);
      return found ? found.handicap : 0;
    },
    [holes]
  );

  /**
   * Calculates stroke play stroke holes for each golfer. Mimics Swift logic.
   */
  const calculateStrokePlayStrokeHoles = useCallback(
    (holesList: Hole[]) => {
      // TODO: Implement logic for calculating stroke holes
    },
    []
  );

  // --- Return ---
  return {
    // State
    selectedTee, setSelectedTee,
    selectedCourse, setSelectedCourse,
    selectedLocation, setSelectedLocation,
    golfers, setGolfers,
    currentUserGolfer, setCurrentUserGolfer,
    currentHole, setCurrentHole,
    roundType, setRoundType,
    grossScores, setGrossScores,
    netStrokePlayScores, setNetStrokePlayScores,
    pars, setPars,
    courseHandicaps, setCourseHandicaps,
    strokeHoles, setStrokeHoles,
    holes, setHoles,
    selectedTees, setSelectedTees,
    roundId, setRoundId,
    golferTeeSelections, setGolferTeeSelections,
    isMatchPlay, setIsMatchPlay,
    matchPlayHandicap, setMatchPlayHandicap,
    // Methods
    addGolfer,
    removeGolfer,
    resetForNewRound,
    createNewRound,
    updateHoles,
    formattedGolferName,
    formattedGolferNames,
    setScore,
    beginRound,
    fetchPars,
    fetchRecentRounds,
    getHoleHandicap,
    calculateStrokePlayStrokeHoles,
  };
} 
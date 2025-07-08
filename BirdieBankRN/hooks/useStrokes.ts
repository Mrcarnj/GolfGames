import { useCallback } from 'react';
import { determineStrokePlayStrokeHoles } from '@/utilities/HandicapCalculator';
import { getHoleHandicap } from '@/utilities/StrokesModel';
import type { Golfer } from '@/models/Golfer';
import type { Hole } from '@/models/Hole';

/**
 * Custom hook for stroke calculations and assignments for a round.
 * Encapsulates logic for stroke play, match play, better ball, etc.
 */
export function useStrokes(
  golfers: Golfer[],
  courseHandicaps: Record<string, number>,
  holes: Hole[]
) {
  /**
   * Calculates stroke play stroke holes for all golfers.
   * @returns Record mapping golferId to array of stroke hole numbers
   */
  const calculateStrokePlayStrokeHoles = useCallback((): Record<string, number[]> => {
    const strokeHoles: Record<string, number[]> = {};
    golfers.forEach(golfer => {
      const courseHandicap = courseHandicaps[golfer.id] ?? 0;
      strokeHoles[golfer.id] = determineStrokePlayStrokeHoles(courseHandicap, holes);
    });
    return strokeHoles;
  }, [golfers, courseHandicaps, holes]);

  /**
   * Returns the handicap for a given hole number.
   */
  const getHandicapForHole = useCallback((holeNumber: number): number => {
    return getHoleHandicap(holes, holeNumber);
  }, [holes]);

  // --- Placeholders for advanced game-type logic ---

  /**
   * Calculates match play stroke holes for all golfers (to be implemented).
   */
  const calculateMatchPlayStrokeHoles = useCallback(() => {
    // TODO: Implement match play stroke hole logic
  }, [golfers, courseHandicaps, holes]);

  /**
   * Calculates better ball stroke holes for all golfers (to be implemented).
   */
  const calculateBetterBallStrokeHoles = useCallback(() => {
    // TODO: Implement better ball stroke hole logic
  }, [golfers, courseHandicaps, holes]);

  return {
    calculateStrokePlayStrokeHoles,
    getHandicapForHole,
    calculateMatchPlayStrokeHoles,
    calculateBetterBallStrokeHoles,
    // Add more as needed
  };
} 
// StrokePlay.ts
// TypeScript interface and utilities for tracking stroke play scores in a round

import type { Golfer } from '../Golfer';
import type { Hole } from '../Hole';

/**
 * Represents per-hole gross and net scores for a golfer.
 */
export interface StrokePlayScores {
  /** Gross scores by hole number */
  grossScores: Record<number, number>;
  /** Net scores by hole number */
  netScores: Record<number, number>;
}

/**
 * Represents the stroke play state for a round.
 */
export interface StrokePlayRound {
  /** All golfers in the round */
  golfers: Golfer[];
  /** Per-golfer scores */
  scores: Record<string, StrokePlayScores>; // golferId -> scores
}

/**
 * Calculates the cumulative score to par for a golfer up to a given hole.
 */
export function calculateCumulativeScoreToPar(
  grossScores: Record<number, number>,
  holes: Hole[],
  upToHole: number
): number {
  let cumulative = 0;
  for (let holeNumber = 1; holeNumber <= Math.max(1, upToHole); holeNumber++) {
    const gross = grossScores[holeNumber];
    const hole = holes.find(h => h.holeNumber === holeNumber);
    if (gross !== undefined && hole) {
      cumulative += gross - hole.par;
    }
  }
  return cumulative;
}

/**
 * Formats a score to par as a string (e.g., "+2", "E", "-1").
 */
export function formatScoreToPar(scoreToPar: number): string {
  if (scoreToPar === 0) return 'E';
  if (scoreToPar > 0) return `+${scoreToPar}`;
  return `${scoreToPar}`;
} 
import type { Hole } from '../models/Hole';

/**
 * Returns the handicap for a given hole number from an array of holes.
 * @param holes Array of Hole objects
 * @param holeNumber The hole number to look up
 * @returns Handicap for the hole, or 0 if not found
 */
export function getHoleHandicap(holes: Hole[], holeNumber: number): number {
  const holeData = holes.find(h => h.holeNumber === holeNumber);
  return holeData ? holeData.handicap : 0;
} 
import type { Hole } from '../models/Hole';

/**
 * Calculates the course handicap based on handicap index, slope rating, course rating, and par.
 * @param handicapIndex Player's handicap index (float)
 * @param slopeRating Slope rating of the course (int)
 * @param courseRating Course rating (float)
 * @param par Par for the course (int)
 * @returns Rounded course handicap (int)
 */
export function calculateCourseHandicap(
  handicapIndex: number,
  slopeRating: number,
  courseRating: number,
  par: number
): number {
  const courseHandicap = (handicapIndex * slopeRating / 113) + (courseRating - par);
  let roundedHandicap: number;
  if (courseHandicap % 1 >= 0.5) {
    roundedHandicap = Math.ceil(courseHandicap);
  } else {
    roundedHandicap = Math.floor(courseHandicap);
  }
  return roundedHandicap;
}

/**
 * Determines which holes receive strokes in stroke play based on course handicap.
 * @param courseHandicap The player's course handicap (int)
 * @param holes Array of Hole objects
 * @returns Array of hole numbers that receive strokes
 */
export function determineStrokePlayStrokeHoles(
  courseHandicap: number,
  holes: Hole[]
): number[] {
  // Sort holes by their handicap rating (ascending)
  const sortedHoles = [...holes].sort((a, b) => a.handicap - b.handicap);
  const absHandicap = Math.abs(courseHandicap);
  let strokeHoles: number[];
  if (courseHandicap < 0) {
    // For negative handicaps, take the last 'absHandicap' number of holes (easiest holes)
    strokeHoles = sortedHoles.slice(-absHandicap).map(h => h.holeNumber);
  } else {
    // For positive handicaps, take the first 'courseHandicap' number of holes (hardest holes)
    strokeHoles = sortedHoles.slice(0, absHandicap).map(h => h.holeNumber);
  }
  return strokeHoles;
}

/**
 * Determines which holes receive strokes in match play based on match play handicap.
 * @param matchPlayHandicap The match play handicap (int)
 * @param holes Array of Hole objects
 * @returns Array of hole numbers that receive strokes
 */
export function determineGameStrokeHoles(
  matchPlayHandicap: number,
  holes: Hole[]
): number[] {
  // Sort holes by their handicap rating (ascending)
  const sortedHoles = [...holes].sort((a, b) => a.handicap - b.handicap);
  // Take the first 'matchPlayHandicap' number of holes
  return sortedHoles.slice(0, matchPlayHandicap).map(h => h.holeNumber);
} 
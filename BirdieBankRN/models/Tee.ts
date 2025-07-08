// Tee.ts
// TypeScript interface for representing a tee in the React Native app

/**
 * Represents a tee at a golf course.
 */
export interface Tee {
  /** Unique identifier for the tee (optional, may be undefined) */
  id?: string;
  /** The ID of the course this tee belongs to */
  course_id: string;
  /** The name of the tee (e.g., "Blue", "White") */
  tee_name: string;
  /** Course rating (float in Swift, number in TS) */
  course_rating: number;
  /** Slope rating */
  slope_rating: number;
  /** Course par */
  course_par: number;
  /** Tee yardage */
  tee_yards: number;
} 
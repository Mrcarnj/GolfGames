// Hole.ts
// TypeScript interface for representing a golf hole in the React Native app

/**
 * Represents a golf hole.
 */
export interface Hole {
  /** Unique identifier for the hole (optional, may be undefined) */
  id?: string;
  /** Hole number */
  holeNumber: number;
  /** Par for the hole */
  par: number;
  /** Handicap for the hole */
  handicap: number;
  /** Yardage for the hole */
  yardage: number;
} 
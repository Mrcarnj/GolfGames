// Course.ts
// TypeScript interface for representing a golf course in the React Native app

/**
 * Represents a golf course.
 */
export interface Course {
  /** Unique identifier for the course (optional, may be undefined) */
  id?: string;
  /** Name of the course */
  name: string;
  /** Location of the course */
  location: string;
  /** Latitude (optional) */
  latitude?: number;
  /** Longitude (optional) */
  longitude?: number;
  /** Distance (optional, not in CodingKeys but present in Swift) */
  distance?: number;
} 
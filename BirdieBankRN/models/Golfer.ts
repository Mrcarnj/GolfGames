// Golfer.ts
// TypeScript interface for representing a golfer in the React Native app

import type { Tee } from './Tee';

/**
 * Represents a golfer in the app.
 */
export interface Golfer {
  /** Unique identifier for the golfer */
  id: string;
  /** First name of the golfer */
  firstName: string;
  /** Last name of the golfer */
  lastName: string;
  /** Handicap value (float in Swift, number in TS) */
  handicap: number;
  /** Tee object or undefined (optional) */
  tee?: Tee;
  /** GHIN number (optional) */
  ghinNumber?: number;
  /** Whether the golfer is checked (for selection UI) */
  isChecked: boolean;
  /** Course handicap (optional) */
  courseHandicap?: number;
}


/**
 * Utility function to get the full name of a golfer.
 */
export function getFullName(golfer: Golfer): string {
  return `${golfer.firstName} ${golfer.lastName}`;
}

/**
 * Returns a formatted name for the golfer, disambiguating by last initial if needed.
 * @param golfer The golfer to format
 * @param golfers The list of all golfers
 */
export function formattedName(golfer: Golfer, golfers: Golfer[]): string {
  const sameFirstName = golfers.filter(g => g.firstName === golfer.firstName);
  if (sameFirstName.length > 1) {
    return `${golfer.firstName} ${golfer.lastName.charAt(0)}.`;
  } else {
    return golfer.firstName;
  }
}

/**
 * Returns the last name, first initial format (e.g., "Smith, J.")
 */
export function lastNameFirstFormat(golfer: Golfer): string {
  return `${golfer.lastName}, ${golfer.firstName.charAt(0)}.`;
}

/**
 * Sorts an array of golfers by last name, then first initial.
 */
export function sortGolfersByLastName(golfers: Golfer[]): Golfer[] {
  return [...golfers].sort((a, b) => {
    const aName = lastNameFirstFormat(a);
    const bName = lastNameFirstFormat(b);
    return aName.localeCompare(bName);
  });
} 
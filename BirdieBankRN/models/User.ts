// User.ts
// TypeScript interface for representing a user in the React Native app

/**
 * Represents a user of the app.
 */
export interface User {
  /** Unique identifier for the user */
  id: string;
  /** First name of the user */
  firstName: string;
  /** Last name of the user */
  lastName: string;
  /** Email address */
  email: string;
  /** Handicap (optional) */
  handicap?: number;
  /** GHIN number (optional) */
  ghinNumber?: number;
}

/**
 * Utility function to get the full name of a user.
 */
export function getFullName(user: User): string {
  return `${user.firstName} ${user.lastName}`;
}

/**
 * Utility function to get the initials of a user.
 * Uses the first character of first and last name.
 */
export function getInitials(user: User): string {
  const first = user.firstName.charAt(0) || '';
  const last = user.lastName.charAt(0) || '';
  return `${first}${last}`.toUpperCase();
} 
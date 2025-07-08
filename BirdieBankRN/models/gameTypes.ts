// gameTypes.ts
// Merged type-only files for scorecard and stroke-related types

/** String union type for scorecard types. */
export type ScorecardType =
  | 'strokePlay'
  | 'games'
  | 'matchPlay'
  | 'betterBall'
  | 'ninePoint'
  | 'stablefordGross'
  | 'stablefordNet';

/** Enum for scorecard types (for use where enums are preferred). */
export enum ScorecardTypeEnum {
  StrokePlay = 'strokePlay',
  Games = 'games',
  MatchPlay = 'matchPlay',
  BetterBall = 'betterBall',
  NinePoint = 'ninePoint',
  StablefordGross = 'stablefordGross',
  StablefordNet = 'stablefordNet',
}

/** Represents the mapping of golfer IDs to their stroke holes. */
export type StrokeHoles = Record<string, number[]>;
/** Represents the mapping of golfer IDs to their course handicaps. */
export type CourseHandicaps = Record<string, number>;
/** Represents the mapping of golfer IDs to their match play stroke holes. */
export type MatchPlayStrokeHoles = Record<string, number[]>;
/** Represents the mapping of golfer IDs to their better ball stroke holes. */
export type BetterBallStrokeHoles = Record<string, number[]>;
/** Represents the mapping of golfer IDs to their nine point stroke holes. */
export type NinePointStrokeHoles = Record<string, number[]>; 

/**
 * State for all game-type–specific modes (match play, better ball, nine point, stableford, blind draw, etc.).
 */
export interface GameTypesState {
  // Match Play
  matchPlayStatus?: string;
  isMatchPlay: boolean;
  matchPlayStrokeHoles: Record<string, number[]>;
  matchPlayHandicap: number;
  matchPlayNetScores: Record<number, Record<string, number>>;
  previousHoleWinner?: string;
  holeWinners: Record<number, string>;
  holeTallies: Record<string, number>;
  matchScore: number;
  holesPlayed: number;
  lastUpdatedHole: number;
  talliedHoles: Set<number>;
  matchWinner?: string;
  winningScore?: string;
  selectedScorecardType: ScorecardType;
  matchStatus: Record<number, Record<string, number>>;
  matchStatusArray: number[];
  finalMatchStatusArray?: number[];
  matchWinningHole?: number;
  matchPlayGolfers?: [import('./Golfer').Golfer, import('./Golfer').Golfer];
  presses: Array<{ startHole: number; matchStatusArray: number[]; winner?: string; winningScore?: string; winningHole?: number }>;
  pressStatuses: string[];
  currentPressStartHole?: number;
  matchPlayHandicaps: Record<string, number>;

  // Better Ball
  isBetterBall: boolean;
  betterBallMatchArray: number[];
  betterBallMatchArrayCD: number[];
  betterBallFinalMatchArray?: number[];
  betterBallMatchStatus?: string;
  betterBallMatchStatusCD?: string;
  betterBallTeamAssignments: Record<string, string>;
  betterBallNetScores: Record<number, Record<string, number>>;
  betterBallHoleWinners: Record<number, string>;
  betterBallHoleWinnersCD: Record<number, string>;
  betterBallHoleTallies: Record<string, number>;
  betterBallMatchScore: number;
  betterBallMatchWinner?: string;
  betterBallMatchWinnerCD?: string;
  betterBallWinningScore?: string;
  betterBallWinningScoreCD?: string;
  betterBallMatchWinningHole?: number;
  betterBallMatchWinningHoleCD?: number;
  betterBallHandicaps: Record<string, number>;
  betterBallFinalStatistics: Record<string, number>;
  betterBallStrokeHoles: Record<string, number[]>;
  betterBallTalliedHoles: Set<number>;
  betterBallPresses: Array<{ startHole: number; matchStatusArray: number[]; winner?: string; winningScore?: string; winningHole?: number }>;
  betterBallPressStatuses: string[];
  betterBallCurrentPressStartHole?: number;

  // Nine Point
  isNinePoint: boolean;
  ninePointScores: Record<number, Record<string, number>>;
  ninePointTotalScores: Record<string, number>;
  ninePointStrokeHoles: Record<string, number[]>;

  // Stableford Gross
  isStablefordGross: boolean;
  stablefordGrossScores: Record<number, Record<string, number>>;
  stablefordGrossQuotas: Record<string, number>;
  stablefordGrossTotalScores: Record<string, number>;
  birdieCount: Record<string, number>;
  eagleOrBetterCount: Record<string, number>;
  parCount: Record<string, number>;
  bogeyCount: Record<string, number>;
  doubleBogeyPlusCount: Record<string, number>;

  // Stableford Net
  isStablefordNet: boolean;
  stablefordNetScores: Record<number, Record<string, number>>;
  stablefordNetQuotas: Record<string, number>;
  stablefordNetTotalScores: Record<string, number>;

  // Blind Draw Better Ball
  isBlindDrawBetterBall: boolean;
  blindDrawBetterBallMatchArray: number[];
  blindDrawBetterBallMatchStatus?: string;
  blindDrawBetterBallMatchWinner?: string;
  blindDrawBetterBallWinningScore?: string;
  blindDrawBetterBallMatchWinningHole?: number;
  blindDrawBetterBallHoleTallies: Record<string, number>;
  blindDrawBetterBallTalliedHoles: Set<number>;
  blindDrawBetterBallHoleWinners: Record<number, string>;
  blindDrawBetterBallNetScores: Record<number, Record<string, number>>;
  blindDrawBetterBallStrokeHoles: Record<string, number[]>;
  blindDrawBetterBallTeamAssignments: Record<string, string>;
  blindDrawBetterBallFinalStatistics: Record<string, number>;
  blindDrawScoresToUse: number;
  blindDrawBetterBallHandicaps: Record<string, number>;
} 
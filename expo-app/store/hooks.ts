import { useAuthStore } from "./authStore";
import { useRoundStore } from "./roundStore";
import { useSharedStore } from "./sharedStore";
import { useFriendsStore } from "./friendsStore";
import { useLocationStore } from "./locationStore";

export function useAuth() {
  const userSession = useAuthStore((s) => s.userSession);
  const currentUser = useAuthStore((s) => s.currentUser);
  const loginError = useAuthStore((s) => s.loginError);
  const signUp = useAuthStore((s) => s.signUp);
  const signIn = useAuthStore((s) => s.signIn);
  const signOut = useAuthStore((s) => s.signOut);
  return { userSession, currentUser, loginError, signUp, signIn, signOut };
}

export function useRound() {
  const selectedTee = useRoundStore((s) => s.selectedTee);
  const selectedCourse = useRoundStore((s) => s.selectedCourse);
  const grossScores = useRoundStore((s) => s.grossScores);
  const netStrokePlayScores = useRoundStore((s) => s.netStrokePlayScores);
  const pars = useRoundStore((s) => s.pars);
  const courseHandicaps = useRoundStore((s) => s.courseHandicaps);
  const golfers = useRoundStore((s) => s.golfers);
  const currentHole = useRoundStore((s) => s.currentHole);
  const roundType = useRoundStore((s) => s.roundType);
  const setSelectedTee = useRoundStore((s) => s.setSelectedTee);
  const setSelectedCourse = useRoundStore((s) => s.setSelectedCourse);
  const setGrossScores = useRoundStore((s) => s.setGrossScores);
  const setNetStrokePlayScores = useRoundStore((s) => s.setNetStrokePlayScores);
  const setPars = useRoundStore((s) => s.setPars);
  const setCourseHandicaps = useRoundStore((s) => s.setCourseHandicaps);
  const setGolfers = useRoundStore((s) => s.setGolfers);
  const setCurrentHole = useRoundStore((s) => s.setCurrentHole);
  const setRoundType = useRoundStore((s) => s.setRoundType);
  return {
    selectedTee,
    selectedCourse,
    grossScores,
    netStrokePlayScores,
    pars,
    courseHandicaps,
    golfers,
    currentHole,
    roundType,
    setSelectedTee,
    setSelectedCourse,
    setGrossScores,
    setNetStrokePlayScores,
    setPars,
    setCourseHandicaps,
    setGolfers,
    setCurrentHole,
    setRoundType,
  };
}

export { useSharedStore } from "./sharedStore";

export function useFriends() {
  const friends = useFriendsStore((s) => s.friends);
  const userId = useFriendsStore((s) => s.userId);
  const setFriends = useFriendsStore((s) => s.setFriends);
  const setUserId = useFriendsStore((s) => s.setUserId);
  return { friends, userId, setFriends, setUserId };
}

export function useLocation() {
  const locationStatus = useLocationStore((s) => s.locationStatus);
  const lastLocation = useLocationStore((s) => s.lastLocation);
  const isLocationAvailable = useLocationStore((s) => s.isLocationAvailable);
  const setLocationStatus = useLocationStore((s) => s.setLocationStatus);
  const setLastLocation = useLocationStore((s) => s.setLastLocation);
  const setIsLocationAvailable = useLocationStore(
    (s) => s.setIsLocationAvailable,
  );
  return {
    locationStatus,
    lastLocation,
    isLocationAvailable,
    setLocationStatus,
    setLastLocation,
    setIsLocationAvailable,
  };
}

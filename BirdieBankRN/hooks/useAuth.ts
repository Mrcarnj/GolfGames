import { useAuthContext } from "../context/AuthProvider";
import { auth, db } from "../firebase";
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut as fbSignOut,
  sendPasswordResetEmail,
  updateProfile as fbUpdateProfile,
  User as FirebaseUser,
} from "firebase/auth";
import { doc, setDoc, getDoc, updateDoc, getDocs, collection, query, where, deleteDoc } from "firebase/firestore";
import {
  validateEmail,
  validatePassword,
  validateName,
  validateHandicap,
  validateGHIN,
} from "../utilities/authUtils";
import { User as AppUser } from "../models/User";

export function useAuth() {
  const { user, loading, error, setError } = useAuthContext();

  // Register new user (with migration logic)
  const register = async (
    email: string,
    password: string,
    firstName: string,
    lastName: string,
    handicap?: string,
    ghinNumber?: string
  ) => {
    setError(null);
    if (!validateEmail(email)) throw new Error("Invalid email format");
    if (!validatePassword(password)) throw new Error("Password must be at least 8 characters, include a letter and a number");
    if (!validateName(firstName)) throw new Error("Invalid first name format");
    if (!validateName(lastName)) throw new Error("Invalid last name format");
    if (handicap && !validateHandicap(handicap)) throw new Error("Invalid handicap format");
    if (ghinNumber && !validateGHIN(ghinNumber)) throw new Error("Invalid GHIN number format");

    // Check for existing user in Firestore
    const usersRef = collection(db, "users");
    const q = query(usersRef, where("email", "==", email.trim()));
    const querySnapshot = await getDocs(q);

    // Create Firebase Auth user
    const userCredential = await createUserWithEmailAndPassword(auth, email.trim(), password);
    const firebaseUser = userCredential.user;

    let userData: AppUser = {
      id: firebaseUser.uid,
      email: firebaseUser.email || "",
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      handicap: handicap ? parseFloat(handicap) : undefined,
      ghinNumber: ghinNumber ? parseInt(ghinNumber) : undefined,
    };

    if (!querySnapshot.empty) {
      // Existing user found, migrate friends/rounds, update doc, delete old doc
      const oldUserDoc = querySnapshot.docs[0];
      const oldUserId = oldUserDoc.id;
      const newUserId = firebaseUser.uid;
      await setDoc(doc(db, "users", newUserId), userData);
      await migrateFriends(oldUserId, newUserId);
      await migrateRounds(oldUserId, newUserId);
      await deleteDoc(doc(db, "users", oldUserId));
    } else {
      // New user
      await setDoc(doc(db, "users", firebaseUser.uid), userData);
    }
    // Optionally update displayName
    await fbUpdateProfile(firebaseUser, { displayName: `${firstName.trim()} ${lastName.trim()}` });
  };

  // Login
  const login = async (email: string, password: string) => {
    setError(null);
    if (!validateEmail(email)) throw new Error("Invalid email format");
    await signInWithEmailAndPassword(auth, email.trim(), password);
  };

  // Logout
  const logout = async () => {
    setError(null);
    await fbSignOut(auth);
  };

  // Password reset
  const resetPassword = async (email: string) => {
    setError(null);
    if (!validateEmail(email)) throw new Error("Invalid email format");
    await sendPasswordResetEmail(auth, email.trim());
  };

  // Update user profile
  const updateUserProfile = async (updates: Partial<AppUser & FirebaseUser>) => {
    setError(null);
    if (!auth.currentUser) throw new Error("No authenticated user");
    // Update Auth displayName if needed
    if (updates.displayName) {
      await fbUpdateProfile(auth.currentUser, { displayName: updates.displayName });
    }
    // Update Firestore user doc
    const userRef = doc(db, "users", auth.currentUser.uid);
    const firestoreUpdates: Partial<AppUser> = {};
    if (updates.firstName) firestoreUpdates.firstName = updates.firstName;
    if (updates.lastName) firestoreUpdates.lastName = updates.lastName;
    if (updates.handicap !== undefined) firestoreUpdates.handicap = updates.handicap;
    if (updates.ghinNumber !== undefined) firestoreUpdates.ghinNumber = updates.ghinNumber;
    if (updates.email) firestoreUpdates.email = updates.email;
    await updateDoc(userRef, firestoreUpdates);
  };

  // Migration stubs (for completeness)
  const migrateFriends = async (oldUserId: string, newUserId: string) => {
    const oldFriendsRef = collection(db, "users", oldUserId, "friends");
    const newFriendsRef = collection(db, "users", newUserId, "friends");
    const snapshot = await getDocs(oldFriendsRef);
    for (const docSnap of snapshot.docs) {
      await setDoc(doc(newFriendsRef, docSnap.id), docSnap.data());
    }
  };

  const migrateRounds = async (oldUserId: string, newUserId: string) => {
    const oldRoundsRef = collection(db, "users", oldUserId, "rounds");
    const newRoundsRef = collection(db, "users", newUserId, "rounds");
    const snapshot = await getDocs(oldRoundsRef);
    for (const docSnap of snapshot.docs) {
      await setDoc(doc(newRoundsRef, docSnap.id), docSnap.data());
    }
  };

  // Delete account
  const deleteAccount = async () => {
    setError(null);
    if (!auth.currentUser) throw new Error("No authenticated user");
    const userRef = doc(db, "users", auth.currentUser.uid);
    await updateDoc(userRef, {
      isDeleted: true,
      deletedAt: new Date().toISOString(),
      lastKnownEmail: auth.currentUser.email,
    });
    await auth.currentUser.delete();
  };

  return {
    user: user as (FirebaseUser & AppUser) | null,
    loading,
    error,
    register,
    login,
    logout,
    resetPassword,
    updateUserProfile,
    deleteAccount,
    setError,
  };
} 
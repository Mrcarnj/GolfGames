import { auth } from "./firebase";
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  sendPasswordResetEmail,
  signOut,
  updateProfile,
  GoogleAuthProvider,
  signInWithCredential,
} from "firebase/auth";
import * as Google from "expo-auth-session/providers/google";

// Email/password registration
export const registerUser = async (email, password, displayName) => {
  const userCredential = await createUserWithEmailAndPassword(
    auth,
    email,
    password,
  );
  if (displayName) {
    await updateProfile(userCredential.user, { displayName });
  }
  return userCredential.user;
};

// Email/password login
export const loginUser = async (email, password) => {
  const userCredential = await signInWithEmailAndPassword(
    auth,
    email,
    password,
  );
  return userCredential.user;
};

// Sign out
export const logoutUser = async () => {
  await signOut(auth);
};

// Password reset
export const resetPassword = async (email) => {
  await sendPasswordResetEmail(auth, email);
};

// Google OAuth sign in (Expo + Firebase)
export const signInWithGoogle = async (expoAuthResponse) => {
  if (!expoAuthResponse?.type || expoAuthResponse.type !== "success")
    throw new Error("Google sign-in failed");
  const { id_token, access_token } = expoAuthResponse.params;
  const credential = GoogleAuthProvider.credential(id_token, access_token);
  const userCredential = await signInWithCredential(auth, credential);
  return userCredential.user;
};

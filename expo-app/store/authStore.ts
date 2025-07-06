import { create } from "zustand";
import { persist } from "zustand/middleware";
import { auth } from "../firebase";
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  User,
} from "firebase/auth";
import { zustandAsyncStorage } from "./persistConfig";

interface SerializableUser {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
}

interface AuthState {
  userSession: SerializableUser | null;
  loginError: string | null;
  signUp: (email: string, password: string) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

function toSerializableUser(user: User): SerializableUser {
  const plain = {
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoURL: user.photoURL,
  };
  // Deep clone to strip any prototype
  const serializable = JSON.parse(JSON.stringify(plain));
  console.log("[authStore] toSerializableUser", serializable);
  return serializable;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      userSession: null,
      loginError: null,
      signUp: async (email, password) => {
        console.log("[authStore] signUp called", { email });
        try {
          const cred = await createUserWithEmailAndPassword(
            auth,
            email,
            password,
          );
          const serializableUser = toSerializableUser(cred.user);
          set({ userSession: serializableUser, loginError: null });
          console.log("[authStore] signUp set userSession", serializableUser);
        } catch (error: any) {
          console.error("[authStore] signUp error", error);
          set({ loginError: error.message });
        }
      },
      signIn: async (email, password) => {
        console.log("[authStore] signIn called", { email });
        try {
          const cred = await signInWithEmailAndPassword(auth, email, password);
          const serializableUser = toSerializableUser(cred.user);
          set({ userSession: serializableUser, loginError: null });
          console.log("[authStore] signIn set userSession", serializableUser);
        } catch (error: any) {
          console.error("[authStore] signIn error", error);
          set({ loginError: error.message });
        }
      },
      signOut: async () => {
        console.log("[authStore] signOut called");
        try {
          await auth.signOut();
          set({ userSession: null, loginError: null });
        } catch (error: any) {
          console.error("[authStore] signOut error", error);
          set({ loginError: error.message });
        }
      },
    }),
    {
      name: "auth-store",
      storage: zustandAsyncStorage,
      partialize: (state) => {
        const result = {
          userSession: state.userSession
            ? JSON.parse(JSON.stringify(state.userSession))
            : null,
        };
        console.log("[authStore] partialize result", result);
        return result;
      },
      migrate: (persistedState, version) => {
        // If the persisted userSession is not a plain object, clear it
        if (
          persistedState &&
          typeof persistedState.userSession === "object" &&
          persistedState.userSession !== null
        ) {
          const u = persistedState.userSession;
          if (typeof u.uid === "string" && "email" in u) {
            return persistedState;
          }
        }
        console.log("[authStore] Migration: clearing corrupt userSession");
        return { userSession: null };
      },
      onRehydrateStorage: () => (state) => {
        console.log("[authStore] Rehydrated from AsyncStorage", state);
      },
    },
  ),
);

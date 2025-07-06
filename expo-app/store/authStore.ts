import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { auth } from '../firebase';
import { createUserWithEmailAndPassword, signInWithEmailAndPassword, User } from 'firebase/auth';
import { zustandAsyncStorage } from './persistConfig';

interface AuthState {
  userSession: User | null;
  currentUser: any | null;
  loginError: string | null;
  signUp: (email: string, password: string) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      userSession: auth.currentUser,
      currentUser: null,
      loginError: null,
      signUp: async (email, password) => {
        try {
          const cred = await createUserWithEmailAndPassword(auth, email, password);
          set({ userSession: cred.user, loginError: null });
        } catch (error: any) {
          set({ loginError: error.message });
        }
      },
      signIn: async (email, password) => {
        try {
          const cred = await signInWithEmailAndPassword(auth, email, password);
          set({ userSession: cred.user, loginError: null });
        } catch (error: any) {
          set({ loginError: error.message });
        }
      },
      signOut: async () => {
        try {
          await auth.signOut();
          set({ userSession: null, currentUser: null, loginError: null });
        } catch (error: any) {
          set({ loginError: error.message });
        }
      },
    }),
    {
      name: 'auth-store',
      storage: zustandAsyncStorage,
      partialize: (state) => ({ userSession: state.userSession, currentUser: state.currentUser }),
    }
  )
); 
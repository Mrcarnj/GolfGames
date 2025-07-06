import { initializeApp } from "firebase/app";
import {
  getAuth,
  initializeAuth,
  getReactNativePersistence,
} from "firebase/auth";
import { getFirestore, enableIndexedDbPersistence } from "firebase/firestore";
import { getStorage } from "firebase/storage";
import { Platform } from "react-native";
let AsyncStorage;
try {
  AsyncStorage = require("@react-native-async-storage/async-storage").default;
} catch {}

// Inline Firebase config (migrated from iOS GoogleService-Info.plist)
const firebaseConfig = {
  apiKey: "AIzaSyBBaqH9_FAhboeEoOih_FaMoiwpiAlN9kI",
  authDomain: "gamblegolf-19624.firebaseapp.com",
  projectId: "gamblegolf-19624",
  storageBucket: "gamblegolf-19624.appspot.com",
  messagingSenderId: "64996444063",
  appId: "1:64996444063:web:20c8e1ca5d553a902ddfaa",
};

const app = initializeApp(firebaseConfig);
let auth;
if (Platform.OS === "ios" || Platform.OS === "android") {
  auth = initializeAuth(app, {
    persistence: getReactNativePersistence(AsyncStorage),
  });
} else {
  auth = getAuth(app);
}
export { auth };
export const db = getFirestore(app);
export const storage = getStorage(app);

// Enable offline persistence for Firestore
if (typeof window !== "undefined") {
  enableIndexedDbPersistence(db).catch((err) => {
    console.warn("Firestore offline persistence error:", err);
  });
}

export default app;

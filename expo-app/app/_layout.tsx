import { Stack } from "expo-router";
import { useAuth } from "../store/hooks";
import Home from "./home";

export default function RootLayout() {
  const { userSession } = useAuth();
  if (userSession) {
    return <Home />;
  }
  return <Stack screenOptions={{ headerShown: false }} />;
}

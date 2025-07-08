import { useAuth } from "../hooks/useAuth";
import { Redirect } from "expo-router";
import { View, ActivityIndicator } from "react-native";
import { useEffect, useState } from "react";

export default function Index() {
  const { user, loading } = useAuth();
  const [isInitializing, setIsInitializing] = useState(true);

  useEffect(() => {
    const initTimeout = setTimeout(() => {
      setIsInitializing(false);
    }, 1000);
    return () => clearTimeout(initTimeout);
  }, []);

  if (loading || isInitializing) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#000' }}>
        <ActivityIndicator size="large" color="#ff6600" />
      </View>
    );
  }

  if (!user) {
    return <Redirect href="/(auth)/login" />;
  }

  // Redirect to the main protected area
  return <Redirect href="/(protected)/(tabs)" />;
}

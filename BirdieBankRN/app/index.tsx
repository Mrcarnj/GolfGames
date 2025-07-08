import React, { useEffect } from "react";
import { View, ActivityIndicator } from "react-native";
import { useAuth } from "../hooks/useAuth";
import LoginView from "./(auth)/login";
import { useRouter } from "expo-router";

export default function Index() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (user) {
      router.replace("/(tabs)");
    }
  }, [user, router]);

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  if (!user) {
    return <LoginView />;
  }

  // Optionally, render nothing while redirecting
  return null;
}

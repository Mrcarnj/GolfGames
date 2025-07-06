import React, { useEffect } from "react";
import { View, Text, Button, StyleSheet } from "react-native";
import { useAuth } from "../store/hooks";
import { useRouter } from "expo-router";

export default function Home() {
  const { signOut, userSession } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!userSession) {
      router.replace("/");
    }
  }, [userSession]);

  if (!userSession) {
    return null;
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        Welcome, {userSession?.email || "Golfer"}!
      </Text>
      <Button
        title="Start New Round"
        onPress={() => router.push("/CourseSelection")}
      />
      <Button
        title="Recent Rounds"
        onPress={() => router.push("/RecentRounds")}
      />
      <Button title="Favorites" onPress={() => router.push("/Favorites")} />
      <Button title="Logout" onPress={signOut} />
      {/* TODO: Add main app navigation and features here, matching iOS app */}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#fff",
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 24,
  },
});

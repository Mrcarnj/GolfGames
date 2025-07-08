import React from "react";
import { View, Text, Image, StyleSheet, TouchableOpacity, ScrollView } from "react-native";
import { useAuth } from "../../hooks/useAuth";
import { useRouter } from "expo-router";

export default function TabsIndex() {
  const { user } = useAuth();
  const router = useRouter();

  if (!user) return null;

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.welcome}>Welcome, {user.displayName?.split(" ")[0] || user.email}!</Text>
      <View style={{ alignItems: "center", marginBottom: 20 }}>
        <Image
          source={require("../../assets/images/golfgamble_bag.png")}
          style={styles.image}
          resizeMode="contain"
        />
      </View>
      <TouchableOpacity
        style={styles.roundButton}
        onPress={() => router.push("/single-round-setup")} //needs to be changed to the new round setup
      >
        <Text style={styles.roundButtonText}>New Round</Text>
      </TouchableOpacity>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Recent Rounds</Text>
        {/* TODO: Implement recent rounds list */}
        <Text style={styles.noRounds}>No recent rounds</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: "#fff",
    padding: 24,
    alignItems: "center",
  },
  welcome: {
    fontSize: 22,
    fontWeight: "600",
    marginTop: 35,
    marginBottom: 10,
    textAlign: "center",
  },
  image: {
    width: 100,
    height: 120,
    borderRadius: 10,
    marginBottom: 10,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
  },
  roundButton: {
    backgroundColor: "#20B2AA",
    borderRadius: 10,
    height: 48,
    width: "100%",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 30,
  },
  roundButtonText: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 18,
  },
  section: {
    width: "100%",
    marginTop: 20,
    alignItems: "center",
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: "bold",
    marginBottom: 10,
  },
  noRounds: {
    color: "#888",
    fontSize: 15,
    marginTop: 10,
  },
}); 
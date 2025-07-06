import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Button,
  ActivityIndicator,
  ScrollView,
} from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import { db } from "../firebase";
import { doc, getDoc } from "firebase/firestore";

export default function RoundSummary() {
  const { roundId } = useLocalSearchParams();
  const router = useRouter();
  const [round, setRound] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchRound = async () => {
      if (!roundId) return;
      setLoading(true);
      const docRef = doc(db, "rounds", roundId);
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) {
        setRound(docSnap.data());
      }
      setLoading(false);
    };
    fetchRound();
  }, [roundId]);

  if (loading) {
    return <ActivityIndicator style={{ flex: 1 }} />;
  }
  if (!round) {
    return (
      <View style={styles.container}>
        <Text>Round not found.</Text>
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Round Summary</Text>
      <Text>Course: {round.courseName}</Text>
      <Text>Date: {round.date?.toDate?.().toLocaleString?.() || ""}</Text>
      <Text>Games: {Object.keys(round.games || {}).join(", ")}</Text>
      <Text style={styles.section}>Golfers & Scores:</Text>
      {round.golfers.map((g, idx) => (
        <View key={g.id} style={styles.golferRow}>
          <Text style={styles.golferName}>
            {g.firstName} {g.lastName}
          </Text>
          <Text>
            Scores: {Object.values(round.scores[g.id] || {}).join(", ")}
          </Text>
        </View>
      ))}
      <Button title="Return Home" onPress={() => router.replace("/home")} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    padding: 24,
    backgroundColor: "#fff",
    alignItems: "flex-start",
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 24,
  },
  section: {
    marginTop: 16,
    fontWeight: "bold",
  },
  golferRow: {
    marginBottom: 12,
  },
  golferName: {
    fontWeight: "bold",
  },
});

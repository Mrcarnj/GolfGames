import React from "react";
import {
  View,
  Text,
  StyleSheet,
  Button,
  FlatList,
  TouchableOpacity,
} from "react-native";
import { useRouter } from "expo-router";
import { useSharedStore } from "../store/hooks";

export default function Favorites() {
  const router = useRouter();
  const favorites = useSharedStore((s) => s.favorites);
  const removeFavorite = useSharedStore((s) => s.removeFavorite);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Favorites</Text>
      <FlatList
        data={favorites}
        keyExtractor={(item) => `${item.courseId}-${item.teeId}`}
        renderItem={({ item }) => (
          <View style={styles.favoriteRow}>
            <TouchableOpacity
              style={styles.favoriteInfo}
              onPress={() =>
                router.push({
                  pathname: "/CourseDetails",
                  params: { courseId: item.courseId },
                })
              }
            >
              <Text style={styles.courseName}>{item.courseName}</Text>
              <Text style={styles.teeName}>{item.teeName}</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.removeBtn}
              onPress={() => removeFavorite(item.courseId, item.teeId)}
            >
              <Text style={{ fontSize: 20, color: "#bbb" }}>✕</Text>
            </TouchableOpacity>
          </View>
        )}
        ListEmptyComponent={
          <Text style={{ marginTop: 32 }}>No favorites yet.</Text>
        }
      />
      <Button title="Back to Home" onPress={() => router.replace("/home")} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 24,
    backgroundColor: "#fff",
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 24,
  },
  favoriteRow: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 16,
    borderBottomWidth: 1,
    borderColor: "#eee",
    paddingBottom: 8,
  },
  favoriteInfo: {
    flex: 1,
  },
  courseName: {
    fontSize: 18,
    fontWeight: "bold",
  },
  teeName: {
    fontSize: 16,
    color: "#666",
  },
  removeBtn: {
    marginLeft: 16,
    padding: 8,
  },
});

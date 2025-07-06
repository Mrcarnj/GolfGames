import React, { useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Button,
  FlatList,
  TouchableOpacity,
} from "react-native";
import { useRouter } from "expo-router";
import { useAuth } from "../store/hooks";
import FriendsListModal from "../components/FriendsListModal";
import { useRoundStore } from "../store/roundStore";
import { Golfer } from "../types/Golfer";

export default function AddGolfers() {
  const router = useRouter();
  const { userSession } = useAuth();
  const [showModal, setShowModal] = useState(false);
  const [selectedFriends, setSelectedFriends] = useState<Golfer[]>([]);
  const { setGolfers } = useRoundStore();

  if (!userSession) return null; // or a spinner

  // Fallbacks in case userSession does not have these fields
  const currentUser: Golfer = {
    id: userSession.uid,
    firstName: (userSession as any).firstName ?? "You",
    lastName: (userSession as any).lastName ?? "",
    handicap: (userSession as any).handicap ?? 0,
  };

  const golfers = [currentUser, ...selectedFriends];

  const handleNext = () => {
    if (golfers.length === 0) {
      alert("Add at least one golfer");
      return;
    }
    setGolfers(golfers);
    router.push("/TeeSelection");
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Add Golfers</Text>
      <FlatList
        data={golfers}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={styles.golferRow}>
            <Text>
              {item.firstName} {item.lastName} (HCP: {item.handicap})
            </Text>
            {item.id !== currentUser.id && (
              <TouchableOpacity
                onPress={() =>
                  setSelectedFriends(
                    selectedFriends.filter((f) => f.id !== item.id),
                  )
                }
              >
                <Text style={styles.removeBtn}>Remove</Text>
              </TouchableOpacity>
            )}
          </View>
        )}
        ListEmptyComponent={<Text>No golfers added.</Text>}
        style={{ width: "100%", marginVertical: 16 }}
      />
      <Button title="Add Golfer" onPress={() => setShowModal(true)} />
      <Button
        title="Next: Tee Selection"
        onPress={handleNext}
        disabled={golfers.length === 0}
      />
      <FriendsListModal
        visible={showModal}
        onClose={() => setShowModal(false)}
        selected={selectedFriends}
        onSelect={setSelectedFriends}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: "center",
    backgroundColor: "#fff",
    padding: 24,
  },
  title: { fontSize: 24, fontWeight: "bold", marginBottom: 24 },
  golferRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderColor: "#eee",
    width: "100%",
  },
  removeBtn: { color: "red", marginLeft: 12 },
});

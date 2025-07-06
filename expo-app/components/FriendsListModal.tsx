import React, { useState, useEffect } from "react";
import {
  Modal,
  View,
  Text,
  FlatList,
  TouchableOpacity,
  Button,
  StyleSheet,
} from "react-native";
import { useFriends } from "../hooks/useFriends";
import { Golfer } from "../types/Golfer";

interface FriendsListModalProps {
  visible: boolean;
  onClose: () => void;
  selected: Golfer[];
  onSelect: (selected: Golfer[]) => void;
}

export default function FriendsListModal({
  visible,
  onClose,
  selected,
  onSelect,
}: FriendsListModalProps) {
  const { friends, loading } = useFriends();
  const [localSelected, setLocalSelected] = useState<Golfer[]>(selected || []);

  useEffect(() => {
    setLocalSelected(selected || []);
  }, [selected, visible]);

  const toggleFriend = (friend: Golfer) => {
    setLocalSelected((prev) =>
      prev.some((f) => f.id === friend.id)
        ? prev.filter((f) => f.id !== friend.id)
        : [...prev, friend],
    );
  };

  const handleDone = () => {
    onSelect(localSelected);
    onClose();
  };

  return (
    <Modal visible={visible} animationType="slide">
      <View style={styles.container}>
        <Text style={styles.title}>Select Friends</Text>
        <FlatList
          data={friends}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.row}
              onPress={() => toggleFriend(item)}
            >
              <Text>
                {item.firstName} {item.lastName}
              </Text>
              <Text>
                {localSelected.some((f) => f.id === item.id) ? "✓" : ""}
              </Text>
            </TouchableOpacity>
          )}
          ListEmptyComponent={<Text>No friends found.</Text>}
        />
        <Button title="Done" onPress={handleDone} />
        <Button title="Cancel" onPress={onClose} color="red" />
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 24, backgroundColor: "#fff" },
  title: { fontSize: 20, fontWeight: "bold", marginBottom: 16 },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderColor: "#eee",
  },
});

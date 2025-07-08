import React, { useState, useEffect } from "react";
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert, ActivityIndicator, ScrollView } from "react-native";
import { useAuth } from "../../hooks/useAuth";

const APP_VERSION = "2.4.4";

function getInitials(name: string, last: string) {
  return (name?.[0] || "").toUpperCase() + (last?.[0] || "").toUpperCase();
}

export default function ProfileView() {
  const { user, updateUserProfile, logout, deleteAccount, loading } = useAuth();
  const [isEditing, setIsEditing] = useState(false);
  const [editedFirstName, setEditedFirstName] = useState("");
  const [editedLastName, setEditedLastName] = useState("");
  const [editedEmail, setEditedEmail] = useState("");
  const [editedHandicap, setEditedHandicap] = useState("");
  const [editedGHIN, setEditedGHIN] = useState("");
  const [showDeleteAlert, setShowDeleteAlert] = useState(false);
  const [showingAlert, setShowingAlert] = useState(false);
  const [alertMessage, setAlertMessage] = useState("");

  useEffect(() => {
    if (user) {
      setEditedFirstName(user.displayName?.split(" ")[0] || "");
      setEditedLastName(user.displayName?.split(" ")[1] || "");
      setEditedEmail(user.email || "");
      // If user has a plus sign in displayName or custom field, preserve it
      if (user.handicap !== undefined && user.handicap !== null) {
        setEditedHandicap(String(user.handicap));
      } else {
        setEditedHandicap("");
      }
      if (user.ghinNumber !== undefined && user.ghinNumber !== null) {
        setEditedGHIN(String(user.ghinNumber));
      } else {
        setEditedGHIN("");
      }
    }
  }, [user]);

  useEffect(() => {
    if (showingAlert) {
      Alert.alert("Profile Update", alertMessage, [
        { text: "OK", onPress: () => setShowingAlert(false) }
      ]);
    }
  }, [showingAlert, alertMessage]);

  useEffect(() => {
    if (showDeleteAlert) {
      Alert.alert(
        "Delete Account",
        "Are you sure you want to delete your account? This action cannot be undone.",
        [
          { text: "Cancel", style: "cancel", onPress: () => setShowDeleteAlert(false) },
          { text: "Delete", style: "destructive", onPress: () => { setShowDeleteAlert(false); handleDelete(); } },
        ]
      );
    }
  }, [showDeleteAlert]);

  if (loading || !user) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  const handleUpdate = async () => {
    try {
      // Only update displayName and custom fields
      await updateUserProfile({
        displayName: `${editedFirstName} ${editedLastName}`.trim(),
        email: editedEmail,
        // Optionally, update custom fields in Firestore if needed
      });
      setIsEditing(false);
      setAlertMessage("Profile updated successfully");
      setShowingAlert(true);
    } catch (err: any) {
      setAlertMessage("Failed to update profile: " + (err.message || "Unknown error"));
      setShowingAlert(true);
    }
  };

  const handleDelete = async () => {
    try {
      await deleteAccount();
      // Optionally, navigate to login or home
    } catch (err: any) {
      setAlertMessage("Failed to delete account: " + (err.message || "Unknown error"));
      setShowingAlert(true);
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.avatarRow}>
        <View style={styles.avatarCircle}>
          <Text style={styles.avatarText}>
            {getInitials(editedFirstName, editedLastName)}
          </Text>
        </View>
        <View style={{ flex: 1, marginLeft: 16 }}>
          {isEditing ? (
            <>
              <TextInput
                style={styles.input}
                value={editedFirstName}
                onChangeText={setEditedFirstName}
                placeholder="First Name"
              />
              <TextInput
                style={styles.input}
                value={editedLastName}
                onChangeText={setEditedLastName}
                placeholder="Last Name"
              />
              <TextInput
                style={styles.input}
                value={editedEmail}
                onChangeText={setEditedEmail}
                placeholder="Email"
                autoCapitalize="none"
                keyboardType="email-address"
              />
            </>
          ) : (
            <>
              <Text style={styles.name}>{user.displayName?.split(" ")[0] || ""}</Text>
              <Text style={styles.name}>{user.displayName?.split(" ")[1] || ""}</Text>
              <Text style={styles.email}>{user.email}</Text>
            </>
          )}
        </View>
      </View>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Golfer Info</Text>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Handicap</Text>
          {isEditing ? (
            <TextInput
              style={[styles.input, { textAlign: "right", minWidth: 80 }]}
              value={editedHandicap}
              onChangeText={setEditedHandicap}
              placeholder="Handicap"
              keyboardType="decimal-pad"
            />
          ) : (
            <Text style={styles.infoValue}>{editedHandicap ? editedHandicap : "N/A"}</Text>
          )}
        </View>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>GHIN</Text>
          {isEditing ? (
            <TextInput
              style={[styles.input, { textAlign: "right", minWidth: 80 }]}
              value={editedGHIN}
              onChangeText={setEditedGHIN}
              placeholder="GHIN"
              keyboardType="number-pad"
            />
          ) : (
            <Text style={styles.infoValue}>{editedGHIN ? editedGHIN : "N/A"}</Text>
          )}
        </View>
      </View>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>App Info</Text>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Version</Text>
          <Text style={styles.infoValue}>{APP_VERSION}</Text>
        </View>
      </View>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Account</Text>
        <TouchableOpacity style={styles.accountButton} onPress={logout}>
          <Text style={[styles.accountButtonText, { color: "#d00" }]}>Sign Out</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.accountButton, { marginTop: 8 }]}
          onPress={() => setShowDeleteAlert(true)}
        >
          <Text style={[styles.accountButtonText, { color: "#d00" }]}>Delete Account</Text>
        </TouchableOpacity>
      </View>
      {/* Edit/Update toggle */}
      <TouchableOpacity
        style={styles.editButton}
        onPress={() => {
          if (isEditing) {
            handleUpdate();
          } else {
            setIsEditing(true);
          }
        }}
      >
        <Text style={styles.editButtonText}>{isEditing ? "Update" : "Edit"}</Text>
      </TouchableOpacity>
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
  avatarRow: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 24,
    width: "100%",
  },
  avatarCircle: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: "#ccc",
    alignItems: "center",
    justifyContent: "center",
  },
  avatarText: {
    color: "#fff",
    fontSize: 32,
    fontWeight: "bold",
  },
  name: {
    fontSize: 18,
    fontWeight: "600",
    marginBottom: 2,
  },
  email: {
    fontSize: 14,
    color: "#888",
  },
  section: {
    width: "100%",
    marginTop: 20,
    marginBottom: 10,
    backgroundColor: "#f7f7f7",
    borderRadius: 10,
    padding: 16,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: "bold",
    marginBottom: 10,
  },
  infoRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 10,
  },
  infoLabel: {
    fontSize: 15,
    color: "#333",
  },
  infoValue: {
    fontSize: 15,
    color: "#555",
    minWidth: 80,
    textAlign: "right",
  },
  input: {
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 8,
    padding: 10,
    fontSize: 15,
    backgroundColor: "#fff",
    marginBottom: 4,
  },
  accountButton: {
    paddingVertical: 10,
    alignItems: "center",
    borderRadius: 8,
    backgroundColor: "#fff",
    borderWidth: 1,
    borderColor: "#eee",
  },
  accountButtonText: {
    fontSize: 16,
    fontWeight: "600",
  },
  editButton: {
    marginTop: 24,
    backgroundColor: "#007AFF",
    borderRadius: 10,
    paddingVertical: 12,
    paddingHorizontal: 32,
    alignItems: "center",
  },
  editButtonText: {
    color: "#fff",
    fontWeight: "bold",
    fontSize: 16,
  },
}); 
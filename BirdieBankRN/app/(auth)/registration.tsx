import React, { useState, useEffect } from "react";
import { View, Text, TextInput, TouchableOpacity, Image, Alert, StyleSheet, ScrollView, Keyboard, ActivityIndicator } from "react-native";
import { useAuth } from "../../hooks/useAuth";
import { useRouter } from "expo-router";

export default function RegistrationView() {
  const { register, loading, error, setError } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [handicap, setHandicap] = useState("");
  const [ghinNumber, setGhinNumber] = useState("");
  const [hasEightCharacters, setHasEightCharacters] = useState(false);
  const [hasNumber, setHasNumber] = useState(false);
  const [showingAlert, setShowingAlert] = useState(false);
  const [alertMessage, setAlertMessage] = useState("");
  const [plusHandicap, setPlusHandicap] = useState(false);
  const router = useRouter();

  useEffect(() => {
    if (showingAlert) {
      Alert.alert("Registration Error", alertMessage, [
        { text: "OK", onPress: () => setShowingAlert(false) }
      ]);
    }
  }, [showingAlert, alertMessage]);

  const validatePassword = (pw: string) => {
    setHasEightCharacters(pw.length >= 8);
    setHasNumber(/[0-9]/.test(pw));
  };

  const isPasswordValid = hasEightCharacters && hasNumber;

  const formIsValid =
    email.length > 0 &&
    email.includes("@") &&
    firstName.length > 0 &&
    lastName.length > 0 &&
    password.length > 0 &&
    password.length > 7 &&
    isPasswordValid &&
    password === confirmPassword;

  const handleRegister = async () => {
    setError(null);
    try {
      let handicapToSave = handicap.trim();
      if (plusHandicap && handicapToSave) {
        handicapToSave = "+" + handicapToSave;
      }
      await register(
        email,
        password,
        firstName,
        lastName,
        handicapToSave || undefined,
        ghinNumber.trim() ? ghinNumber : undefined
      );
      // On success, go back to login
      router.replace("/login");
    } catch (err: any) {
      setAlertMessage(err.message || "Registration failed");
      setShowingAlert(true);
    }
  };

  const handleHandicapChange = (value: string) => {
    // Allow only numbers and at most one decimal point, and only one digit after the decimal
    let filtered = value.replace(/[^0-9.]/g, "");
    // Only allow one decimal point
    const parts = filtered.split(".");
    if (parts.length > 2) {
      filtered = parts[0] + "." + parts.slice(1).join("");
    }
    // Only allow one digit after the decimal
    if (filtered.includes(".")) {
      const [intPart, decPart] = filtered.split(".");
      filtered = intPart + "." + decPart.slice(0, 1);
    }
    setHandicap(filtered);
  };

  return (
    <ScrollView contentContainerStyle={styles.scrollContainer} keyboardShouldPersistTaps="handled">
      <View style={styles.container}>
        {/* Golf bag image */}
        <Image
          source={require("../../assets/images/golfgamble_bag.png")}
          style={styles.image}
          resizeMode="contain"
        />
        {/* Form fields */}
        <View style={styles.form}>
          <Text style={styles.label}>Email Address</Text>
          <TextInput
            style={styles.input}
            value={email}
            onChangeText={setEmail}
            placeholder="email@example.com"
            autoCapitalize="none"
            keyboardType="email-address"
            returnKeyType="next"
          />
          <Text style={styles.label}>First Name</Text>
          <TextInput
            style={styles.input}
            value={firstName}
            onChangeText={setFirstName}
            placeholder="John"
            returnKeyType="next"
          />
          <Text style={styles.label}>Last Name</Text>
          <TextInput
            style={styles.input}
            value={lastName}
            onChangeText={setLastName}
            placeholder="Smith"
            returnKeyType="next"
          />
          <Text style={styles.label}>Password</Text>
          <TextInput
            style={styles.input}
            value={password}
            onChangeText={pw => { setPassword(pw); validatePassword(pw); }}
            placeholder="Minimum 8 characters"
            autoCapitalize="none"
            secureTextEntry
            returnKeyType="next"
          />
          {/* Password requirements */}
          <View style={{ marginBottom: 8 }}>
            <View style={{ flexDirection: "row", alignItems: "center" }}>
              <Text style={{ color: hasEightCharacters ? "green" : "red", marginRight: 4 }}>
                {hasEightCharacters ? "✓" : "✗"}
              </Text>
              <Text style={{ fontSize: 12 }}>Minimum 8 characters</Text>
            </View>
            <View style={{ flexDirection: "row", alignItems: "center" }}>
              <Text style={{ color: hasNumber ? "green" : "red", marginRight: 4 }}>
                {hasNumber ? "✓" : "✗"}
              </Text>
              <Text style={{ fontSize: 12 }}>Includes a number</Text>
            </View>
          </View>
          <Text style={styles.label}>Confirm Password</Text>
          <TextInput
            style={styles.input}
            value={confirmPassword}
            onChangeText={setConfirmPassword}
            placeholder="Re-Enter Password"
            autoCapitalize="none"
            secureTextEntry
            returnKeyType="done"
            onSubmitEditing={Keyboard.dismiss}
          />
          {/* Password match indicator */}
          {password.length > 0 && confirmPassword.length > 0 && (
            <Text style={{ color: password === confirmPassword ? "green" : "red", fontSize: 12, marginBottom: 8 }}>
              {password === confirmPassword ? "Passwords match" : "Passwords do not match"}
            </Text>
          )}
          <Text style={styles.label}>GHIN Number (optional)</Text>
          <TextInput
            style={styles.input}
            value={ghinNumber}
            onChangeText={setGhinNumber}
            placeholder="1234567"
            keyboardType="number-pad"
            returnKeyType="next"
          />
          <Text style={styles.label}>Handicap (optional)</Text>
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <TouchableOpacity
              style={[styles.plusToggle, plusHandicap && styles.plusToggleActive]}
              onPress={() => setPlusHandicap(v => !v)}
            >
              <Text style={{ color: plusHandicap ? '#fff' : '#007AFF', fontWeight: 'bold', fontSize: 18 }}>+</Text>
            </TouchableOpacity>
            <TextInput
              style={[styles.input, { flex: 1, marginLeft: 8 }]}
              value={handicap}
              onChangeText={handleHandicapChange}
              placeholder="12.3"
              keyboardType="decimal-pad"
              returnKeyType="done"
            />
          </View>
        </View>
        {/* Error message */}
        {!!error && <Text style={styles.error}>{error}</Text>}
        {/* Register button */}
        <TouchableOpacity
          style={[styles.button, { opacity: formIsValid ? 1 : 0.5 }]}
          onPress={handleRegister}
          disabled={!formIsValid || loading}
        >
          {loading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "center" }}>
              <Text style={styles.buttonText}>CREATE ACCOUNT</Text>
            </View>
          )}
        </TouchableOpacity>
        {/* Already have an account? */}
        <TouchableOpacity style={{ marginTop: 24 }} onPress={() => router.replace("/login")}> 
          <Text style={styles.signupText}>
            Already have an account? <Text style={{ fontWeight: "bold" }}>Sign In</Text>
          </Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scrollContainer: {
    flexGrow: 1,
    backgroundColor: "#fff",
  },
  container: {
    flex: 1,
    padding: 24,
    backgroundColor: "#fff",
    justifyContent: "center",
    alignItems: "center",
  },
  image: {
    width: 100,
    height: 170,
    borderRadius: 10,
    marginVertical: 32,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
  },
  form: {
    width: "100%",
    maxWidth: 350,
    marginTop: 12,
  },
  label: {
    fontWeight: "600",
    marginBottom: 4,
    marginTop: 12,
  },
  input: {
    borderWidth: 1,
    borderColor: "#ccc",
    borderRadius: 8,
    padding: 12,
    marginBottom: 8,
    fontSize: 16,
    backgroundColor: "#f9f9f9",
  },
  error: {
    color: "red",
    fontSize: 13,
    marginTop: 5,
  },
  button: {
    backgroundColor: "#007AFF",
    borderRadius: 10,
    height: 48,
    width: "100%",
    alignItems: "center",
    justifyContent: "center",
    marginTop: 24,
  },
  buttonText: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 18,
  },
  signupText: {
    fontSize: 14,
    color: "#333",
    textAlign: "center",
  },
  plusToggle: {
    width: 36,
    height: 36,
    borderRadius: 18,
    borderWidth: 2,
    borderColor: '#007AFF',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fff',
  },
  plusToggleActive: {
    backgroundColor: '#007AFF',
    borderColor: '#007AFF',
  },
}); 
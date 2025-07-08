import React, { useState } from "react";
import { View, Text, TextInput, TouchableOpacity, Image, Alert, StyleSheet, Keyboard, ActivityIndicator } from "react-native";
import { useAuth } from "../../hooks/useAuth";
import { useRouter } from "expo-router";

export default function LoginView() {
  const { login, resetPassword, error, setError, loading } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [resetting, setResetting] = useState(false);
  const router = useRouter();

  const formIsValid = email.includes("@") && email.length > 0 && password.length > 0;

  const handleLogin = async () => {
    setError(null);
    try {
      await login(email, password);
    } catch (err: any) {
      setError(err.message || "Login failed");
    }
  };

  const handleForgotPassword = async () => {
    setResetting(true);
    try {
      await resetPassword(email);
      Alert.alert(
        "Password Reset",
        "If an account exists for this email, a password reset link has been sent."
      );
    } catch {
      Alert.alert("Password Reset", "An error occurred. Please try again later.");
    } finally {
      setResetting(false);
    }
  };

  return (
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
          returnKeyType="done"
        />
        <Text style={styles.label}>Password</Text>
        <TextInput
          style={styles.input}
          value={password}
          onChangeText={setPassword}
          placeholder="Enter Password"
          autoCapitalize="none"
          secureTextEntry
          returnKeyType="done"
          onSubmitEditing={Keyboard.dismiss}
        />
        {/* Forgot Password */}
        <View style={{ alignItems: "flex-end", marginTop: 8 }}>
          <TouchableOpacity onPress={handleForgotPassword} disabled={resetting}>
            <Text style={styles.forgot}>Forgot Password?</Text>
          </TouchableOpacity>
        </View>
        {/* Error message */}
        {!!error && <Text style={styles.error}>{error}</Text>}
      </View>

      {/* Sign in button */}
      <TouchableOpacity
        style={[styles.button, { opacity: formIsValid ? 1 : 0.5 }]}
        onPress={handleLogin}
        disabled={!formIsValid || loading}
      >
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "center" }}>
            <Text style={styles.buttonText}>SIGN IN</Text>
          </View>
        )}
      </TouchableOpacity>

      {/* Sign up navigation */}
      <TouchableOpacity
        style={{ marginTop: 24 }}
        onPress={() => router.push("/registration")}
      >
        <Text style={styles.signupText}>
          Don't have an account? <Text style={{ fontWeight: "bold" }}>Sign Up</Text>
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
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
  forgot: {
    color: "#007AFF",
    fontSize: 14,
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
}); 
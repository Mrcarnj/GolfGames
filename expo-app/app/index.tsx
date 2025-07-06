import { useState } from "react";
import { View, Text, Alert, KeyboardAvoidingView, Platform, TouchableOpacity, useColorScheme, ScrollView, Image } from "react-native";
import { auth } from "../firebase";
import { createUserWithEmailAndPassword, signInWithEmailAndPassword, sendPasswordResetEmail } from "firebase/auth";
import InputView from "../components/InputView";
import PrimaryButton from "../components/PrimaryButton";
import SecondaryButton from "../components/SecondaryButton";
import Logo from "../components/Logo";
import { colors } from "../theme.js";
import * as Google from 'expo-auth-session/providers/google';
import * as WebBrowser from 'expo-web-browser';
import { signInWithGoogle } from '../authService';
import React from 'react';

WebBrowser.maybeCompleteAuthSession();

export default function Index() {
  const [mode, setMode] = useState<'signup' | 'signin'>("signin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [showReset, setShowReset] = useState(false);
  const colorScheme = useColorScheme();

  // Google Auth
  const [request, response, promptAsync] = Google.useAuthRequest({
    clientId: '64996444063-rlbepaoamu4801dfrlfa35oiasehucn7.apps.googleusercontent.com', // For Expo Go
    iosClientId: '<YOUR_IOS_CLIENT_ID>',      // (optional, for standalone iOS builds)
    androidClientId: '<YOUR_ANDROID_CLIENT_ID>', // (optional, for standalone Android builds)
    webClientId: '64996444063-rlbepaoamu4801dfrlfa35oiasehucn7.apps.googleusercontent.com', // (optional, for web)
  });

  // Password validation
  const hasEightCharacters = password.length >= 8;
  const hasNumber = /\d/.test(password);
  const passwordsMatch = password === confirmPassword;
  const isPasswordValid = hasEightCharacters && hasNumber;

  const formIsValid =
    email.includes("@") &&
    password.length >= 8 &&
    (mode === "signin" || (firstName && lastName && isPasswordValid && passwordsMatch));

  const handleAuth = async () => {
    setLoading(true);
    setError("");
    try {
      if (mode === "signup") {
        if (!isPasswordValid) throw new Error("Password must be at least 8 characters and include a number.");
        if (!passwordsMatch) throw new Error("Passwords do not match.");
        const cred = await createUserWithEmailAndPassword(auth, email, password);
        // Optionally save firstName/lastName to Firestore here
        Alert.alert("Sign up successful");
      } else {
        await signInWithEmailAndPassword(auth, email, password);
        Alert.alert("Sign in successful");
      }
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async () => {
    if (!email.includes("@")) {
      setError("Enter your email to reset password.");
      return;
    }
    try {
      await sendPasswordResetEmail(auth, email);
      Alert.alert("Password Reset", "If an account exists for this email, a reset link has been sent.");
    } catch (e: any) {
      setError(e.message);
    }
  };

  // Google sign-in effect
  React.useEffect(() => {
    if (response?.type === 'success') {
      setLoading(true);
      setError("");
      signInWithGoogle(response)
        .then(() => {
          Alert.alert("Google sign-in successful");
        })
        .catch((e) => {
          setError(e.message);
        })
        .finally(() => setLoading(false));
    }
  }, [response]);

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: colorScheme === 'dark' ? '#000' : colors.background }}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 24 }} keyboardShouldPersistTaps="handled">
        <Logo style={{}} />
        <View style={{ width: '100%', maxWidth: 350, alignSelf: 'center' }}>
          <InputView
            label="Email Address"
            value={email}
            onChangeText={setEmail}
            placeholder="name@example.com"
            keyboardType="email-address"
            autoCapitalize="none"
            validationIcon={undefined}
            validationColor={undefined}
            style={{}}
          />
          {mode === "signup" && (
            <>
              <InputView
                label="First Name"
                value={firstName}
                onChangeText={setFirstName}
                placeholder="John"
                autoCapitalize="words"
                validationIcon={undefined}
                validationColor={undefined}
                style={{}}
              />
              <InputView
                label="Last Name"
                value={lastName}
                onChangeText={setLastName}
                placeholder="Smith"
                autoCapitalize="words"
                validationIcon={undefined}
                validationColor={undefined}
                style={{}}
              />
            </>
          )}
          <InputView
            label="Password"
            value={password}
            onChangeText={setPassword}
            placeholder="Enter Password"
            secureTextEntry
            validationIcon={mode === "signup" ? (hasEightCharacters ? "checkmark-circle" : "close-circle") : undefined}
            validationColor={hasEightCharacters ? "green" : "red"}
            style={{}}
          />
          {mode === "signup" && (
            <>
              <InputView
                label="Confirm Password"
                value={confirmPassword}
                onChangeText={setConfirmPassword}
                placeholder="Re-Enter Password"
                secureTextEntry
                validationIcon={passwordsMatch ? "checkmark-circle" : "close-circle"}
                validationColor={passwordsMatch ? "green" : "red"}
                style={{}}
              />
              <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 8 }}>
                <Text style={{ fontSize: 12, color: hasEightCharacters ? 'green' : 'red', marginRight: 8 }}>
                  {hasEightCharacters ? '✓' : '✗'} Minimum 8 characters
                </Text>
                <Text style={{ fontSize: 12, color: hasNumber ? 'green' : 'red' }}>
                  {hasNumber ? '✓' : '✗'} Includes a number
                </Text>
              </View>
            </>
          )}
          <View style={{ flexDirection: 'row', justifyContent: 'flex-end', marginBottom: 8 }}>
            {mode === "signin" && (
              <TouchableOpacity onPress={handleForgotPassword}>
                <Text style={{ color: colors.primary, fontSize: 13 }}>Forgot Password?</Text>
              </TouchableOpacity>
            )}
          </View>
          {error ? (
            <Text style={{ color: colors.error, fontSize: 12, marginBottom: 8 }}>{error}</Text>
          ) : null}
          <PrimaryButton
            title={mode === "signup" ? "CREATE ACCOUNT" : "SIGN IN"}
            onPress={handleAuth}
            disabled={!formIsValid || loading}
            icon={null}
            style={{}}
            textColor="#fff"
          />
          {/* <PrimaryButton
            title="Sign in with Google"
            onPress={() => promptAsync()}
            disabled={!request || loading}
            icon={<Image source={require('../assets/google-logo.png')} style={{ width: 24, height: 24 }} />}
            iconPosition="left"
            style={{ backgroundColor: '#fff', borderWidth: 1, borderColor: '#ccc', marginTop: 8 }}
            textColor="#222"
          /> */}
          <SecondaryButton
            text={mode === "signup" ? "Already have an account?" : "Don't have an account?"}
            actionText={mode === "signup" ? "Sign In" : "Sign Up"}
            onPress={() => {
              setMode(mode === "signup" ? "signin" : "signup");
              setError("");
            }}
            style={{}}
          />
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

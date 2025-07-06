import React, { useState } from 'react';
import { View, Text, StyleSheet, Button, Switch, Alert } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';

export default function GameSelection() {
  const { golfers: golfersParam, courseName, selectedTees: selectedTeesParam } = useLocalSearchParams();
  const router = useRouter();
  const golfers = golfersParam ? JSON.parse(golfersParam) : [];
  const selectedTees = selectedTeesParam ? JSON.parse(selectedTeesParam) : {};

  const [isMatchPlay, setIsMatchPlay] = useState(false);
  const [isBetterBall, setIsBetterBall] = useState(false);
  const [isNinePoint, setIsNinePoint] = useState(false);
  const [isStablefordGross, setIsStablefordGross] = useState(false);
  const [isStablefordNet, setIsStablefordNet] = useState(false);

  const handleStartRound = () => {
    // TODO: Pass all selections to round start logic
    Alert.alert('Starting Round', JSON.stringify({
      golfers,
      selectedTees,
      games: { isMatchPlay, isBetterBall, isNinePoint, isStablefordGross, isStablefordNet },
    }, null, 2));
    // router.push({ pathname: '/Scorecard', params: { ... } });
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Game Selection</Text>
      <Text>Course: {courseName}</Text>
      <Text style={styles.label}>Available Games</Text>
      <View style={styles.gameRow}>
        <Text>Match Play</Text>
        <Switch value={isMatchPlay} onValueChange={setIsMatchPlay} />
      </View>
      <View style={styles.gameRow}>
        <Text>Better Ball</Text>
        <Switch value={isBetterBall} onValueChange={setIsBetterBall} />
      </View>
      <View style={styles.gameRow}>
        <Text>9 Point</Text>
        <Switch value={isNinePoint} onValueChange={setIsNinePoint} />
      </View>
      <View style={styles.gameRow}>
        <Text>Stableford Gross</Text>
        <Switch value={isStablefordGross} onValueChange={setIsStablefordGross} />
      </View>
      <View style={styles.gameRow}>
        <Text>Stableford Net</Text>
        <Switch value={isStablefordNet} onValueChange={setIsStablefordNet} />
      </View>
      <Button title="Start Round" onPress={handleStartRound} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 24,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'flex-start',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 24,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    marginTop: 16,
    marginBottom: 8,
  },
  gameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    width: '100%',
    marginBottom: 16,
  },
}); 
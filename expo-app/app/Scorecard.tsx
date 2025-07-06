import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TextInput, Button, Alert } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { db } from '../firebase';
import { collection, addDoc, Timestamp } from 'firebase/firestore';

const NUM_HOLES = 18;

export default function Scorecard() {
  const { golfers: golfersParam, selectedTees: selectedTeesParam, courseName, courseId, games: gamesParam } = useLocalSearchParams();
  const router = useRouter();
  const golfers = golfersParam ? JSON.parse(golfersParam) : [];
  const selectedTees = selectedTeesParam ? JSON.parse(selectedTeesParam) : {};
  const games = gamesParam ? JSON.parse(gamesParam) : {};

  // Initialize scores: { golferId: { 1: '', 2: '', ..., 18: '' } }
  const [scores, setScores] = useState(() => {
    const s = {};
    golfers.forEach(g => {
      s[g.id] = {};
      for (let h = 1; h <= NUM_HOLES; h++) s[g.id][h] = '';
    });
    return s;
  });
  const [saving, setSaving] = useState(false);

  const handleScoreChange = (golferId, hole, value) => {
    setScores(prev => ({
      ...prev,
      [golferId]: { ...prev[golferId], [hole]: value.replace(/[^0-9]/g, '') },
    }));
  };

  const handleSubmit = async () => {
    setSaving(true);
    try {
      const roundData = {
        courseId: courseId || '',
        courseName: courseName || '',
        golfers,
        selectedTees,
        games,
        scores,
        date: Timestamp.now(),
      };
      const docRef = await addDoc(collection(db, 'rounds'), roundData);
      Alert.alert('Round Saved', 'Your round has been saved.');
      router.replace({ pathname: '/RoundSummary', params: { roundId: docRef.id } });
    } catch (e) {
      Alert.alert('Error', e.message);
    }
    setSaving(false);
  };

  return (
    <ScrollView contentContainerStyle={styles.container} horizontal>
      <View>
        <Text style={styles.title}>Scorecard</Text>
        <Text>Course: {courseName}</Text>
        <ScrollView horizontal>
          <View style={styles.table}>
            <View style={styles.headerRow}>
              <Text style={styles.headerCell}>Hole</Text>
              {golfers.map(g => (
                <Text key={g.id} style={styles.headerCell}>{g.firstName}</Text>
              ))}
            </View>
            {[...Array(NUM_HOLES)].map((_, i) => (
              <View key={i + 1} style={styles.row}>
                <Text style={styles.cell}>{i + 1}</Text>
                {golfers.map(g => (
                  <TextInput
                    key={g.id}
                    style={styles.input}
                    value={scores[g.id][i + 1]}
                    onChangeText={v => handleScoreChange(g.id, i + 1, v)}
                    keyboardType="numeric"
                  />
                ))}
              </View>
            ))}
          </View>
        </ScrollView>
        <Button title={saving ? 'Saving...' : 'Save Round'} onPress={handleSubmit} disabled={saving} />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    padding: 24,
    backgroundColor: '#fff',
    alignItems: 'flex-start',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 24,
  },
  table: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    overflow: 'hidden',
  },
  headerRow: {
    flexDirection: 'row',
    backgroundColor: '#eee',
  },
  headerCell: {
    padding: 8,
    fontWeight: 'bold',
    minWidth: 70,
    textAlign: 'center',
  },
  row: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderColor: '#eee',
  },
  cell: {
    padding: 8,
    minWidth: 70,
    textAlign: 'center',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 4,
    padding: 4,
    minWidth: 50,
    margin: 2,
    textAlign: 'center',
  },
}); 
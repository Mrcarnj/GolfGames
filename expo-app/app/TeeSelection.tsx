import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Button, ScrollView, TouchableOpacity, ActivityIndicator, Alert } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { db } from '../firebase';
import { collection, getDocs } from 'firebase/firestore';

export default function TeeSelection() {
  const { courseId, courseName, golfers: golfersParam } = useLocalSearchParams();
  const router = useRouter();
  const golfers = golfersParam ? JSON.parse(golfersParam) : [];
  const [tees, setTees] = useState([]);
  const [selectedTees, setSelectedTees] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      setLoading(true);
      const snapshot = await getDocs(collection(db, 'courses', courseId, 'Tees'));
      const teesData = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setTees(teesData);
      // Default: assign first tee to all golfers
      const defaultTee = teesData[0]?.id;
      if (defaultTee) {
        const initial = {};
        golfers.forEach(g => { initial[g.id] = defaultTee; });
        setSelectedTees(initial);
      }
      setLoading(false);
    })();
  }, [courseId]);

  const handleTeeSelect = (golferId, teeId) => {
    setSelectedTees({ ...selectedTees, [golferId]: teeId });
  };

  const handleNext = () => {
    // TODO: Pass all selections to game selection or round start
    Alert.alert('Proceeding', JSON.stringify(selectedTees, null, 2));
    // router.push({ pathname: '/GameSelection', params: { ... } });
  };

  if (loading) return <ActivityIndicator style={{ flex: 1 }} size="large" />;

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Tee Selection</Text>
      <Text>Course: {courseName}</Text>
      {golfers.map(golfer => (
        <View key={golfer.id} style={styles.golferRow}>
          <Text style={styles.golferName}>{golfer.firstName} {golfer.lastName}</Text>
          <ScrollView horizontal style={styles.teeRow}>
            {tees.map(tee => (
              <TouchableOpacity
                key={tee.id}
                style={[styles.teeBtn, selectedTees[golfer.id] === tee.id && styles.selectedTee]}
                onPress={() => handleTeeSelect(golfer.id, tee.id)}
              >
                <Text>{tee.tee_name}</Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      ))}
      <Button title="Next: Game Selection / Start Round" onPress={handleNext} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    padding: 24,
    backgroundColor: '#fff',
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 24,
  },
  golferRow: {
    width: '100%',
    marginBottom: 20,
  },
  golferName: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
  },
  teeRow: {
    flexDirection: 'row',
    marginBottom: 8,
  },
  teeBtn: {
    padding: 10,
    borderRadius: 8,
    backgroundColor: '#eee',
    marginRight: 8,
  },
  selectedTee: {
    backgroundColor: '#cce6ff',
  },
}); 
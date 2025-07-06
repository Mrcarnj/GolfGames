import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, Button, ActivityIndicator, FlatList } from 'react-native';
import { useRouter } from 'expo-router';
import { db } from '../firebase';
import { collection, query, orderBy, limit, getDocs } from 'firebase/firestore';

export default function RecentRounds() {
  const router = useRouter();
  const [rounds, setRounds] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchRounds = async () => {
      setLoading(true);
      const q = query(collection(db, 'rounds'), orderBy('date', 'desc'), limit(10));
      const snapshot = await getDocs(q);
      setRounds(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    };
    fetchRounds();
  }, []);

  if (loading) {
    return <ActivityIndicator style={{ flex: 1 }} />;
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Recent Rounds</Text>
      <FlatList
        data={rounds}
        keyExtractor={item => item.id}
        renderItem={({ item }) => (
          <View style={styles.roundRow}>
            <Text style={styles.roundText}>{item.courseName} - {item.date?.toDate?.().toLocaleString?.() || ''}</Text>
            <Button title="View" onPress={() => router.push({ pathname: '/RoundSummary', params: { roundId: item.id } })} />
          </View>
        )}
        ListEmptyComponent={<Text>No rounds found.</Text>}
      />
      <Button title="Back" onPress={() => router.replace('/home')} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 24,
    backgroundColor: '#fff',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 24,
  },
  roundRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
    justifyContent: 'space-between',
  },
  roundText: {
    fontSize: 16,
    flex: 1,
  },
}); 
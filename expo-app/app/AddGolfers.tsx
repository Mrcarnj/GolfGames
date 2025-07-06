import React, { useState } from 'react';
import { View, Text, StyleSheet, Button, FlatList, TouchableOpacity, TextInput, Alert } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';

export default function AddGolfers() {
  const { courseId, courseName, teeId, teeName } = useLocalSearchParams();
  const router = useRouter();

  // For now, use a simple array of golfers. In the future, integrate with user/friends.
  const [golfers, setGolfers] = useState([
    { id: 'me', firstName: 'You', lastName: '', handicap: 0 },
  ]);
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [handicap, setHandicap] = useState('');

  const addGolfer = () => {
    if (!firstName.trim()) {
      Alert.alert('First name required');
      return;
    }
    setGolfers([...golfers, {
      id: Math.random().toString(36).substring(2, 10),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      handicap: parseFloat(handicap) || 0,
    }]);
    setFirstName('');
    setLastName('');
    setHandicap('');
  };

  const removeGolfer = (id) => {
    setGolfers(golfers.filter(g => g.id !== id));
  };

  const handleNext = () => {
    if (golfers.length === 0) {
      Alert.alert('Add at least one golfer');
      return;
    }
    // TODO: Pass golfers to next step (tee/game selection)
    Alert.alert('Proceeding', `Golfers: ${golfers.map(g => g.firstName).join(', ')}`);
    // router.push({ pathname: '/TeeSelection', params: { ... } });
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Add Golfers</Text>
      <Text>Course: {courseName}</Text>
      <Text>Tee: {teeName}</Text>
      <FlatList
        data={golfers}
        keyExtractor={item => item.id}
        renderItem={({ item }) => (
          <View style={styles.golferRow}>
            <Text>{item.firstName} {item.lastName} (HCP: {item.handicap})</Text>
            {item.id !== 'me' && (
              <TouchableOpacity onPress={() => removeGolfer(item.id)}>
                <Text style={styles.removeBtn}>Remove</Text>
              </TouchableOpacity>
            )}
          </View>
        )}
        ListEmptyComponent={<Text>No golfers added.</Text>}
        style={{ width: '100%', marginVertical: 16 }}
      />
      <View style={styles.addRow}>
        <TextInput
          style={styles.input}
          placeholder="First Name"
          value={firstName}
          onChangeText={setFirstName}
        />
        <TextInput
          style={styles.input}
          placeholder="Last Name"
          value={lastName}
          onChangeText={setLastName}
        />
        <TextInput
          style={styles.input}
          placeholder="Handicap"
          value={handicap}
          onChangeText={setHandicap}
          keyboardType="numeric"
        />
        <Button title="Add" onPress={addGolfer} />
      </View>
      <Button title="Next: Tee/Game Selection" onPress={handleNext} disabled={golfers.length === 0} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'flex-start',
    alignItems: 'center',
    backgroundColor: '#fff',
    padding: 24,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 24,
  },
  golferRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderColor: '#eee',
    width: '100%',
  },
  removeBtn: {
    color: 'red',
    marginLeft: 12,
  },
  addRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
    width: '100%',
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 6,
    padding: 8,
    marginRight: 8,
    width: 90,
  },
}); 
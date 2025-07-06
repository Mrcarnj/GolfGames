import React, { useEffect, useState } from 'react';
import { View, Text, Button, ActivityIndicator, ScrollView, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { useShared } from '../store/hooks';
import { useLocationStore } from '../store/locationStore';
import * as Location from 'expo-location';
import { db } from '../firebase';
import { collection, getDocs } from 'firebase/firestore';
import { useRouter } from 'expo-router';

// Firestore fetch functions
const fetchCourses = async () => {
  try {
    const snapshot = await getDocs(collection(db, 'courses'));
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    console.error('Error fetching courses:', e);
    return [];
  }
};

const fetchTees = async (courseId) => {
  try {
    const snapshot = await getDocs(collection(db, 'courses', courseId, 'Tees'));
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    console.error('Error fetching tees:', e);
    return [];
  }
};

export default function CourseSelection() {
  const [loading, setLoading] = useState(true);
  const [courses, setCourses] = useState([]);
  const [uniqueLocations, setUniqueLocations] = useState([]);
  const [filteredCourses, setFilteredCourses] = useState([]);
  const [tees, setTees] = useState([]);
  const [selectedLocation, setSelectedLocation] = useState(null);
  const [selectedCourse, setSelectedCourse] = useState(null);
  const [selectedTee, setSelectedTee] = useState(null);
  const [nearbyCourses, setNearbyCourses] = useState([]);
  const [locationLoading, setLocationLoading] = useState(false);
  const [locationError, setLocationError] = useState(null);
  const router = useRouter();

  // Fetch all courses on mount
  useEffect(() => {
    (async () => {
      setLoading(true);
      const allCourses = await fetchCourses();
      setCourses(allCourses);
      setUniqueLocations([...new Set(allCourses.map(c => c.location))].sort());
      setLoading(false);
    })();
  }, []);

  // Filter courses by selected location
  useEffect(() => {
    if (selectedLocation) {
      setFilteredCourses(courses.filter(c => c.location === selectedLocation));
      setSelectedCourse(null);
      setTees([]);
      setSelectedTee(null);
    } else {
      setFilteredCourses([]);
      setSelectedCourse(null);
      setTees([]);
      setSelectedTee(null);
    }
  }, [selectedLocation, courses]);

  // Fetch tees when course is selected
  useEffect(() => {
    if (selectedCourse) {
      (async () => {
        setTees([]);
        const tees = await fetchTees(selectedCourse.id);
        setTees(tees);
      })();
    }
  }, [selectedCourse]);

  // Get nearby courses using geolocation
  const handleFindNearby = async () => {
    setLocationLoading(true);
    setLocationError(null);
    try {
      let { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        setLocationError('Location permission not granted');
        setLocationLoading(false);
        return;
      }
      let loc = await Location.getCurrentPositionAsync({});
      const { latitude, longitude } = loc.coords;
      // Calculate distances and filter courses within 20 miles
      const coursesWithDistance = courses.map(course => {
        if (course.latitude && course.longitude) {
          const toRad = x => (x * Math.PI) / 180;
          const R = 3958.8; // miles
          const dLat = toRad(course.latitude - latitude);
          const dLon = toRad(course.longitude - longitude);
          const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(latitude)) * Math.cos(toRad(course.latitude)) * Math.sin(dLon / 2) ** 2;
          const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
          const distance = R * c;
          return { ...course, distance };
        }
        return { ...course, distance: null };
      });
      const nearby = coursesWithDistance.filter(c => c.distance !== null && c.distance <= 20).sort((a, b) => a.distance - b.distance);
      setNearbyCourses(nearby);
    } catch (e) {
      setLocationError(e.message);
    }
    setLocationLoading(false);
  };

  const handleNext = () => {
    if (selectedCourse && selectedTee) {
      router.push({
        pathname: '/AddGolfers',
        params: {
          courseId: selectedCourse.id,
          courseName: selectedCourse.name,
          teeId: selectedTee.id,
          teeName: selectedTee.tee_name,
        },
      });
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Single Round Setup</Text>
      {loading ? <ActivityIndicator size="large" /> : (
        <>
          {/* State Picker */}
          <Text style={styles.label}>Select a State</Text>
          <ScrollView horizontal style={styles.pickerRow}>
            {uniqueLocations.map(loc => (
              <TouchableOpacity key={loc} style={[styles.pickerItem, selectedLocation === loc && styles.selected]} onPress={() => setSelectedLocation(loc)}>
                <Text>{loc}</Text>
              </TouchableOpacity>
            ))}
          </ScrollView>

          {/* Course Picker */}
          {filteredCourses.length > 0 && (
            <>
              <Text style={styles.label}>Select a Course</Text>
              <ScrollView horizontal style={styles.pickerRow}>
                {filteredCourses.map(course => (
                  <TouchableOpacity key={course.id} style={[styles.pickerItem, selectedCourse?.id === course.id && styles.selected]} onPress={() => setSelectedCourse(course)}>
                    <Text>{course.name}</Text>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </>
          )}

          {/* Tee Picker */}
          {tees.length > 0 && (
            <>
              <Text style={styles.label}>Select a Tee</Text>
              <ScrollView horizontal style={styles.pickerRow}>
                {tees.map(tee => (
                  <TouchableOpacity key={tee.id} style={[styles.pickerItem, selectedTee?.id === tee.id && styles.selected]} onPress={() => setSelectedTee(tee)}>
                    <Text>{tee.tee_name}</Text>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </>
          )}

          {/* Nearby Courses */}
          <View style={styles.nearbySection}>
            <Text style={styles.label}>Nearby Courses</Text>
            <Button title="Find Nearby Courses" onPress={handleFindNearby} />
            {locationLoading && <ActivityIndicator size="small" />}
            {locationError && <Text style={styles.error}>{locationError}</Text>}
            <ScrollView horizontal style={styles.pickerRow}>
              {nearbyCourses.map(course => (
                <TouchableOpacity key={course.id} style={[styles.pickerItem, selectedCourse?.id === course.id && styles.selected]} onPress={() => setSelectedCourse(course)}>
                  <Text>{course.name} ({course.distance?.toFixed(1)} mi)</Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>

          {/* Next Button */}
          <Button title="Next" onPress={handleNext} disabled={!(selectedCourse && selectedTee)} />
        </>
      )}
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
    marginVertical: 24,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    marginTop: 16,
    marginBottom: 8,
  },
  pickerRow: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  pickerItem: {
    padding: 12,
    borderRadius: 8,
    backgroundColor: '#eee',
    marginRight: 8,
  },
  selected: {
    backgroundColor: '#cce6ff',
  },
  nearbySection: {
    marginTop: 24,
    width: '100%',
  },
  error: {
    color: 'red',
    marginTop: 4,
  },
}); 
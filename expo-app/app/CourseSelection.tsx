import React, { useEffect, useState } from 'react';
import { View, Text, Button, ActivityIndicator, ScrollView, TouchableOpacity, StyleSheet, Alert, TextInput } from 'react-native';
import { useShared, useSharedStore } from '../store/hooks';
import { useLocationStore } from '../store/locationStore';
import { db } from '../firebase';
import { collection, getDocs } from 'firebase/firestore';
import { useRouter } from 'expo-router';
import { getCurrentLocation, getDistanceMiles, getLastKnownLocation } from '../Utilities/locationService';

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
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState<'distance' | 'name'>('distance');
  const PAGE_SIZE = 20;
  const [page, setPage] = useState(0);
  const recentCourseSearches = useSharedStore((s) => s.recentCourseSearches);
  const setRecentCourseSearch = useSharedStore((s) => s.setRecentCourseSearch);

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

  // Filter and sort courses for display
  const getDisplayCourses = () => {
    let list = filteredCourses.length > 0 ? filteredCourses : courses;
    if (searchTerm.trim()) {
      list = list.filter(c => c.name.toLowerCase().includes(searchTerm.trim().toLowerCase()));
    }
    if (sortBy === 'distance') {
      list = [...list].sort((a, b) => {
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance - b.distance;
      });
    } else {
      list = [...list].sort((a, b) => a.name.localeCompare(b.name));
    }
    return list;
  };

  // Get nearby courses using geolocation
  const handleFindNearby = async () => {
    setLocationLoading(true);
    setLocationError(null);
    try {
      // Try to use cached location first
      let loc = getLastKnownLocation();
      if (!loc) {
        const freshLoc = await getCurrentLocation();
        if (!freshLoc) throw new Error('Unable to get location');
        loc = freshLoc;
      }
      const { latitude, longitude } = loc;
      // Calculate distances and filter courses within 20 miles
      const coursesWithDistance = courses.map(course => {
        if (course.latitude && course.longitude) {
          const distance = getDistanceMiles(latitude, longitude, course.latitude, course.longitude);
          return { ...course, distance };
        }
        return { ...course, distance: null };
      });
      const nearby = coursesWithDistance.filter(c => c.distance !== null && c.distance <= 20).sort((a, b) => a.distance - b.distance);
      setNearbyCourses(nearby);
    } catch (e: any) {
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

  // Handle search submit
  const handleSearchSubmit = () => {
    if (searchTerm.trim()) {
      setRecentCourseSearch(searchTerm);
      setPage(0);
    }
  };

  // Handle recent search click
  const handleRecentSearch = (term: string) => {
    setSearchTerm(term);
    setRecentCourseSearch(term);
    setPage(0);
  };

  // Get paginated, filtered, and sorted courses
  const displayCourses = getDisplayCourses();
  const totalPages = Math.ceil(displayCourses.length / PAGE_SIZE);
  const paginatedCourses = displayCourses.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE);

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Single Round Setup</Text>
      {/* Search Bar */}
      <TextInput
        style={styles.searchBar}
        placeholder="Search courses by name..."
        value={searchTerm}
        onChangeText={setSearchTerm}
        onEndEditing={handleSearchSubmit}
        returnKeyType="search"
      />
      {/* Recent Searches */}
      {recentCourseSearches.length > 0 && (
        <View style={styles.recentSearchesRow}>
          <Text style={{ marginRight: 8 }}>Recent:</Text>
          {recentCourseSearches.map(term => (
            <TouchableOpacity key={term} style={styles.recentChip} onPress={() => handleRecentSearch(term)}>
              <Text>{term}</Text>
            </TouchableOpacity>
          ))}
        </View>
      )}
      {/* Sort Toggle */}
      <View style={styles.sortRow}>
        <Text>Sort by:</Text>
        <Button
          title={sortBy === 'distance' ? 'Distance' : 'Name'}
          onPress={() => setSortBy(sortBy === 'distance' ? 'name' : 'distance')}
        />
      </View>
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

      {/* Display filtered and sorted courses */}
      <Text style={styles.label}>All Courses</Text>
      <ScrollView style={{ maxHeight: 200 }}>
        {paginatedCourses.map(course => (
          <TouchableOpacity
            key={course.id}
            style={[styles.pickerItem, selectedCourse?.id === course.id && styles.selected]}
            onPress={() => router.push({ pathname: '/CourseDetails', params: { courseId: course.id } })}
          >
            <Text>{course.name}{course.distance != null ? ` (${course.distance.toFixed(1)} mi)` : ''}</Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
      {/* Pagination Controls */}
      <View style={styles.paginationRow}>
        <Button title="Previous" onPress={() => setPage(p => Math.max(0, p - 1))} disabled={page === 0} />
        <Text style={styles.pageText}>{page + 1} / {Math.max(1, totalPages)}</Text>
        <Button title="Next" onPress={() => setPage(p => Math.min(totalPages - 1, p + 1))} disabled={page >= totalPages - 1} />
      </View>
      {/* Next Button */}
      <Button title="Next" onPress={handleNext} disabled={!(selectedCourse && selectedTee)} />
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
  searchBar: {
    width: '100%',
    padding: 10,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    marginBottom: 12,
    fontSize: 16,
  },
  sortRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
    gap: 8,
  },
  paginationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: 8,
    gap: 8,
  },
  pageText: {
    marginHorizontal: 12,
    fontSize: 16,
    fontWeight: 'bold',
  },
  recentSearchesRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    marginBottom: 8,
  },
  recentChip: {
    backgroundColor: '#e0e0e0',
    borderRadius: 16,
    paddingHorizontal: 12,
    paddingVertical: 4,
    marginRight: 6,
    marginBottom: 4,
  },
}); 
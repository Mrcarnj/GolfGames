import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  Button,
  ActivityIndicator,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Alert,
  TextInput,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useLocationStore } from "../store/locationStore";
import { db } from "../firebase";
import { collection, getDocs } from "firebase/firestore";
import { useRouter } from "expo-router";
import {
  getCurrentLocation,
  getLastKnownLocation,
} from "../Utilities/locationService";
import { useFavoritesStore } from "../store/favoritesStore";
import { Ionicons } from "@expo/vector-icons";

// Define Course type
interface Course {
  id: string;
  name: string;
  location: string;
  latitude?: number;
  longitude?: number;
}

// Utility to calculate distance between two lat/lng points in miles
function getDistanceMiles(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const toRad = (v: number) => (v * Math.PI) / 180;
  const R = 3958.8; // Earth radius in miles
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Firestore fetch functions
const fetchCourses = async () => {
  try {
    const snapshot = await getDocs(collection(db, "courses"));
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name || "",
        location: data.location || "",
        latitude: typeof data.latitude === "number" ? data.latitude : undefined,
        longitude: typeof data.longitude === "number" ? data.longitude : undefined,
      };
    });
  } catch (e) {
    console.error("Error fetching courses:", e);
    return [];
  }
};

const fetchTees = async (courseId: string) => {
  try {
    const snapshot = await getDocs(collection(db, "courses", courseId, "Tees"));
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    console.error("Error fetching tees:", e);
    return [];
  }
};

export default function CourseSelection() {
  const [loading, setLoading] = useState(true);
  const [courses, setCourses] = useState<Course[]>([]);
  const [uniqueLocations, setUniqueLocations] = useState<string[]>([]);
  const [filteredCourses, setFilteredCourses] = useState<Course[]>([]);
  const [tees, setTees] = useState<any[]>([]);
  const [selectedLocation, setSelectedLocation] = useState<string | null>(null);
  const [selectedCourse, setSelectedCourse] = useState<Course | null>(null);
  const [selectedTee, setSelectedTee] = useState<any | null>(null);
  const [locationLoading, setLocationLoading] = useState(false);
  const [locationError, setLocationError] = useState<string | null>(null);
  const router = useRouter();
  const [searchTerm, setSearchTerm] = useState("");
  const PAGE_SIZE = 20;
  const [page, setPage] = useState(0);
  const [tab, setTab] = useState<'all' | 'favorites'>('all');
  const { favoriteCourseIds, addFavorite, removeFavorite, isFavorite } = useFavoritesStore();
  // Type assertion fallback for location if needed
  const lastLocation = useLocationStore((state: any) => state.lastLocation) as { latitude: number; longitude: number } | null;
  // Remove setLocation if not used

  // Fetch all courses on mount
  useEffect(() => {
    (async () => {
      setLoading(true);
      const allCourses = await fetchCourses();
      setCourses(allCourses);
      setUniqueLocations(
        [...new Set(allCourses.map((c) => c.location))].sort(),
      );
      setLoading(false);
    })();
  }, []);

  // Filter courses by selected location
  useEffect(() => {
    if (selectedLocation) {
      setFilteredCourses(
        courses.filter((c) => c.location === selectedLocation),
      );
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
      list = list.filter((c) =>
        c.name.toLowerCase().includes(searchTerm.trim().toLowerCase()),
      );
    }
    // Only sort by name, not distance
    list = [...list].sort((a, b) => a.name.localeCompare(b.name));
    return list;
  };

  // Handle search submit
  const handleSearchSubmit = () => {
    if (searchTerm.trim()) {
      setPage(0);
    }
  };

  // Handle recent search click
  const handleRecentSearch = (term: string) => {
    setSearchTerm(term);
    setPage(0);
  };

  // Get paginated, filtered, and sorted courses
  const displayCourses = getDisplayCourses();
  const totalPages = Math.ceil(displayCourses.length / PAGE_SIZE);
  const paginatedCourses = displayCourses.slice(
    page * PAGE_SIZE,
    (page + 1) * PAGE_SIZE,
  );

  // Filter for favorites tab
  const filteredDisplayCourses = tab === 'favorites'
    ? getDisplayCourses().filter((c) => favoriteCourseIds.includes(c.id))
    : getDisplayCourses();

  // Pagination for filtered courses
  const paginatedFilteredCourses = filteredDisplayCourses.slice(
    page * PAGE_SIZE,
    (page + 1) * PAGE_SIZE,
  );

  // Build nearbyCourses array when lastLocation and allCourses are available
  const nearbyCourses: (Course & { distance: number })[] = React.useMemo(() => {
    if (!lastLocation || !Array.isArray(courses)) return [];
    return courses
      .filter(
        (course) =>
          typeof course.latitude === 'number' &&
          typeof course.longitude === 'number'
      )
      .map((course) => {
        const distance = getDistanceMiles(
          course.latitude as number,
          course.longitude as number,
          lastLocation.latitude,
          lastLocation.longitude
        );
        return { ...course, distance };
      })
      .filter((course) => course.distance <= 20)
      .sort((a, b) => a.distance - b.distance);
  }, [lastLocation, courses]);

  const handleNext = () => {
    if (selectedCourse && selectedTee) {
      router.push({
        pathname: "/AddGolfers",
        params: {
          courseId: selectedCourse.id,
          courseName: selectedCourse.name,
          teeId: selectedTee.id,
          teeName: selectedTee.tee_name,
        },
      });
    }
  };

  // Handler for Find Nearby Courses
  const handleFindNearby = async () => {
    setLocationLoading(true);
    setLocationError(null);
    try {
      const freshLoc = await getCurrentLocation();
      if (!freshLoc) throw new Error("Unable to get location");
      // Do not call setLocation here; getCurrentLocation already updates the store
    } catch (e: any) {
      setLocationError(e.message);
    }
    setLocationLoading(false);
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: '#f8f9fa' }}>
      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.tabRow}>
          <TouchableOpacity
            style={[styles.tabBtn, tab === 'all' && styles.tabBtnActive]}
            onPress={() => setTab('all')}
          >
            <Text style={[styles.tabText, tab === 'all' && styles.tabTextActive]}>All Courses</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.tabBtn, tab === 'favorites' && styles.tabBtnActive]}
            onPress={() => setTab('favorites')}
          >
            <Text style={[styles.tabText, tab === 'favorites' && styles.tabTextActive]}>Favorites</Text>
          </TouchableOpacity>
        </View>
        <TextInput
          style={styles.searchInput}
          placeholder="Search courses..."
          value={searchTerm}
          onChangeText={setSearchTerm}
          onSubmitEditing={handleSearchSubmit}
        />
        {/* Nearby Courses Section */}
        <View style={styles.nearbySection}>
          <Text style={styles.label}>Nearby Courses</Text>
          <Button title="Find Nearby Courses" onPress={handleFindNearby} />
          {locationLoading && <ActivityIndicator size="small" />}
          {locationError && <Text style={styles.error}>{locationError}</Text>}
          <ScrollView horizontal style={styles.pickerRow} showsHorizontalScrollIndicator={false}>
            {nearbyCourses.map((course, idx) => (
              <View
                key={course.id}
                style={[
                  styles.courseCard,
                  styles.nearbyCourseCard,
                  { 
                    marginLeft: idx === 0 ? 16 : 8,
                    marginRight: idx === nearbyCourses.length - 1 ? 16 : 8,
                  },
                ]}
              >
                <View style={styles.courseHeader}>
                  <Text style={styles.courseName}>{course.name}</Text>
                  <TouchableOpacity
                    onPress={() =>
                      isFavorite(course.id)
                        ? removeFavorite(course.id)
                        : addFavorite(course.id)
                    }
                    hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                  >
                    <Ionicons
                      name={isFavorite(course.id) ? "star" : "star-outline"}
                      size={28}
                      color={isFavorite(course.id) ? "#FFD700" : "#bbb"}
                    />
                  </TouchableOpacity>
                </View>
                <Text style={styles.distanceText}>{`${course.distance.toFixed(1)} mi away`}</Text>
                <Text style={styles.courseLocation}>{course.location}</Text>
                <TouchableOpacity
                  style={styles.selectBtn}
                  onPress={() => {
                    setSelectedCourse(course);
                    setSelectedTee(null);
                  }}
                >
                  <Text style={styles.selectBtnText}>View Details</Text>
                </TouchableOpacity>
              </View>
            ))}
          </ScrollView>
        </View>
        {/* Add margin below nearbySection for separation */}
        <View style={{ height: 20 }} />
        {filteredDisplayCourses.length === 0 && (
          <Text style={styles.emptyText}>
            {tab === 'favorites' ? 'No favorite courses yet.' : 'No courses found.'}
          </Text>
        )}
        {paginatedFilteredCourses.map((course) => (
          <View key={course.id} style={styles.courseCard}>
            <View style={styles.courseHeader}>
              <Text style={styles.courseName}>{course.name}</Text>
              <TouchableOpacity
                onPress={() =>
                  isFavorite(course.id)
                    ? removeFavorite(course.id)
                    : addFavorite(course.id)
                }
                hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
              >
                <Ionicons
                  name={isFavorite(course.id) ? "star" : "star-outline"}
                  size={28}
                  color={isFavorite(course.id) ? "#FFD700" : "#bbb"}
                />
              </TouchableOpacity>
            </View>
            <Text style={styles.courseLocation}>{course.location}</Text>
            <TouchableOpacity
              style={styles.selectBtn}
              onPress={() => {
                setSelectedCourse(course);
                setSelectedTee(null);
              }}
            >
              <Text style={styles.selectBtnText}>View Details</Text>
            </TouchableOpacity>
          </View>
        ))}
        {/* Pagination Controls */}
        <View style={styles.paginationRow}>
          <Button
            title="Previous"
            onPress={() => setPage((p) => Math.max(0, p - 1))}
            disabled={page === 0}
          />
          <Text style={styles.pageText}>
            {page + 1} / {Math.max(1, totalPages)}
          </Text>
          <Button
            title="Next"
            onPress={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
            disabled={page >= totalPages - 1}
          />
        </View>
        {/* Next Button */}
        <Button
          title="Next"
          onPress={handleNext}
          disabled={!(selectedCourse && selectedTee)}
        />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    padding: 20,
    backgroundColor: '#f8f9fa',
  },
  tabRow: {
    flexDirection: 'row',
    marginBottom: 16,
    borderRadius: 10,
    backgroundColor: '#f2f2f7',
    overflow: 'hidden',
  },
  tabBtn: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    backgroundColor: '#f2f2f7',
  },
  tabBtnActive: {
    backgroundColor: '#007aff',
  },
  tabText: {
    color: '#444',
    fontWeight: '600',
    fontSize: 16,
  },
  tabTextActive: {
    color: '#fff',
    fontWeight: 'bold',
  },
  searchInput: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#d1d1d6',
  },
  emptyText: {
    textAlign: 'center',
    color: '#888',
    marginVertical: 32,
    fontSize: 16,
  },
  courseCard: {
    backgroundColor: '#fff',
    borderRadius: 14,
    padding: 18,
    marginBottom: 18,
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    borderWidth: 1,
    borderColor: '#d1d1d6',
  },
  courseHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  courseName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#222',
  },
  courseLocation: {
    fontSize: 15,
    color: '#666',
    marginBottom: 10,
  },
  selectBtn: {
    marginTop: 8,
    backgroundColor: '#20b2aa',
    borderRadius: 8,
    paddingVertical: 10,
    alignItems: 'center',
  },
  selectBtnText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 15,
  },
  paginationRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    marginVertical: 8,
    gap: 8,
  },
  pageText: {
    marginHorizontal: 12,
    fontSize: 16,
    fontWeight: "bold",
  },
  nearbySection: {
    marginTop: 20,
    paddingVertical: 15,
    backgroundColor: '#fff',
    borderRadius: 14,
    shadowColor: '#000',
    shadowOpacity: 0.06,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    borderWidth: 1,
    borderColor: '#d1d1d6',
    marginBottom: 8, // add margin below the section
  },
  label: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#222',
    marginBottom: 10,
    paddingHorizontal: 10,
  },
  error: {
    color: 'red',
    textAlign: 'center',
    marginBottom: 10,
    paddingHorizontal: 10,
  },
  pickerRow: {
    paddingHorizontal: 0,
    flexDirection: 'row',
  },
  nearbyCourseCard: {
    minWidth: 220,
    maxWidth: 260,
    marginVertical: 8,
  },
  distanceText: {
    fontSize: 13,
    color: '#888',
    marginBottom: 2,
    marginLeft: 2,
  },
});

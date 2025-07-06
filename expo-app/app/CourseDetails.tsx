import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ActivityIndicator, ScrollView, TouchableOpacity, Button } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { db } from '../firebase';
import { doc, getDoc, collection, getDocs } from 'firebase/firestore';
import { useSharedStore } from '../store/hooks';

function ExpandableSection({ title, children }: { title: string; children: React.ReactNode }) {
  const [expanded, setExpanded] = useState(false);
  return (
    <View style={styles.expandableSection}>
      <TouchableOpacity onPress={() => setExpanded(e => !e)} style={styles.expandableHeader}>
        <Text style={styles.expandableTitle}>{title}</Text>
        <Text>{expanded ? '▲' : '▼'}</Text>
      </TouchableOpacity>
      {expanded && <View style={styles.expandableContent}>{children}</View>}
    </View>
  );
}

export default function CourseDetails() {
  const { courseId } = useLocalSearchParams();
  const router = useRouter();
  const [course, setCourse] = useState(null);
  const [tees, setTees] = useState([]);
  const [selectedTee, setSelectedTee] = useState(null);
  const [loading, setLoading] = useState(true);
  const favorites = useSharedStore(s => s.favorites);
  const addFavorite = useSharedStore(s => s.addFavorite);
  const removeFavorite = useSharedStore(s => s.removeFavorite);

  useEffect(() => {
    const fetchCourse = async () => {
      setLoading(true);
      if (!courseId) return;
      const courseDoc = await getDoc(doc(db, 'courses', courseId));
      if (courseDoc.exists()) {
        setCourse({ id: courseDoc.id, ...courseDoc.data() });
      }
      // Fetch tees for this course
      const teesSnap = await getDocs(collection(db, 'courses', courseId, 'tees'));
      setTees(teesSnap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    };
    fetchCourse();
  }, [courseId]);

  const isFavorited = selectedTee && favorites.some(f => f.courseId === courseId && f.teeId === selectedTee.id);
  const handleToggleFavorite = () => {
    if (!selectedTee) return;
    if (isFavorited) {
      removeFavorite(courseId, selectedTee.id);
    } else {
      addFavorite(courseId, course.name, selectedTee.id, selectedTee.tee_name);
    }
  };

  if (loading) {
    return <ActivityIndicator style={{ flex: 1 }} />;
  }
  if (!course) {
    return <View style={styles.container}><Text>Course not found.</Text></View>;
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>{course.name}</Text>
      <Text style={styles.subtitle}>{course.location}</Text>
      <Text>Rating: {course.rating || 'N/A'} | Slope: {course.slope || 'N/A'} | Par: {course.par || 'N/A'}</Text>
      {/* Tees */}
      <Text style={styles.section}>Tees</Text>
      <ScrollView horizontal style={styles.teeRow}>
        {tees.map(tee => (
          <TouchableOpacity
            key={tee.id}
            style={[styles.teeChip, selectedTee?.id === tee.id && styles.selectedTee]}
            onPress={() => setSelectedTee(tee)}
          >
            <Text>{tee.tee_name} ({tee.yardage} yds)</Text>
          </TouchableOpacity>
        ))}
        {/* Favorite button for selected tee */}
        {selectedTee && (
          <TouchableOpacity style={styles.favoriteBtn} onPress={handleToggleFavorite}>
            <Text style={{ fontSize: 24, color: isFavorited ? '#FFD700' : '#bbb' }}>{isFavorited ? '★' : '☆'}</Text>
          </TouchableOpacity>
        )}
      </ScrollView>
      {/* Expandable sections */}
      <ExpandableSection title="Course Statistics">
        <Text>Holes: {course.holes || 'N/A'}</Text>
        <Text>Par: {course.par || 'N/A'}</Text>
        <Text>Rating: {course.rating || 'N/A'}</Text>
        <Text>Slope: {course.slope || 'N/A'}</Text>
      </ExpandableSection>
      <ExpandableSection title="Photos">
        <Text>Photo gallery coming soon.</Text>
      </ExpandableSection>
      <ExpandableSection title="Amenities">
        <Text>Amenities info coming soon.</Text>
      </ExpandableSection>
      <ExpandableSection title="Map">
        <Text>Map integration coming soon.</Text>
      </ExpandableSection>
      {/* Proceed button */}
      <Button title="Next" onPress={() => router.push({ pathname: '/AddGolfers', params: { courseId: course.id, courseName: course.name, teeId: selectedTee?.id, teeName: selectedTee?.tee_name } })} disabled={!selectedTee} />
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
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 12,
  },
  section: {
    marginTop: 16,
    fontWeight: 'bold',
    fontSize: 18,
  },
  teeRow: {
    flexDirection: 'row',
    marginVertical: 8,
  },
  teeChip: {
    backgroundColor: '#e0e0e0',
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 8,
    marginRight: 8,
  },
  selectedTee: {
    backgroundColor: '#cce6ff',
  },
  expandableSection: {
    width: '100%',
    marginTop: 16,
    borderWidth: 1,
    borderColor: '#eee',
    borderRadius: 8,
    overflow: 'hidden',
    backgroundColor: '#fafbfc',
  },
  expandableHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 12,
    backgroundColor: '#f0f4f8',
  },
  expandableTitle: {
    fontWeight: 'bold',
    fontSize: 16,
  },
  expandableContent: {
    padding: 12,
    borderTopWidth: 1,
    borderTopColor: '#eee',
  },
  favoriteBtn: {
    marginLeft: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
}); 
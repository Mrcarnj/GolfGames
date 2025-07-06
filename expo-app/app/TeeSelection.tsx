import React, { useEffect, useState, useMemo } from "react";
import {
  View,
  Text,
  StyleSheet,
  Button,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  Platform,
} from "react-native";
import { useRouter, useLocalSearchParams } from "expo-router";
import { db } from "../firebase";
import { collection, getDocs } from "firebase/firestore";
import { useRoundStore } from "../store/roundStore";
import { Golfer } from "../types/Golfer";

const COLORS = {
  background: "#f8f9fa",
  primary: "#007aff", // systemBlue
  secondary: "#20b2aa", // systemTeal
  gray: "#f2f2f7", // systemGray6
  grayBorder: "#d1d1d6", // systemGray4
  text: "#222",
  label: "#444",
  white: "#fff",
  error: "#d32f2f",
};

const ROUND_TYPES = [
  { label: "18 Holes", value: "full18" },
  { label: "Front 9", value: "front9" },
  { label: "Back 9", value: "back9" },
];

function getAvailableStartingHoles(roundType: string) {
  if (roundType === "full18") return Array.from({ length: 18 }, (_, i) => i + 1);
  if (roundType === "front9") return Array.from({ length: 9 }, (_, i) => i + 1);
  if (roundType === "back9") return Array.from({ length: 9 }, (_, i) => i + 10);
  return [1];
}

function calculateCourseHandicap(handicapIndex: number, slope: number, rating: number, par: number) {
  // Mimic USGA formula: (Handicap Index * Slope / 113) + (Rating - Par)
  return Math.round(handicapIndex * (slope / 113) + (rating - par));
}

export default function TeeSelection() {
  const { golfers: golfersParam, courseId, courseName } = useLocalSearchParams();
  const router = useRouter();
  const { setGolfers } = useRoundStore();
  const golfers: Golfer[] = golfersParam ? JSON.parse(golfersParam as string) : [];
  const [tees, setTees] = useState<any[]>([]);
  const [selectedTees, setSelectedTees] = useState<{ [golferId: string]: string }>({});
  const [courseHandicaps, setCourseHandicaps] = useState<{ [golferId: string]: number }>({});
  const [roundType, setRoundType] = useState("full18");
  const [startingHole, setStartingHole] = useState(1);
  const [loading, setLoading] = useState(true);
  const [showGames, setShowGames] = useState(false);

  useEffect(() => {
    (async () => {
      setLoading(true);
      const snapshot = await getDocs(collection(db, "courses", courseId as string, "Tees"));
      const teesData = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
      setTees(teesData);
      // Default: assign first tee to all golfers
      const defaultTee = teesData[0]?.id;
      if (defaultTee) {
        const initialTees: { [golferId: string]: string } = {};
        const initialHandicaps: { [golferId: string]: number } = {};
        golfers.forEach((g) => {
          initialTees[g.id] = defaultTee;
          initialHandicaps[g.id] = calculateCourseHandicap(g.handicap, teesData[0].slope_rating, teesData[0].course_rating, teesData[0].course_par);
        });
        setSelectedTees(initialTees);
        setCourseHandicaps(initialHandicaps);
      }
      setLoading(false);
    })();
  }, [courseId]);

  const availableStartingHoles = useMemo(() => getAvailableStartingHoles(roundType), [roundType]);

  const handleTeeSelect = (golferId: string, teeId: string) => {
    setSelectedTees((prev) => ({ ...prev, [golferId]: teeId }));
    const tee = tees.find((t) => t.id === teeId);
    const golfer = golfers.find((g) => g.id === golferId);
    if (tee && golfer) {
      setCourseHandicaps((prev) => ({
        ...prev,
        [golferId]: calculateCourseHandicap(golfer.handicap, tee.slope_rating, tee.course_rating, tee.course_par),
      }));
    }
  };

  const allTeesSelected = golfers.every((g) => selectedTees[g.id]);

  const handleBeginRound = () => {
    if (!allTeesSelected) {
      Alert.alert("Error", "Please select a tee for every golfer.");
      return;
    }
    setGolfers(
      golfers.map((g) => ({
        ...g,
        teeId: selectedTees[g.id],
        courseHandicap: courseHandicaps[g.id],
      }))
    );
    Alert.alert(
      "Round Ready",
      `Golfers: ${JSON.stringify(
        golfers.map((g) => ({
          ...g,
          teeId: selectedTees[g.id],
          courseHandicap: courseHandicaps[g.id],
        })),
        null,
        2
      )}\nRound Type: ${roundType}\nStarting Hole: ${startingHole}`
    );
    // router.push("/Scorecard");
  };

  if (loading) return <ActivityIndicator style={{ flex: 1 }} size="large" color={COLORS.primary} />;

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Tee Selection</Text>
      <Text style={styles.courseName}>Course: {courseName}</Text>
      {/* Round Type Segmented Control */}
      <View style={styles.segmentedRow}>
        {ROUND_TYPES.map((rt) => (
          <TouchableOpacity
            key={rt.value}
            style={[styles.segmentedBtn, roundType === rt.value && styles.segmentedBtnSelected]}
            onPress={() => setRoundType(rt.value)}
            activeOpacity={0.8}
          >
            <Text style={[styles.segmentedText, roundType === rt.value && styles.segmentedTextSelected]}>{rt.label}</Text>
          </TouchableOpacity>
        ))}
      </View>
      {/* Starting Hole Picker */}
      <View style={styles.pickerRow}>
        <Text style={styles.label}>Starting Hole:</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginLeft: 8 }}>
          {availableStartingHoles.map((hole) => (
            <TouchableOpacity
              key={hole}
              style={[styles.holeBtn, startingHole === hole && styles.selectedHole]}
              onPress={() => setStartingHole(hole)}
              activeOpacity={0.8}
            >
              <Text style={[styles.holeText, startingHole === hole && styles.selectedHoleText]}>{hole}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>
      {/* Golfers and Tee Pickers */}
      {golfers.map((golfer) => (
        <View key={golfer.id} style={styles.golferCard}>
          <View style={styles.golferHeader}>
            <Text style={styles.golferName}>{golfer.firstName} {golfer.lastName}</Text>
            <Text style={styles.golferHcp}>HCP: <Text style={styles.golferHcpNum}>{golfer.handicap}</Text></Text>
          </View>
          <ScrollView horizontal style={styles.teeRow} showsHorizontalScrollIndicator={false}>
            {tees.map((tee) => (
              <TouchableOpacity
                key={tee.id}
                style={[
                  styles.teeBtn,
                  selectedTees[golfer.id] === tee.id && styles.selectedTee,
                ]}
                onPress={() => handleTeeSelect(golfer.id, tee.id)}
                activeOpacity={0.8}
              >
                <Text style={styles.teeText}>
                  {tee.tee_name} {tee.tee_yards}yds ({tee.course_rating}/{tee.slope_rating}) Par {tee.course_par}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
          <Text style={styles.courseHandicapLabel}>Course Handicap: <Text style={styles.courseHandicapNum}>{courseHandicaps[golfer.id] ?? "-"}</Text></Text>
        </View>
      ))}
      {/* Add Games Button (stub) */}
      {golfers.length > 1 && (
        <TouchableOpacity style={styles.gamesBtn} onPress={() => setShowGames(true)} activeOpacity={0.85}>
          <Text style={styles.gamesBtnText}>Add Games</Text>
        </TouchableOpacity>
      )}
      {/* Begin Round Button */}
      <TouchableOpacity
        style={[styles.beginBtn, !allTeesSelected && styles.beginBtnDisabled]}
        onPress={handleBeginRound}
        disabled={!allTeesSelected}
        activeOpacity={0.85}
      >
        <Text style={styles.beginBtnText}>Begin Round</Text>
      </TouchableOpacity>
      {/* Game Selection Modal (stub) */}
      {/* {showGames && <GameSelectionModal onClose={() => setShowGames(false)} />} */}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    padding: 24,
    backgroundColor: COLORS.background,
    alignItems: "center",
  },
  title: {
    fontSize: 28,
    fontWeight: "bold",
    marginBottom: 12,
    color: COLORS.primary,
    letterSpacing: 0.5,
  },
  courseName: {
    fontSize: 16,
    color: COLORS.label,
    marginBottom: 18,
    fontWeight: "600",
  },
  segmentedRow: {
    flexDirection: "row",
    backgroundColor: COLORS.gray,
    borderRadius: 10,
    marginBottom: 18,
    overflow: "hidden",
  },
  segmentedBtn: {
    flex: 1,
    paddingVertical: 10,
    paddingHorizontal: 18,
    alignItems: "center",
    backgroundColor: COLORS.gray,
  },
  segmentedBtnSelected: {
    backgroundColor: COLORS.primary,
  },
  segmentedText: {
    color: COLORS.label,
    fontWeight: "600",
    fontSize: 15,
  },
  segmentedTextSelected: {
    color: COLORS.white,
    fontWeight: "bold",
  },
  pickerRow: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 18,
    width: "100%",
  },
  label: {
    fontSize: 15,
    color: COLORS.label,
    fontWeight: "600",
  },
  holeBtn: {
    paddingVertical: 7,
    paddingHorizontal: 16,
    borderRadius: 8,
    backgroundColor: COLORS.gray,
    marginRight: 8,
    borderWidth: 1,
    borderColor: COLORS.grayBorder,
  },
  selectedHole: {
    backgroundColor: COLORS.primary,
    borderColor: COLORS.primary,
  },
  holeText: {
    color: COLORS.label,
    fontWeight: "600",
    fontSize: 15,
  },
  selectedHoleText: {
    color: COLORS.white,
    fontWeight: "bold",
  },
  golferCard: {
    width: "100%",
    backgroundColor: COLORS.white,
    borderRadius: 14,
    padding: 16,
    marginBottom: 18,
    shadowColor: "#000",
    shadowOpacity: 0.06,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    borderWidth: 1,
    borderColor: COLORS.grayBorder,
  },
  golferHeader: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 8,
    justifyContent: "space-between",
  },
  golferName: {
    fontSize: 17,
    fontWeight: "bold",
    color: COLORS.text,
    letterSpacing: 0.2,
  },
  golferHcp: {
    fontSize: 15,
    color: COLORS.label,
    fontWeight: "600",
  },
  golferHcpNum: {
    color: COLORS.primary,
    fontWeight: "bold",
  },
  teeRow: {
    flexDirection: "row",
    marginBottom: 8,
  },
  teeBtn: {
    paddingVertical: 8,
    paddingHorizontal: 14,
    borderRadius: 8,
    backgroundColor: COLORS.gray,
    marginRight: 8,
    borderWidth: 1,
    borderColor: COLORS.grayBorder,
  },
  selectedTee: {
    backgroundColor: COLORS.primary,
    borderColor: COLORS.primary,
  },
  teeText: {
    color: COLORS.label,
    fontWeight: "600",
    fontSize: 14,
  },
  courseHandicapLabel: {
    fontSize: 15,
    color: COLORS.label,
    fontWeight: "600",
    marginTop: 2,
  },
  courseHandicapNum: {
    color: COLORS.secondary,
    fontWeight: "bold",
    fontSize: 15,
  },
  gamesBtn: {
    width: "100%",
    backgroundColor: COLORS.primary,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: "center",
    marginBottom: 18,
    shadowColor: "#007aff",
    shadowOpacity: 0.08,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
  },
  gamesBtnText: {
    color: COLORS.white,
    fontWeight: "bold",
    fontSize: 16,
    letterSpacing: 0.5,
  },
  beginBtn: {
    width: "100%",
    backgroundColor: COLORS.secondary,
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: "center",
    marginBottom: 24,
    shadowColor: "#20b2aa",
    shadowOpacity: 0.09,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
  },
  beginBtnDisabled: {
    backgroundColor: COLORS.gray,
    opacity: 0.6,
  },
  beginBtnText: {
    color: COLORS.white,
    fontWeight: "bold",
    fontSize: 18,
    letterSpacing: 0.5,
  },
});

import { useState, useEffect, useCallback } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebase";
import { useAuth } from "../store/hooks";
import { Golfer } from "../types/Golfer";

export function useFriends() {
  const { userSession } = useAuth();
  const [friends, setFriends] = useState<Golfer[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchFriends = useCallback(async () => {
    if (!userSession?.uid) return;
    setLoading(true);
    try {
      const q = collection(db, "users", userSession.uid, "friends");
      const snapshot = await getDocs(q);
      const friendsList = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })) as Golfer[];
      setFriends(friendsList);
    } catch (e) {
      console.error("Error fetching friends:", e);
    } finally {
      setLoading(false);
    }
  }, [userSession?.uid]);

  useEffect(() => {
    fetchFriends();
  }, [fetchFriends]);

  return { friends, loading, fetchFriends };
}

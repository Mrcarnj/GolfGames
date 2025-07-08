// useFriends.ts
// React hook for managing friends data, mimicking Swift FriendsViewModel

import { useState, useCallback } from 'react';
import type { Golfer } from '../models/Golfer';

// Placeholder for Firestore/database logic
// import { firestore } from '../firebase';

export function useFriends(initialUserId?: string) {
  const [friends, setFriends] = useState<Golfer[]>([]);
  const [userId, setUserId] = useState<string | undefined>(initialUserId);

  // --- Fetch friends ---
  const fetchFriends = useCallback((completion?: () => void) => {
    if (!userId) return;
    // TODO: Replace with Firestore/database logic
    // For now, mock fetch
    // setFriends([...]);
    if (completion) completion();
  }, [userId]);

  // --- Sort friends ---
  const sortFriends = useCallback(() => {
    setFriends(prev =>
      [...prev].sort((a, b) => {
        const name1 = a.lastName.toLowerCase();
        const name2 = b.lastName.toLowerCase();
        if (name1 < name2) return -1;
        if (name1 > name2) return 1;
        return a.firstName.toLowerCase() < b.firstName.toLowerCase() ? -1 : 1;
      })
    );
  }, []);

  // --- Add friend ---
  const addFriend = useCallback((firstName: string, lastName: string, ghinNumber: number | undefined, handicap: number, completion: (result: { success: boolean; error?: Error }) => void) => {
    if (!userId) {
      completion({ success: false, error: new Error('User ID not set') });
      return;
    }
    // TODO: Replace with Firestore/database logic
    const newFriend: Golfer = {
      id: Math.random().toString(36).substr(2, 9),
      firstName,
      lastName,
      handicap,
      ghinNumber,
      isChecked: false,
    };
    setFriends(prev => {
      const updated = [...prev, newFriend];
      return updated.sort((a, b) => a.lastName.localeCompare(b.lastName));
    });
    completion({ success: true });
  }, [userId]);

  // --- Remove friend ---
  const removeFriend = useCallback((friend: Golfer) => {
    if (!userId) return;
    // TODO: Replace with Firestore/database logic
    setFriends(prev => prev.filter(f => f.id !== friend.id));
  }, [userId]);

  // --- Update friend ---
  const updateFriend = useCallback((friend: Golfer, firstName: string, lastName: string, ghinNumber: number | undefined, handicap: number, completion: (result: { success: boolean; error?: Error }) => void) => {
    if (!userId) {
      completion({ success: false, error: new Error('User ID not set') });
      return;
    }
    // TODO: Replace with Firestore/database logic
    setFriends(prev => {
      const updated = prev.map(f =>
        f.id === friend.id
          ? { ...f, firstName, lastName, ghinNumber, handicap }
          : f
      );
      return updated.sort((a, b) => a.lastName.localeCompare(b.lastName));
    });
    completion({ success: true });
  }, [userId]);

  // --- Set userId and refetch friends ---
  const setAndFetchUserId = useCallback((id: string) => {
    setUserId(id);
    fetchFriends();
  }, [fetchFriends]);

  return {
    friends,
    userId,
    setUserId: setAndFetchUserId,
    fetchFriends,
    addFriend,
    removeFriend,
    updateFriend,
    sortFriends,
  };
} 
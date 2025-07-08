import { useState, useEffect, useCallback } from 'react';
import * as Location from 'expo-location';

export type LocationStatus = 'granted' | 'denied' | 'undetermined' | 'restricted' | 'error';

export interface UseLocationResult {
  location: Location.LocationObject | null;
  status: LocationStatus;
  isLocationAvailable: boolean;
  error: string | null;
  refresh: () => Promise<void>;
}

/**
 * Custom hook to manage location permissions and fetch the user's current location using expo-location.
 * Mimics the behavior of the Swift LocationManager class.
 */
export function useLocation(): UseLocationResult {
  const [location, setLocation] = useState<Location.LocationObject | null>(null);
  const [status, setStatus] = useState<LocationStatus>('undetermined');
  const [isLocationAvailable, setIsLocationAvailable] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const checkAndRequestPermission = useCallback(async () => {
    try {
      const { status: permissionStatus } = await Location.requestForegroundPermissionsAsync();
      if (permissionStatus === 'granted') {
        setStatus('granted');
        setIsLocationAvailable(true);
      } else if (permissionStatus === 'denied') {
        setStatus('denied');
        setIsLocationAvailable(false);
        setError('Location permission denied');
      } else {
        setStatus('undetermined');
        setIsLocationAvailable(false);
      }
    } catch (e: any) {
      setStatus('error');
      setIsLocationAvailable(false);
      setError(e.message || 'Unknown error requesting location permission');
    }
  }, []);

  const getLocation = useCallback(async () => {
    try {
      await checkAndRequestPermission();
      if (status === 'granted') {
        const loc = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.BestForNavigation });
        setLocation(loc);
        setIsLocationAvailable(true);
        setError(null);
      }
    } catch (e: any) {
      setError(e.message || 'Error getting location');
      setIsLocationAvailable(false);
    }
  }, [checkAndRequestPermission, status]);

  // Initial effect to get location on mount
  useEffect(() => {
    getLocation();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Manual refresh function
  const refresh = useCallback(async () => {
    await getLocation();
  }, [getLocation]);

  return {
    location,
    status,
    isLocationAvailable,
    error,
    refresh,
  };
} 
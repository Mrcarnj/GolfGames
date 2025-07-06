import * as Location from 'expo-location';
import { useLocationStore } from '../store/locationStore';

// Haversine formula for distance in miles
export function getDistanceMiles(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const toRad = (x: number) => (x * Math.PI) / 180;
  const R = 3958.8; // Earth radius in miles
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Request location permission and get current location, with Zustand caching
export async function getCurrentLocation(): Promise<{ latitude: number; longitude: number } | null> {
  const { setLocationStatus, setLastLocation, setIsLocationAvailable } = useLocationStore.getState();
  try {
    let { status } = await Location.requestForegroundPermissionsAsync();
    setLocationStatus(status);
    if (status !== 'granted') {
      setIsLocationAvailable(false);
      throw new Error('Location permission not granted');
    }
    let loc = await Location.getCurrentPositionAsync({});
    setLastLocation(loc.coords);
    setIsLocationAvailable(true);
    return { latitude: loc.coords.latitude, longitude: loc.coords.longitude };
  } catch (e: any) {
    setIsLocationAvailable(false);
    setLocationStatus(e.message);
    return null;
  }
}

// Get last known location from Zustand
export function getLastKnownLocation(): { latitude: number; longitude: number } | null {
  const { lastLocation } = useLocationStore.getState();
  if (lastLocation && lastLocation.latitude && lastLocation.longitude) {
    return { latitude: lastLocation.latitude, longitude: lastLocation.longitude };
  }
  return null;
} 
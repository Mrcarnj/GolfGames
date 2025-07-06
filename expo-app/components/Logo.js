import React from 'react';
import { Image, StyleSheet, View } from 'react-native';

export default function Logo({ style }) {
  return (
    <View style={[styles.shadow, style]}>
      <Image
        source={require('../assets/golfgamble_bag.png')}
        style={styles.image}
        resizeMode="cover"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  shadow: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
    elevation: 6,
    borderRadius: 10,
    alignSelf: 'center',
    marginVertical: 32,
  },
  image: {
    width: 120,
    height: 120,
    borderRadius: 10,
  },
}); 
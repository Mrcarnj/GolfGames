//
//  SingleRound.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/4/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import CoreLocation

class SingleRoundViewModel: ObservableObject {
    @Published var allCourses: [Course] = []
    @Published var uniqueLocations: [String] = []
    @Published var filteredCourses: [Course] = []
    @Published var nearbyCourses: [Course] = []
    @Published var selectedCourse: Course?
    @Published var tees: [Tee] = []
    @Published var holes: [Hole] = []

    private var db = Firestore.firestore()

    func fetchCoursesAndNearby(userLocation: CLLocation?) {
        print("Fetching all courses")
        db.collection("courses").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching courses: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No courses found")
                return
            }

            self.allCourses = documents.compactMap { try? $0.data(as: Course.self) }
            print("Fetched \(self.allCourses.count) courses")
            self.extractUniqueLocations()
            
            if let location = userLocation {
                self.fetchNearbyCourses(userLocation: location)
            }
        }
    }

    private func extractUniqueLocations() {
        let locations = allCourses.map { $0.location }
        self.uniqueLocations = Array(Set(locations)).sorted()
    }

    func filterCourses(by location: String?) {
        guard let location = location else {
            filteredCourses = []
            return
        }
        filteredCourses = allCourses.filter { $0.location == location }
    }

    func fetchNearbyCourses(userLocation: CLLocation) {
        print("Fetching nearby courses for location: \(userLocation)")
        nearbyCourses = allCourses.compactMap { course in
            guard let courseLat = course.latitude, let courseLon = course.longitude else {
                print("Course \(course.name) missing lat/lon")
                return nil
            }
            let courseLocation = CLLocation(latitude: courseLat, longitude: courseLon)
            let distance = userLocation.distance(from: courseLocation) / 1609.34 // Convert meters to miles
            print("Course: \(course.name), Distance: \(distance) miles")
            if distance <= 20 {
                var courseWithDistance = course
                courseWithDistance.distance = distance
                return courseWithDistance
            }
            return nil
        }.sorted { $0.distance ?? 0 < $1.distance ?? 0 }
        print("Found \(nearbyCourses.count) nearby courses")
    }

    func fetchTees(for course: Course, completion: @escaping ([Tee]) -> Void) {
        guard let courseId = course.id else { return }

        db.collection("courses").document(courseId).collection("Tees").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching tees: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No tees found")
                return
            }

            let fetchedTees = documents.compactMap { doc -> Tee? in
                let data = doc.data()

                guard let teeName = data["tee_name"] as? String else {
                    print("Missing tee_name")
                    return nil
                }

                let courseRatingValue = data["course_rating"]
                let courseRating: Float
                if let rating = courseRatingValue as? Float {
                    courseRating = rating
                } else if let rating = courseRatingValue as? Double {
                    courseRating = Float(rating)
                } else {
                    print("Missing course_rating")
                    return nil
                }

                guard let slopeRating = data["slope_rating"] as? Int else {
                    print("Missing slope_rating")
                    return nil
                }
                guard let coursePar = data["course_par"] as? Int else {
                    print("Missing course_par")
                    return nil
                }
                guard let teeYards = data["tee_yards"] as? Int else {
                    print("Missing tee_yards")
                    return nil
                }

                return Tee(id: doc.documentID, course_id: courseId, tee_name: teeName, course_rating: courseRating, slope_rating: slopeRating, course_par: coursePar, tee_yards: teeYards)
            }

            self.tees = fetchedTees.sorted { $0.tee_yards > $1.tee_yards }
            completion(fetchedTees)
        }
    }

    func loadHoles(for courseId: String, teeId: String, completion: @escaping ([Hole]) -> Void) {
        let db = Firestore.firestore()
        db.collection("courses").document(courseId).collection("Tees").document(teeId).collection("Holes").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completion([])
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                completion([])
                return
            }
            
            let loadedHoles = documents.compactMap { document -> Hole? in
                do {
                    let hole = try document.data(as: Hole.self)
                    return hole
                } catch {
                    print("Error decoding hole document \(document.documentID): \(error)")
                    return nil
                }
            }.sorted { $0.holeNumber < $1.holeNumber }
            
            DispatchQueue.main.async {
                self.holes = loadedHoles
                completion(loadedHoles)
            }
        }
    }
}
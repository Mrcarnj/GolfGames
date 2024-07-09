//
//  SingleRound.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/4/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class SingleRoundViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var uniqueLocations: [String] = []
    @Published var filteredCourses: [Course] = []
    @Published var tees: [Tee] = []

    private var db = Firestore.firestore()

    func fetchCourses() {
        db.collection("courses").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching courses: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No courses found")
                return
            }

            self.courses = documents.compactMap { try? $0.data(as: Course.self) }
            self.extractUniqueLocations()
            print("Fetched courses: \(self.courses)")
        }
    }

    private func extractUniqueLocations() {
        let locations = courses.map { $0.location }
        self.uniqueLocations = Array(Set(locations)).sorted()
    }

    func filterCourses(by location: String?) {
        guard let location = location else {
            filteredCourses = []
            return
        }
        filteredCourses = courses.filter { $0.location == location }
    }

    func fetchTees(for course: Course) {
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

            print("Tees documents count: \(documents.count)")

            self.tees = documents.compactMap { doc -> Tee? in
                let data = doc.data()
                print("Tee document data: \(data)")

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
            
            self.tees.sort { $0.tee_yards > $1.tee_yards } // Sort tees by tee_yards in descending order
            
            print("Fetched tees for course \(course.name): \(self.tees)")
        }
    }
}


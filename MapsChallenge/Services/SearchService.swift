import MapKit

struct SearchResult: Identifiable, Hashable, Equatable {
    let id = UUID()
    let name: String
    let placemark: MKPlacemark
    let coordinate: CLLocationCoordinate2D
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
    
    // Implement Equatable
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

protocol SearchServiceProtocol {
    func search(query: String, region: MKCoordinateRegion) async throws -> [SearchResult]
}

@Observable final class SearchService: SearchServiceProtocol {
    func search(query: String, region: MKCoordinateRegion) async throws -> [SearchResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        return response.mapItems.map { item in
            SearchResult(
                name: item.name ?? "Unknown Location",
                placemark: item.placemark,
                coordinate: item.placemark.coordinate
            )
        }
    }
} 
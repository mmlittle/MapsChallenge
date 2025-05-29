import MapKit

struct RouteInfo {
    let route: MKRoute
    let polyline: MKPolyline
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
}

protocol RouteServiceProtocol {
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> RouteInfo
}

@Observable final class RouteService: RouteServiceProtocol {
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> RouteInfo {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let request = MKDirections.Request()
        request.source = sourceMapItem
        request.destination = destinationMapItem
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw NSError(domain: "RouteService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No route found"])
        }
        
        return RouteInfo(
            route: route,
            polyline: route.polyline,
            distance: route.distance,
            expectedTravelTime: route.expectedTravelTime
        )
    }
} 
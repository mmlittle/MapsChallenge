import MapKit
import SwiftUI

@Observable final class MapViewModel {
    private let locationService: LocationServiceProtocol
    private let searchService: SearchServiceProtocol
    private let routeService: RouteServiceProtocol
    
    var region: MKCoordinateRegion?
    var searchResults: [SearchResult] = []
    var selectedResult: SearchResult?
    var routeInfo: RouteInfo?
    var isLoading = false
    var errorMessage: String?
    
    var searchText = ""
    var isSearching = false
    
    var currentLocation: CLLocation? {
        locationService.currentLocation
    }
    
    init(
        locationService: LocationServiceProtocol,
        searchService: SearchServiceProtocol,
        routeService: RouteServiceProtocol
    ) {
        self.locationService = locationService
        self.searchService = searchService
        self.routeService = routeService
        
        setupLocationUpdates()
        
        // Check current authorization status and start updates if needed
        if locationService.locationAuthorizationStatus == .authorizedWhenInUse ||
           locationService.locationAuthorizationStatus == .authorizedAlways {
            locationService.startUpdatingLocation()
        }
    }
    
    private func setupLocationUpdates() {
        locationService.onLocationUpdate = { [weak self] location in
            print("MapViewModel received location update")
            self?.updateRegion(with: location)
        }
        
        locationService.onAuthorizationStatusChange = { [weak self] status in
            print("MapViewModel received authorization status change: \(status.rawValue)")
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("MapViewModel starting location updates")
                self?.locationService.startUpdatingLocation()
            case .denied, .restricted:
                self?.errorMessage = "Location access denied. Please enable location services in Settings."
            case .notDetermined:
                self?.locationService.requestLocationPermission()
            @unknown default:
                break
            }
        }
    }
    
    private func updateRegion(with location: CLLocation) {
        print("MapViewModel updating region to: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        withAnimation {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    func requestLocationPermission() {
        print("MapViewModel requesting location permission")
        locationService.requestLocationPermission()
    }
    
    func search() async {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            searchResults = try await searchService.search(query: searchText, region: region ?? MKCoordinateRegion(
                center: currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        } catch {
            errorMessage = "Failed to search: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func selectResult(_ result: SearchResult) {
        selectedResult = result
        // Update region to center on selected result
        withAnimation {
            region = MKCoordinateRegion(
                center: result.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        calculateRoute(to: result.coordinate)
    }
    
    private func calculateRoute(to destination: CLLocationCoordinate2D) {
        guard let currentLocation = locationService.currentLocation else {
            errorMessage = "Unable to get current location"
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                routeInfo = try await routeService.calculateRoute(
                    from: currentLocation.coordinate,
                    to: destination
                )
            } catch {
                errorMessage = "Failed to calculate route: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
    
    func clearRoute() {
        routeInfo = nil
        selectedResult = nil
    }
} 
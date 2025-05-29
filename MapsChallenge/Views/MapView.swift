import SwiftUI
import MapKit

struct MapView: View {
    let model: MapViewModel
    @State private var selectedMarker: SearchResult?
    @State private var position: MapCameraPosition
    
    init(model: MapViewModel) {
        self.model = model
        // Initialize with a default position that will be updated when we get the user's location
        self._position = State(initialValue: .automatic)
    }
    
    var body: some View {
        ZStack {
            Map(position: $position, selection: $selectedMarker) {
                // User's current location
                if let location = model.currentLocation {
                    Marker("Current Location", coordinate: location.coordinate)
                        .tint(.blue)
                }
                
                // Search results
                ForEach(model.searchResults) { result in
                    Marker(result.name, coordinate: result.coordinate)
                        .tint(.red)
                        .tag(result)
                }
                
                // Route overlay
                if let routeInfo = model.routeInfo {
                    MapPolyline(routeInfo.polyline)
                        .stroke(.blue, lineWidth: 4)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onTapGesture { location in
                // Clear selection when tapping on the map
                model.clearRoute()
                selectedMarker = nil
            }
            .onChange(of: selectedMarker) { _, newValue in
                if let result = newValue {
                    model.selectResult(result)
                }
            }
            .onChange(of: model.currentLocation) { _, newLocation in
                if let location = newLocation {
                    withAnimation {
                        position = .region(MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        ))
                    }
                }
            }
            
            VStack {
                // Search bar
                SearchBar(text: Binding(
                    get: { model.searchText },
                    set: { model.searchText = $0 }
                ), onSubmit: {
                    Task {
                        await model.search()
                    }
                })
                .padding()
                
                Spacer()
                
                // Route info
                if let routeInfo = model.routeInfo {
                    RouteInfoView(routeInfo: routeInfo) {
                        model.clearRoute()
                        selectedMarker = nil
                    }
                    .padding()
                }
            }
            
            // Loading indicator
            if model.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
            
            // Error message
            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.white)
                    .padding()
                    .background(.red.opacity(0.8))
                    .cornerRadius(10)
                    .padding()
                    .transition(.move(edge: .top))
            }
        }
        .onAppear {
            model.requestLocationPermission()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSubmit: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search places...", text: $text)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit(onSubmit)
            
            Button(action: onSubmit) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

struct RouteInfoView: View {
    let routeInfo: RouteInfo
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Route Information")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Text("Distance: \(formatDistance(routeInfo.distance))")
            Text("Time: \(formatTime(routeInfo.expectedTravelTime))")
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: time) ?? ""
    }
}

#Preview {
    MapView(model: MapViewModel(
        locationService: LocationService(),
        searchService: SearchService(),
        routeService: RouteService()
    ))
} 
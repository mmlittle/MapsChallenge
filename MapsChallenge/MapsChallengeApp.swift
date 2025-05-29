//
//  MapsChallengeApp.swift
//  MapsChallenge
//
//  Created by llamaman on 5/29/25.
//

import SwiftUI

@main
struct MapsChallengeApp: App {
    private let locationService: LocationServiceProtocol
    private let searchService: SearchServiceProtocol
    private let routeService: RouteServiceProtocol
    
    init() {
        // Initialize services
        self.locationService = LocationService()
        self.searchService = SearchService()
        self.routeService = RouteService()
    }
    
    var body: some Scene {
        WindowGroup {
            MapView(model: MapViewModel(
                locationService: locationService,
                searchService: searchService,
                routeService: routeService
            ))
        }
    }
}

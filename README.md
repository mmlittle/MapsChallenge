Map Exploration App
 * Objective: Create an app that displays the user's current location on a map and allows the user to search for nearby places of interest. The app should also display a route to a selected destination.
 * Requirements:
   * Location Display:
     * Use CoreLocation to request and display the user's current location on a MapKit map. Ensure proper handling of location permissions.
     * Continuously update the user's location on the map as they move.
   * Nearby Search:
     * Implement a search bar or a similar UI element that allows users to search for places nearby (e.g., "restaurants," "cafes," "parks").
     * Use the MapKit Local Search API (MKLocalSearch) to find places matching the search query within a reasonable radius of the user's current location.
     * Display the search results as annotations (pins) on the map, showing the name and address of each place.
   * Route Display:
     * When the user selects a place from the search results, display a route from the user's current location to the selected destination.
     * Use MapKit's directions API (MKDirections) to calculate and display the route on the map as an overlay. Include estimated travel time and distance.
   * UI/UX:
     * Use Swift and either UIKit or SwiftUI for the UI.
     * Provide a clean and intuitive user interface.
     * Handle loading states, errors (e.g., no search results, location services disabled), and empty states gracefully.

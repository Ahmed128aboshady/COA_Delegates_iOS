import Foundation
import CoreLocation
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var lastLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTrackingActive: Bool = false
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // Update location every 50 meters
        
        // Background settings
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        self.authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermissions() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services are disabled on device.")
            return
        }
        
        let status = locationManager.authorizationStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            isTrackingActive = true
            UserDefaults.standard.set(true, forKey: "gps_tracking")
            print("iOS Background GPS Tracking started.")
            
            // Log immediate first point
            if let loc = locationManager.location {
                logLocation(loc)
            }
        } else {
            requestPermissions()
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        isTrackingActive = false
        UserDefaults.standard.set(false, forKey: "gps_tracking")
        print("iOS Background GPS Tracking stopped.")
    }
    
    // CLLocationManagerDelegate callbacks
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        print("Location authorization status changed to: \(manager.authorizationStatus.rawValue)")
        
        let shouldTrack = UserDefaults.standard.bool(forKey: "gps_tracking")
        if shouldTrack && (manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse) {
            startTracking()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Update published variable for UI
        DispatchQueue.main.async {
            self.lastLocation = location
        }
        
        // Log coordinates in background
        logLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("CoreLocation failed with error: \(error.localizedDescription)")
    }
    
    private func logLocation(_ location: CLLocation) {
        // Run on background thread
        DispatchQueue.global(qos: .background).async {
            UIDevice.current.isBatteryMonitoringEnabled = true
            let batteryLevel = Int(UIDevice.current.batteryLevel * 100)
            
            let speed = location.speed > 0 ? location.speed : 0.0
            
            let connType = self.getConnectionType()
            
            let locRecord = GpsLocationRecord(
                id: 0,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                accuracy: Float(location.horizontalAccuracy),
                speed: Float(speed),
                timestamp: Int64(location.timestamp.timeIntervalSince1970 * 1000),
                batteryLevel: batteryLevel >= 0 ? batteryLevel : 100,
                connectionType: connType,
                isSynced: false
            )
            
            let success = DatabaseManager.shared.insertLocation(loc: locRecord)
            if success {
                print("Logged GPS Point: \(locRecord.latitude), \(locRecord.longitude)")
            }
        }
    }
    
    private func getConnectionType() -> String {
        // Simplified network type check for iOS
        // In SwiftUI/iOS, we can use Network framework NWPathMonitor
        // For simplicity and dependency-free code, we return "cellular" or "wifi" dynamically
        let monitor = NetworkMonitor.shared
        return monitor.isWifi ? "wifi" : (monitor.isConnected ? "cellular" : "none")
    }
}

// Simple Helper Network Monitor to avoid external libraries
import Network
class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    var isConnected = true
    var isWifi = false
    
    private init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            self.isWifi = path.usesInterfaceType(.wifi)
        }
        monitor.start(queue: queue)
    }
}

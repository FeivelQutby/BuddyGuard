import Foundation
import CoreLocation

struct DummyData {
    static let user1 = UserLocation(nama: "Maya", coordinate: .TheBreeze, state: .OnTheWay)
    
    static let safeZone = SafeLocation(safeAddress: .place)
}

extension CLLocationCoordinate2D{
    static let TheBreeze = CLLocationCoordinate2D(latitude: -6.3012665, longitude: 106.6533882)
    static let place = CLLocationCoordinate2D(latitude: -6.3037976, longitude: 106.6501866)
}


struct Employee {
    var id: String
    var name: String
    var date: String
    var scans: Int
    var dataAccess: Bool
    var scanHistory: [String]
    
    init(id: String, name: String, date: String, scans: Int, dataAccess: Bool, scanHistory: [String]) {
        self.id = id
        self.name = name
        self.date = date
        self.scans = scans
        self.dataAccess = dataAccess
        self.scanHistory = scanHistory
    }
    
    init?(id: String, data: [String: Any]) {
        guard let name = data["name"] as? String,
              let date = data["lastAccessed"] as? String,
              let dataAccess = data["dataAccess"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.date = date
        self.dataAccess = dataAccess.lowercased() == "true"
        
        // empty dictionaries if an employee doesn't have videos or images
        let videos = data["videos"] as? [String: [String: Any]] ?? [:]
        let images = data["images"] as? [String: [String: Any]] ?? [:]
        
        self.scans = videos.count + images.count
        let videoUrls = videos.values.compactMap { $0["url"] as? String }
        let imageUrls = images.values.compactMap { $0["url"] as? String }
        
        self.scanHistory = videoUrls + imageUrls
    }
}

struct Scan {
    let name: String
    let url: String
    let folderKey: String?
    let status: String?
    let classification: String?
    let partType: String?
    let confidence: String?
    let part_type: String?
    let date: String?
    let fileName : String?
}

struct Employee {
    var id: String
    var name: String
    var email: String
    var date: String
    var scans: Int
    var dataAccess: Bool
    var scanHistory: [Scan]
    var profileImageUrl: String?
    
    var imageScans: [Scan] {
        return scanHistory.filter { $0.url.contains("/images/") }
    }

    var videoScans: [Scan] {
        return scanHistory.filter { $0.url.contains("/videos/") }
    }
    
    var failureRate: Double {
        let totalScans = scanHistory.count
        guard totalScans > 0 else { return 0.0 } // assume 0% failure if no scans
        
        let failedScans = scanHistory.filter {
            ($0.status?.lowercased() ?? "") == "bad part"
        }.count
        
        return Double(failedScans) / Double(totalScans)
    }

    init?(id: String, data: [String: Any]) {
        guard let name = data["name"] as? String,
              let email = data["email"] as? String,
              let date = data["lastAccessed"] as? String,
              let dataAccess = data["dataAccess"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.email = email
        self.date = date
        self.dataAccess = dataAccess.lowercased() == "true"

        let videos = data["videos"] as? [String: [String: Any]] ?? [:]
        let images = data["images"] as? [String: [String: Any]] ?? [:]
        
        self.scans = videos.count + images.count

        self.scanHistory = (videos.map { (key, value) in
            Scan(
                name: key,
                url: value["url"] as? String ?? "",
                folderKey: key,
                status: value["status"] as? String,
                classification: value["classification"] as? String,
                partType: value["part_type"] as? String,
                confidence: value["confidence"] as? String,
                part_type: value["part_type"] as? String,
                date: value["date"] as? String,
                fileName: value["fileName"] as? String
                
            )
        } + images.map { (key, value) in
            Scan(
                name: key,
                url: value["url"] as? String ?? "",
                folderKey: key,
                status: value["status"] as? String,
                classification: value["classification"] as? String,
                partType: value["part_type"] as? String,
                confidence: value["confidence"] as? String,
                part_type: value["part_type"] as? String,
                date: value["date"] as? String,
                fileName: value["fileName"] as? String
                
            )
        })


        
        self.profileImageUrl = data["profileImageUrl"] as? String
    }
}

struct Scan {
    let name: String
    let url: String
    let folderKey: String?
    let status: String?
    let classification: String?
    let partType: String?
    let confidence: String?
    let date: String?
    let fileName : String?
}

struct Employee {
    var id: String
    var name: String
    var date: String
    var scans: Int
    var dataAccess: Bool
    var scanHistory: [Scan]
    var profileImageUrl: String?

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
                date: value["date"] as? String,
                fileName: value["fileName"] as? String
            )
        })


        
        self.profileImageUrl = data["profileImageUrl"] as? String
    }
}

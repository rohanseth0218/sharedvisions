import Foundation

enum Constants {
    // App Info
    static let appName = "SharedVisions"
    static let appVersion = "1.0.0"
    
    // Validation
    enum Validation {
        static let minPasswordLength = 8
        static let maxUsernameLength = 30
        static let maxVisionTitleLength = 100
        static let maxVisionDescriptionLength = 500
        static let inviteCodeLength = 6
    }
    
    // Limits
    enum Limits {
        static let maxPhotosPerUser = 10
        static let maxMembersPerGroup = 10
        static let maxVisionsPerGroup = 100
        static let maxImagesPerVision = 5
    }
    
    // Storage
    enum Storage {
        static let maxImageSize = 5 * 1024 * 1024 // 5MB
        static let imageCompressionQuality: CGFloat = 0.8
        static let thumbnailSize = 200
    }
    
    // API
    enum API {
        static let timeoutInterval: TimeInterval = 30
        static let maxRetries = 3
    }
    
    // Animation
    enum Animation {
        static let defaultDuration: Double = 0.3
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.8
    }
    
    // UI
    enum UI {
        static let cornerRadius: CGFloat = 16
        static let cardCornerRadius: CGFloat = 12
        static let buttonCornerRadius: CGFloat = 14
        static let defaultPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
    }
}


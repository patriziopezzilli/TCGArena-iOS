import Foundation
import UIKit

struct SearchResult: Codable {
    let card_id: Int64
    let confidence: Float
}

class VisualSearchService: ObservableObject {
    static let shared = VisualSearchService()
    
    // Direct connection to the Python Service on the VPS
    private let baseURL = "http://80.211.236.249:8001" 
    
    func searchCard(image: UIImage) async throws -> [SearchResult] {
        guard let url = URL(string: "\(baseURL)/search") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30 // Increase timeout for image upload & processing
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 1. Digital Zoom (Crop to Center) - Simulate 2x Zoom
        // This removes background noise and focuses on the card
        let zoomedImage = cropToCenter(image: image, scale: 0.5) // 0.5 = 2x Zoom (keeping 50% of center)
        
        // 2. Resize image to max 800px to speed up upload
        let resizedImage = resizeImage(image: zoomedImage, targetSize: CGSize(width: 800, height: 800))
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("🔵 VisualSearchService: Sending request to \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🔴 VisualSearchService: Invalid response type")
                throw URLError(.badServerResponse)
            }
            
            print("🔵 VisualSearchService: Response Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔵 VisualSearchService: Raw Response Body: \(responseString)")
            }
            
            guard httpResponse.statusCode == 200 else {
                print("🔴 VisualSearchService: Server Error (Status: \(httpResponse.statusCode))")
                throw URLError(.badServerResponse)
            }
            
            let results = try JSONDecoder().decode([SearchResult].self, from: data)
            print("🟢 VisualSearchService: Successfully decoded \(results.count) results")
            return results
        } catch {
            print("🔴 VisualSearchService: Network/Decoding Error: \(error)")
            throw error
        }
    }
    
    private func cropToCenter(image: UIImage, scale: CGFloat) -> UIImage {
        let size = image.size
        let targetWidth = size.width * scale
        let targetHeight = size.height * scale
        let originX = (size.width - targetWidth) / 2
        let originY = (size.height - targetHeight) / 2
        
        let rect = CGRect(x: originX, y: originY, width: targetWidth, height: targetHeight)
        
        // Use CGImage for cropping to ensure correct orientation handling
        guard let cgImage = image.cgImage?.cropping(to: rect) else {
            return image
        }
        
        // Return new image preserving the original orientation
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // Don't scale up
        if newSize.width > size.width { return image }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}

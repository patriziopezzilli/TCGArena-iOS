//
//  ImageCacheManager.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/29/25.
//

import SwiftUI
import Combine

/// Gestore del caching delle immagini con supporto per memoria e disco
class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Configura la cache in memoria
        memoryCache.countLimit = 100 // Numero massimo di immagini in memoria
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limite totale
        
        // Directory per il cache su disco
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
        
        // Crea la directory se non esiste
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configura URLCache per il caching HTTP
        configureURLCache()
    }
    
    private func configureURLCache() {
        // Configura URLCache con 100MB di memoria e 500MB su disco
        let memoryCapacity = 100 * 1024 * 1024 // 100MB
        let diskCapacity = 500 * 1024 * 1024 // 500MB
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "TCG_Arena_Image_Cache")
        URLCache.shared = cache
    }
    
    /// Carica un'immagine dall'URL con caching
    func loadImage(from url: URL) async throws -> UIImage {
        let cacheKey = url.absoluteString as NSString
        
        // Controlla prima la cache in memoria
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            print("🖼️ ImageCache: Loaded from memory cache - \(url.lastPathComponent)")
            return cachedImage
        }
        
        // Controlla la cache su disco
        if let diskImage = loadFromDisk(for: cacheKey) {
            // Salva anche in memoria per accessi futuri più veloci
            memoryCache.setObject(diskImage, forKey: cacheKey)
            print("🖼️ ImageCache: Loaded from disk cache - \(url.lastPathComponent)")
            return diskImage
        }
        
        // Scarica dall'URL
        print("🌐 ImageCache: Downloading from network - \(url.lastPathComponent)")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let image = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        
        // Salva nelle cache
        memoryCache.setObject(image, forKey: cacheKey)
        saveToDisk(image, for: cacheKey)
        
        print("💾 ImageCache: Saved to cache - \(url.lastPathComponent)")
        return image
    }
    
    /// Carica un'immagine dalla cache su disco
    private func loadFromDisk(for key: NSString) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key.hash.description)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    /// Salva un'immagine nella cache su disco
    private func saveToDisk(_ image: UIImage, for key: NSString) {
        let fileURL = cacheDirectory.appendingPathComponent(key.hash.description)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        try? data.write(to: fileURL)
    }
    
    /// Cancella tutta la cache
    func clearCache() {
        memoryCache.removeAllObjects()
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
            print("🗑️ ImageCache: Cache cleared")
        } catch {
            print("❌ ImageCache: Error clearing cache - \(error.localizedDescription)")
        }
    }
    
    /// Ottieni le dimensioni della cache
    func cacheSize() -> (memory: Int, disk: Int) {
        let memorySize = memoryCache.totalCostLimit // Approssimativo
        
        var diskSize = 0
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            for fileURL in contents {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                diskSize += attributes[.size] as? Int ?? 0
            }
        } catch {
            print("❌ ImageCache: Error calculating disk size - \(error.localizedDescription)")
        }
        
        return (memorySize, diskSize)
    }
}

/// View personalizzata per AsyncImage con caching
struct CachedAsyncImage: View {
    let url: URL?
    let scale: CGFloat
    let content: (AsyncImagePhase) -> AnyView
    
    init(url: URL?, scale: CGFloat = 1.0, @ViewBuilder content: @escaping (AsyncImagePhase) -> some View) {
        self.url = url
        self.scale = scale
        self.content = { phase in AnyView(content(phase)) }
    }
    
    var body: some View {
        if let url = url {
            AsyncImage(url: url, scale: scale) { phase in
                content(phase)
            }
            .task {
                // Pre-carica l'immagine per il caching
                do {
                    _ = try await ImageCacheManager.shared.loadImage(from: url)
                } catch {
                    print("❌ CachedAsyncImage: Failed to cache image - \(error.localizedDescription)")
                }
            }
        } else {
            content(.empty)
        }
    }
}
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
    
    /// Ottieni immagine dalla cache in memoria (sincrono, per UI immediata)
    func getFromMemoryCache(key: NSString) -> UIImage? {
        return memoryCache.object(forKey: key)
    }
    
    /// Ottieni immagine dalla cache in memoria usando URL
    func getFromMemoryCache(url: URL) -> UIImage? {
        let cacheKey = url.absoluteString as NSString
        return memoryCache.object(forKey: cacheKey)
    }
    
    /// Ottieni immagine dalla cache (memoria o disco) in modo sincrono
    func getFromCache(url: URL) -> UIImage? {
        let cacheKey = url.absoluteString as NSString
        
        // Controlla prima la cache in memoria
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Controlla la cache su disco
        if let diskImage = loadFromDisk(for: cacheKey) {
            // Salva anche in memoria per accessi futuri più veloci
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }
        
        return nil
    }
    
    /// Carica un'immagine dall'URL con caching
    func loadImage(from url: URL) async throws -> UIImage {
        let cacheKey = url.absoluteString as NSString
        
        // Controlla prima la cache in memoria
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Controlla la cache su disco
        if let diskImage = loadFromDisk(for: cacheKey) {
            // Salva anche in memoria per accessi futuri più veloci
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }
        
        // Scarica dall'URL
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let image = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        
        // Salva nelle cache
        memoryCache.setObject(image, forKey: cacheKey)
        saveToDisk(image, for: cacheKey)
        
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
        } catch {
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
        }
        
        return (memorySize, diskSize)
    }
}

/// View personalizzata per AsyncImage con caching migliorato
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let scale: CGFloat
    let content: (AsyncImagePhase) -> Content
    
    @State private var phase: AsyncImagePhase = .empty
    @State private var loadTask: Task<Void, Never>?
    
    init(url: URL?, scale: CGFloat = 1.0, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.scale = scale
        self.content = content
    }
    
    var body: some View {
        content(phase)
            .onAppear {
                loadImage()
            }
            .onChange(of: url) { newUrl in
                // Ricarica se l'URL cambia
                loadImage()
            }
            .onDisappear {
                loadTask?.cancel()
            }
    }
    
    private func loadImage() {
        // Cancella task precedente
        loadTask?.cancel()
        
        guard let url = url else {
            phase = .empty
            return
        }
        
        // Controlla prima la cache (memoria + disco) per un caricamento istantaneo
        if let cachedImage = ImageCacheManager.shared.getFromCache(url: url) {
            phase = .success(SwiftUI.Image(uiImage: cachedImage))
            return
        }
        
        // Mostra loading state
        phase = .empty
        
        // Carica l'immagine in background
        loadTask = Task {
            do {
                let image = try await ImageCacheManager.shared.loadImage(from: url)
                
                // Aggiorna UI sul main thread
                await MainActor.run {
                    if !Task.isCancelled {
                        phase = .success(SwiftUI.Image(uiImage: image))
                    }
                }
            } catch {
                await MainActor.run {
                    if !Task.isCancelled {
                        phase = .failure(error)
                    }
                }
            }
        }
    }
}

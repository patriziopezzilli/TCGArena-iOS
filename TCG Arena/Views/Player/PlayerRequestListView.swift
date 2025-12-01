//
//  PlayerRequestListView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct PlayerRequestListView: View {
    @EnvironmentObject var requestService: RequestService
    @EnvironmentObject var authService: AuthService
    @State private var requests: [CustomerRequest] = []
    @State private var isLoading = false
    @State private var selectedRequest: CustomerRequest?
    @State private var showingCreateRequest = false
    @State private var selectedStatus: RequestStatusFilter = .all
    
    enum RequestStatusFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case accepted = "Accepted"
        case completed = "Completed"
        case rejected = "Rejected"
    }
    
    var filteredRequests: [CustomerRequest] {
        guard selectedStatus != .all else { return requests }
        
        switch selectedStatus {
        case .all:
            return requests
        case .pending:
            return requests.filter { $0.status == .pending }
        case .accepted:
            return requests.filter { $0.status == .accepted }
        case .completed:
            return requests.filter { $0.status == .completed }
        case .rejected:
            return requests.filter { $0.status == .rejected }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Status Filter
                statusFilterSection
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredRequests.isEmpty {
                    emptyStateView
                } else {
                    requestList
                }
            }
            .navigationTitle("My Requests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: loadRequests) {
                            Image(systemName: "arrow.clockwise")
                        }
                        
                        Button(action: { showingCreateRequest = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateRequest) {
                CreateRequestView { success in
                    if success {
                        loadRequests()
                    }
                }
                .environmentObject(requestService)
                .environmentObject(authService)
            }
            .sheet(item: $selectedRequest) { request in
                PlayerRequestDetailView(request: request) {
                    loadRequests()
                }
                .environmentObject(requestService)
            }
        }
        .onAppear(perform: loadRequests)
    }
    
    private var statusFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RequestStatusFilter.allCases, id: \.self) { status in
                    FilterChip(
                        title: status.rawValue,
                        isSelected: selectedStatus == status
                    ) {
                        selectedStatus = status
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var requestList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredRequests.sorted(by: { $0.createdAt > $1.createdAt })) { request in
                    RequestCardView(request: request)
                        .onTapGesture {
                            selectedRequest = request
                        }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Requests")
                .font(.headline)
            
            Text("Create a request to ask shops for specific cards or services")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingCreateRequest = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Request")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color(AdaptiveColors.primary))
                .cornerRadius(12)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func loadRequests() {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        
        Task {
            do {
                let response = try await requestService.getRequests(
                    status: nil,
                    type: nil,
                    userId: userId,
                    shopId: nil
                )
                
                await MainActor.run {
                    requests = response.requests
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading requests: \(error)")
                    isLoading = false
                }
            }
        }
    }
}

struct RequestCardView: View {
    let request: CustomerRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.type.displayName)
                        .font(.headline)
                    
                    Text(request.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                RequestStatusBadge(status: request.status)
            }
            
            // Shop
            if let shop = request.shop {
                HStack(spacing: 6) {
                    Image(systemName: "storefront.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(shop.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Description preview
            if !request.description.isEmpty {
                Text(request.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Footer
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    
                    Text(request.createdAt, style: .date)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                if request.hasUnreadMessages {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color(AdaptiveColors.primary))
                        
                        Text("New messages")
                            .font(.caption)
                            .foregroundColor(Color(AdaptiveColors.primary))
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct RequestStatusBadge: View {
    let status: CustomerRequest.RequestStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(status.color))
            .cornerRadius(12)
    }
}

#Preview {
    PlayerRequestListView()
        .environmentObject(RequestService(apiClient: APIClient.shared))
        .environmentObject(AuthService())
}

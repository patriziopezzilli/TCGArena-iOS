//
//  CreateTournamentView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI
import MapKit

struct CreateTournamentView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    
    // Tournament Details
    @State private var title = ""
    @State private var description = ""
    @State private var selectedTCG: TCGType = .pokemon
    @State private var selectedFormat: Tournament.TournamentType = .casual
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600 * 4) // 4 hours later
    @State private var registrationDeadline = Date().addingTimeInterval(3600 * 24) // 1 day later
    @State private var maxParticipants = 16
    @State private var entryFee: Double = 0.0
    @State private var prizePool = ""
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var rules = ""
    
    // UI State
    @State private var isCreating = false
    @State private var showingSuccess = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Basic Information
                    basicInfoSection
                    
                    // Tournament Settings
                    settingsSection
                    
                    // Location Section
                    locationSection
                    
                    // Rules Section
                    rulesSection
                    
                    // Create Button
                    createButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Create Tournament")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Tournament created successfully!")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(selectedTCG.themeColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                SwiftUI.Image(systemName: selectedTCG.systemIcon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(selectedTCG.themeColor)
            }
            
            Text("New Tournament")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Create an amazing tournament experience")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Basic Information Section
    private var basicInfoSection: some View {
        VStack(spacing: 20) {
            SectionHeaderView(title: "Basic Information", subtitle: "Tournament details and game type")
            
            VStack(spacing: 16) {
                ModernTextField(
                    title: "Tournament Title",
                    text: $title,
                    icon: "trophy.fill"
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                ModernPickerField(
                    title: "Trading Card Game",
                    selection: $selectedTCG,
                    options: TCGType.allCases,
                    icon: "gamecontroller.fill",
                    displayName: { $0.rawValue }
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 20) {
            SectionHeaderView(title: "Tournament Settings", subtitle: "Format, dates, and participant limits")
            
            VStack(spacing: 16) {
                ModernPickerField(
                    title: "Format",
                    selection: $selectedFormat,
                    options: Tournament.TournamentType.allCases,
                    icon: "list.bullet.rectangle",
                    displayName: { $0.rawValue }
                )
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dates & Times")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        
                        DatePicker("Registration Deadline", selection: $registrationDeadline, displayedComponents: [.date, .hourAndMinute])
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Max Participants")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Stepper("\(maxParticipants)", value: $maxParticipants, in: 4...128, step: 4)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Entry Fee ($)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextField("0.00", value: $entryFee, format: .number)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                }
                
                ModernTextField(
                    title: "Prize Pool",
                    text: $prizePool,
                    icon: "gift.fill"
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(spacing: 20) {
            SectionHeaderView(title: "Location", subtitle: "Venue name and address")
            
            VStack(spacing: 16) {
                ModernTextField(
                    title: "Venue Name",
                    text: $locationName,
                    icon: "building.2.fill"
                )
                
                ModernTextField(
                    title: "Address",
                    text: $locationAddress,
                    icon: "location.fill"
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Rules Section
    private var rulesSection: some View {
        VStack(spacing: 20) {
            SectionHeaderView(title: "Rules & Details", subtitle: "Tournament rules and additional information")
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tournament Rules")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    TextEditor(text: $rules)
                        .frame(height: 120)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button {
            createTournament()
        } label: {
            HStack(spacing: 12) {
                if isCreating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    SwiftUI.Image(systemName: "trophy.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                
                Text(isCreating ? "Creating Tournament..." : "Create Tournament")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFormValid ? selectedTCG.themeColor : Color(.systemGray4))
            )
        }
        .disabled(!isFormValid || isCreating)
        .padding(.top, 20)
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        !locationName.isEmpty &&
        !locationAddress.isEmpty &&
        startDate < endDate &&
        registrationDeadline < startDate
    }
    
    // MARK: - Actions
    // Helper function to format dates as strings for backend (format: "dd MMM yyyy, HH:mm")
    private func formatDateForBackend(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    private func createTournament() {
        guard isFormValid else {
            errorMessage = "Please fill all required fields correctly."
            showingError = true
            return
        }
        
        isCreating = true
        
        let newTournament = Tournament(
            title: title,
            description: description,
            tcgType: selectedTCG,
            type: selectedFormat,
            startDate: formatDateForBackend(startDate),
            endDate: formatDateForBackend(endDate),
            maxParticipants: maxParticipants,
            entryFee: entryFee,
            prizePool: Double(prizePool) ?? 0.0,
            organizerId: Int64(authService.currentUserId ?? 0),
            location: Tournament.TournamentLocation(
                venueName: locationName,
                address: locationAddress,
                city: "Milano", // Default for demo
                country: "Italy",
                latitude: 45.4642,
                longitude: 9.1900
            ),
            rules: rules
        )
        
        Task {
            await tournamentService.createTournament(newTournament)
            
            DispatchQueue.main.async {
                isCreating = false
                if tournamentService.errorMessage == nil {
                    showingSuccess = true
                } else {
                    errorMessage = tournamentService.errorMessage ?? "Failed to create tournament"
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    CreateTournamentView()
        .environmentObject(TournamentService())
}
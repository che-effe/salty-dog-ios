import SwiftUI
import MapKit

// MARK: - Fishing View
struct FishingView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var weatherManager: WeatherManager
    @StateObject private var fishingLogManager = FishingLogManager()
    @StateObject private var marineService = MarineDataService()
    
    @State private var showMarkSpotSheet = false
    @State private var showLogDetail: FishingLog?
    @State private var showStatistics = false
    
    @AppStorage("fishWeightUnit") private var weightUnitRaw: String = WeightUnit.pounds.rawValue
    @AppStorage("fishLengthUnit") private var lengthUnitRaw: String = LengthUnit.inches.rawValue
    
    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .pounds
    }
    
    private var lengthUnit: LengthUnit {
        LengthUnit(rawValue: lengthUnitRaw) ?? .inches
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.saltyBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignConstants.componentSpacing) {
                        // Current Conditions
                        conditionsCard
                        
                        // Mark Spot Button
                        markSpotButton
                        
                        // Statistics Summary (if logs exist)
                        if !fishingLogManager.logs.isEmpty {
                            statisticsSummary
                        }
                        
                        // Fishing Logs
                        logsSection
                    }
                    .padding(DesignConstants.screenPadding)
                }
            }
            .navigationTitle("Fishing Log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !fishingLogManager.logs.isEmpty {
                        Button {
                            showStatistics = true
                        } label: {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.saltyBlue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showMarkSpotSheet) {
                MarkSpotSheet(
                    locationManager: locationManager,
                    weatherManager: weatherManager,
                    marineService: marineService,
                    fishingLogManager: fishingLogManager,
                    weightUnit: weightUnit,
                    lengthUnit: lengthUnit
                )
            }
            .sheet(item: $showLogDetail) { log in
                LogDetailSheet(
                    log: log,
                    fishingLogManager: fishingLogManager,
                    weightUnit: weightUnit,
                    lengthUnit: lengthUnit
                )
            }
            .sheet(isPresented: $showStatistics) {
                StatisticsSheet(
                    statistics: fishingLogManager.statistics,
                    weightUnit: weightUnit,
                    lengthUnit: lengthUnit
                )
            }
            .onAppear {
                if let coordinate = locationManager.currentCoordinate {
                    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    Task {
                        await marineService.fetchMarineData(for: location)
                    }
                }
            }
        }
    }
    
    // MARK: - Current Conditions Card
    private var conditionsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Conditions")
                    .font(.headline)
                    .foregroundColor(.saltyTextPrimary)
                Spacer()
                if marineService.isLoading {
                    ProgressView()
                        .tint(.saltyBlue)
                }
            }
            
            HStack(spacing: 20) {
                // Weather
                conditionItem(
                    icon: weatherManager.currentWeather.symbolName,
                    title: "Air Temp",
                    value: formatTemperature(weatherManager.currentWeather.temperature)
                )
                
                // Water Temperature
                conditionItem(
                    icon: "thermometer.variable.and.figure",
                    title: "Water Temp",
                    value: formatWaterTemp(marineService.currentMarineData.waterTemperature)
                )
                
                // Tide
                conditionItem(
                    icon: tideIcon(for: marineService.currentMarineData.tideStatus),
                    title: "Tide",
                    value: marineService.currentMarineData.tideStatus?.rawValue ?? "--"
                )
                
                // Pressure
                conditionItem(
                    icon: "gauge.with.needle",
                    title: "Pressure",
                    value: String(format: "%.0f mb", weatherManager.currentWeather.barometricPressure)
                )
            }
            
            // Tide times
            if let nextHigh = marineService.currentMarineData.nextHighTide,
               let nextLow = marineService.currentMarineData.nextLowTide {
                Divider()
                    .background(Color.saltyTextSecondary.opacity(0.3))
                
                HStack {
                    tideTimeItem(title: "High Tide", date: nextHigh)
                    Spacer()
                    tideTimeItem(title: "Low Tide", date: nextLow)
                }
            }
        }
        .saltyCardStyle()
    }
    
    private func conditionItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.saltyBlue)
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.saltyTextPrimary)
            Text(title)
                .font(.caption2)
                .foregroundColor(.saltyTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func tideTimeItem(title: String, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.saltyTextSecondary)
            Text(formatTime(date))
                .font(.subheadline.bold())
                .foregroundColor(.saltyTextPrimary)
        }
    }
    
    // MARK: - Mark Spot Button
    private var markSpotButton: some View {
        Button {
            showMarkSpotSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                Text("Mark Fishing Spot")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.saltyBlue, .saltyBlue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cardCornerRadius))
        }
        .disabled(locationManager.currentCoordinate == nil)
    }
    
    // MARK: - Statistics Summary
    private var statisticsSummary: some View {
        let stats = fishingLogManager.statistics
        
        return HStack(spacing: 20) {
            statItem(value: "\(stats.totalLogs)", label: "Trips")
            statItem(value: "\(stats.totalFish)", label: "Fish")
            statItem(
                value: String(format: "%.1f", weightUnit.convert(fromKilograms: stats.totalWeight)),
                label: "Total \(weightUnit.displayName)"
            )
        }
        .saltyCardStyle()
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.saltyBlue)
            Text(label)
                .font(.caption)
                .foregroundColor(.saltyTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Logs Section
    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fishing Log")
                .font(.headline)
                .foregroundColor(.saltyTextPrimary)
            
            if fishingLogManager.logs.isEmpty {
                emptyLogsView
            } else {
                ForEach(fishingLogManager.logs) { log in
                    LogRowView(
                        log: log,
                        weightUnit: weightUnit,
                        onTap: { showLogDetail = log },
                        onToggleFavorite: { fishingLogManager.toggleFavorite(log) },
                        onDelete: { fishingLogManager.deleteLog(log) }
                    )
                }
            }
        }
    }
    
    private var emptyLogsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fish")
                .font(.system(size: 48))
                .foregroundColor(.saltyTextSecondary.opacity(0.5))
            
            Text("No fishing logs yet")
                .font(.headline)
                .foregroundColor(.saltyTextSecondary)
            
            Text("Tap 'Mark Fishing Spot' to start logging your catches")
                .font(.subheadline)
                .foregroundColor(.saltyTextSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .saltyCardStyle()
    }
    
    // MARK: - Helper Methods
    
    private func formatTemperature(_ celsius: Double) -> String {
        let fahrenheit = celsius * 9/5 + 32
        return String(format: "%.0f°F", fahrenheit)
    }
    
    private func formatWaterTemp(_ celsius: Double?) -> String {
        guard let celsius = celsius else { return "--" }
        let fahrenheit = celsius * 9/5 + 32
        return String(format: "%.0f°F", fahrenheit)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func tideIcon(for status: MarineData.TideStatus?) -> String {
        switch status {
        case .rising: return "arrow.up.circle.fill"
        case .falling: return "arrow.down.circle.fill"
        case .high: return "water.waves"
        case .low: return "water.waves.slash"
        default: return "water.waves"
        }
    }
}

// MARK: - Log Row View
struct LogRowView: View {
    let log: FishingLog
    let weightUnit: WeightUnit
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Date
                VStack {
                    Text(log.shortDate)
                        .font(.caption.bold())
                        .foregroundColor(.saltyTextPrimary)
                    Text(log.timeString)
                        .font(.caption2)
                        .foregroundColor(.saltyTextSecondary)
                }
                .frame(width: 70)
                
                Divider()
                    .frame(height: 40)
                
                // Fish info
                VStack(alignment: .leading, spacing: 4) {
                    if let spotName = log.spotName {
                        Text(spotName)
                            .font(.subheadline.bold())
                            .foregroundColor(.saltyTextPrimary)
                    }
                    
                    HStack(spacing: 8) {
                        Label("\(log.totalFishCount)", systemImage: "fish")
                        if log.totalWeight > 0 {
                            Text("•")
                            Text(String(format: "%.1f %@", 
                                       weightUnit.convert(fromKilograms: log.totalWeight),
                                       weightUnit.displayName))
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.saltyTextSecondary)
                }
                
                Spacer()
                
                // Favorite
                Button(action: onToggleFavorite) {
                    Image(systemName: log.isFavorite ? "star.fill" : "star")
                        .foregroundColor(log.isFavorite ? .yellow : .saltyTextSecondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.saltyTextSecondary)
            }
            .padding()
            .background(Color.saltyCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete this log?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Mark Spot Sheet
struct MarkSpotSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var weatherManager: WeatherManager
    @ObservedObject var marineService: MarineDataService
    @ObservedObject var fishingLogManager: FishingLogManager
    
    let weightUnit: WeightUnit
    let lengthUnit: LengthUnit
    
    @State private var spotName = ""
    @State private var notes = ""
    @State private var fishEntries: [FishEntry] = []
    @State private var showAddFish = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Location Section
                Section("Location") {
                    if let coordinate = locationManager.currentCoordinate {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))) {
                            Marker("", coordinate: coordinate)
                        }
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        
                        TextField("Spot Name (optional)", text: $spotName)
                    } else {
                        Text("Waiting for location...")
                            .foregroundColor(.saltyTextSecondary)
                    }
                }
                .listRowBackground(Color.saltyCardBackground)
                
                // Fish Entries Section
                Section {
                    ForEach(fishEntries) { entry in
                        FishEntryRow(entry: entry, weightUnit: weightUnit, lengthUnit: lengthUnit)
                    }
                    .onDelete { offsets in
                        fishEntries.remove(atOffsets: offsets)
                    }
                    
                    Button {
                        showAddFish = true
                    } label: {
                        Label("Add Fish", systemImage: "plus.circle.fill")
                            .foregroundColor(.saltyBlue)
                    }
                } header: {
                    Text("Fish Caught")
                } footer: {
                    if !fishEntries.isEmpty {
                        Text("\(fishEntries.count) fish • \(String(format: "%.1f", weightUnit.convert(fromKilograms: fishEntries.compactMap(\.weight).reduce(0, +)))) \(weightUnit.displayName) total")
                    }
                }
                .listRowBackground(Color.saltyCardBackground)
                
                // Conditions Section
                Section("Conditions (Auto-captured)") {
                    LabeledContent("Air Temp") {
                        Text(String(format: "%.0f°F", weatherManager.currentWeather.temperature * 9/5 + 32))
                    }
                    
                    if let waterTemp = marineService.currentMarineData.waterTemperature {
                        LabeledContent("Water Temp") {
                            Text(String(format: "%.0f°F", waterTemp * 9/5 + 32))
                        }
                    }
                    
                    if let tideStatus = marineService.currentMarineData.tideStatus {
                        LabeledContent("Tide") {
                            Text(tideStatus.rawValue)
                        }
                    }
                    
                    LabeledContent("Pressure") {
                        HStack {
                            Text(String(format: "%.0f mb", weatherManager.currentWeather.barometricPressure))
                            Text(weatherManager.currentWeather.pressureTrend.rawValue)
                                .foregroundColor(.saltyTextSecondary)
                        }
                    }
                    
                    LabeledContent("Wind") {
                        Text(String(format: "%.0f mph %@",
                                   weatherManager.currentWeather.windSpeed * 2.237,
                                   HeadingFormatter.cardinalDirection(for: weatherManager.currentWeather.windDirection)))
                    }
                }
                .listRowBackground(Color.saltyCardBackground)
                
                // Notes Section
                Section("Notes") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                .listRowBackground(Color.saltyCardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.saltyBackground)
            .navigationTitle("Mark Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveLog()
                    }
                    .bold()
                    .disabled(locationManager.currentCoordinate == nil)
                }
            }
            .sheet(isPresented: $showAddFish) {
                AddFishSheet(
                    weightUnit: weightUnit,
                    lengthUnit: lengthUnit
                ) { entry in
                    fishEntries.append(entry)
                }
            }
        }
    }
    
    private func saveLog() {
        guard let coordinate = locationManager.currentCoordinate else { return }
        
        _ = fishingLogManager.createLog(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            spotName: spotName.isEmpty ? nil : spotName,
            fishEntries: fishEntries,
            weatherData: weatherManager.currentWeather,
            marineData: marineService.currentMarineData,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

// MARK: - Fish Entry Row
struct FishEntryRow: View {
    let entry: FishEntry
    let weightUnit: WeightUnit
    let lengthUnit: LengthUnit
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.fishType)
                    .font(.subheadline.bold())
                
                HStack(spacing: 8) {
                    if let weight = entry.weight {
                        Text(String(format: "%.1f %@", weightUnit.convert(fromKilograms: weight), weightUnit.displayName))
                    }
                    if let length = entry.length {
                        Text(String(format: "%.1f %@", lengthUnit.convert(fromCentimeters: length), lengthUnit.displayName))
                    }
                }
                .font(.caption)
                .foregroundColor(.saltyTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "fish.fill")
                .foregroundColor(.saltyBlue)
        }
    }
}

// MARK: - Add Fish Sheet
struct AddFishSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let weightUnit: WeightUnit
    let lengthUnit: LengthUnit
    let onSave: (FishEntry) -> Void
    
    @State private var selectedFishType: CommonFishType = .bass
    @State private var customFishType = ""
    @State private var weight = ""
    @State private var length = ""
    @State private var notes = ""
    @State private var useCustomType = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Fish Type") {
                    Toggle("Custom Type", isOn: $useCustomType)
                    
                    if useCustomType {
                        TextField("Fish Type", text: $customFishType)
                    } else {
                        Picker("Type", selection: $selectedFishType) {
                            ForEach(CommonFishType.allCases) { fish in
                                Text("\(fish.icon) \(fish.rawValue)").tag(fish)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }
                .listRowBackground(Color.saltyCardBackground)
                
                Section("Measurements") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("0.0", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(weightUnit.displayName)
                            .foregroundColor(.saltyTextSecondary)
                    }
                    
                    HStack {
                        Text("Length")
                        Spacer()
                        TextField("0.0", text: $length)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(lengthUnit.displayName)
                            .foregroundColor(.saltyTextSecondary)
                    }
                }
                .listRowBackground(Color.saltyCardBackground)
                
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                .listRowBackground(Color.saltyCardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.saltyBackground)
            .navigationTitle("Add Fish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        saveFish()
                    }
                    .bold()
                    .disabled(fishType.isEmpty)
                }
            }
        }
    }
    
    private var fishType: String {
        useCustomType ? customFishType : selectedFishType.rawValue
    }
    
    private func saveFish() {
        let weightKg = Double(weight).map { weightUnit.convertToKilograms($0) }
        let lengthCm = Double(length).map { lengthUnit.convertToCentimeters($0) }
        
        let entry = FishEntry(
            fishType: fishType,
            weight: weightKg,
            length: lengthCm,
            notes: notes.isEmpty ? nil : notes
        )
        
        onSave(entry)
        dismiss()
    }
}

// MARK: - Log Detail Sheet
struct LogDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let log: FishingLog
    @ObservedObject var fishingLogManager: FishingLogManager
    let weightUnit: WeightUnit
    let lengthUnit: LengthUnit
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignConstants.componentSpacing) {
                    // Map
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: log.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))) {
                        Marker(log.spotName ?? "Fishing Spot", coordinate: log.coordinate)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cardCornerRadius))
                    
                    // Fish Caught
                    if !log.fishEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fish Caught")
                                .font(.headline)
                            
                            ForEach(log.fishEntries) { entry in
                                FishEntryRow(entry: entry, weightUnit: weightUnit, lengthUnit: lengthUnit)
                                    .padding()
                                    .background(Color.saltyDarkPanel)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .saltyCardStyle()
                    }
                    
                    // Conditions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Conditions")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            conditionDetail(title: "Air Temp", value: String(format: "%.0f°F", log.weatherSnapshot.temperature * 9/5 + 32))
                            
                            if let waterTemp = log.marineSnapshot.waterTemperature {
                                conditionDetail(title: "Water Temp", value: String(format: "%.0f°F", waterTemp * 9/5 + 32))
                            }
                            
                            if let tideStatus = log.marineSnapshot.tideStatus {
                                conditionDetail(title: "Tide", value: tideStatus)
                            }
                            
                            conditionDetail(title: "Pressure", value: String(format: "%.0f mb", log.weatherSnapshot.barometricPressure))
                            conditionDetail(title: "Wind", value: String(format: "%.0f mph", log.weatherSnapshot.windSpeed * 2.237))
                            conditionDetail(title: "Humidity", value: String(format: "%.0f%%", log.weatherSnapshot.humidity))
                        }
                    }
                    .saltyCardStyle()
                    
                    // Notes
                    if let notes = log.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .foregroundColor(.saltyTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .saltyCardStyle()
                    }
                }
                .padding(DesignConstants.screenPadding)
            }
            .background(Color.saltyBackground)
            .navigationTitle(log.spotName ?? log.formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        fishingLogManager.toggleFavorite(log)
                    } label: {
                        Image(systemName: log.isFavorite ? "star.fill" : "star")
                            .foregroundColor(log.isFavorite ? .yellow : .saltyTextSecondary)
                    }
                }
            }
        }
    }
    
    private func conditionDetail(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.saltyTextPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(.saltyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.saltyDarkPanel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Statistics Sheet
struct StatisticsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let statistics: FishingStatistics
    let weightUnit: WeightUnit
    let lengthUnit: LengthUnit
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignConstants.componentSpacing) {
                    // Summary Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statCard(title: "Total Trips", value: "\(statistics.totalLogs)", icon: "calendar")
                        statCard(title: "Total Fish", value: "\(statistics.totalFish)", icon: "fish")
                        statCard(
                            title: "Total Weight",
                            value: String(format: "%.1f %@",
                                         weightUnit.convert(fromKilograms: statistics.totalWeight),
                                         weightUnit.displayName),
                            icon: "scalemass"
                        )
                        statCard(
                            title: "Avg Fish/Trip",
                            value: String(format: "%.1f", statistics.averageFishPerTrip),
                            icon: "chart.line.uptrend.xyaxis"
                        )
                    }
                    
                    // Records
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Records")
                            .font(.headline)
                        
                        if let biggest = statistics.biggestFishWeight {
                            recordRow(
                                title: "Biggest Fish",
                                value: String(format: "%.1f %@", weightUnit.convert(fromKilograms: biggest), weightUnit.displayName),
                                icon: "trophy.fill"
                            )
                        }
                        
                        if let longest = statistics.longestFish {
                            recordRow(
                                title: "Longest Fish",
                                value: String(format: "%.1f %@", lengthUnit.convert(fromCentimeters: longest), lengthUnit.displayName),
                                icon: "ruler"
                            )
                        }
                        
                        if let mostCaught = statistics.mostCaughtFish {
                            recordRow(
                                title: "Most Caught",
                                value: mostCaught,
                                icon: "repeat"
                            )
                        }
                    }
                    .saltyCardStyle()
                    
                    // Fish Types
                    if !statistics.uniqueFishTypes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fish Types Caught")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(Array(statistics.uniqueFishTypes).sorted(), id: \.self) { fishType in
                                    Text(fishType)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.saltyBlue.opacity(0.2))
                                        .foregroundColor(.saltyBlue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .saltyCardStyle()
                    }
                }
                .padding(DesignConstants.screenPadding)
            }
            .background(Color.saltyBackground)
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.saltyBlue)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.saltyTextPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(.saltyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.saltyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cardCornerRadius))
    }
    
    private func recordRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.saltyOrange)
            Text(title)
                .foregroundColor(.saltyTextSecondary)
            Spacer()
            Text(value)
                .bold()
                .foregroundColor(.saltyTextPrimary)
        }
        .padding()
        .background(Color.saltyDarkPanel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: width, height: y + lineHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    FishingView(
        locationManager: LocationManager(),
        weatherManager: WeatherManager()
    )
}

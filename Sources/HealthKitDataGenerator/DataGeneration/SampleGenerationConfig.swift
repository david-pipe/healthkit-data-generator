import Foundation

/// Configuration for generating health samples
public struct SampleGenerationConfig: Codable {
    /// The health profile to use for generation
    public let profile: HealthProfile
    
    /// Date range for sample generation
    public let dateRange: DateRange
    
    /// Which metrics to generate
    public let metricsToGenerate: Set<HealthMetric>
    
    /// Generation pattern (continuous, sparse, etc.)
    public let pattern: GenerationPattern
    
    /// Random seed for reproducible generation
    public let randomSeed: Int?
    
    /// Custom overrides for specific metrics
    public let customOverrides: [String: MetricOverride]?
    
    public init(
        profile: HealthProfile,
        dateRange: DateRange,
        metricsToGenerate: Set<HealthMetric> = HealthMetric.standardMetrics,
        pattern: GenerationPattern = .continuous,
        randomSeed: Int? = nil,
        customOverrides: [String: MetricOverride]? = nil
    ) {
        self.profile = profile
        self.dateRange = dateRange
        self.metricsToGenerate = metricsToGenerate
        self.pattern = pattern
        self.randomSeed = randomSeed
        self.customOverrides = customOverrides
    }
}

// MARK: - Date Range

public struct DateRange: Codable {
    public let startDate: Date
    public let endDate: Date
    
    /// Number of days in the range
    public var numberOfDays: Int {
        let calendar = Calendar.newZealand
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return max(1, components.day ?? 1)
    }
    
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    /// Create a range for the last N days
    public static func lastDays(_ days: UInt) -> DateRange {
        let end = Date()
        let start = Calendar.newZealand.date(byAdding: .day, value: min(0, -Int(days)), to: end)!
        return DateRange(startDate: start, endDate: end)
    }
    
    /// Create a range for a specific date
    public static func singleDay(_ date: Date) -> DateRange {
        let calendar = Calendar.newZealand
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return DateRange(startDate: start, endDate: end)
    }
}

// MARK: - Health Metrics

public enum HealthMetric: String, Codable, CaseIterable, Hashable {
    // Activity
    case steps = "steps"
    case heartRate = "heart_rate"
    case heartRateVariability = "heart_rate_variability"
    case sleepAnalysis = "sleep_analysis"
    case workouts = "workouts"
    case activeEnergy = "active_energy"
    case basalEnergy = "basal_energy"
    case respiratoryRate = "respiratory_rate"
    case oxygenSaturation = "oxygen_saturation"

    // Vitals
    case bloodPressure = "blood_pressure"
    case bloodGlucose = "blood_glucose"

    // Body
    case bodyMass = "body_mass"
    case bodyFat = "body_fat"
    case leanBodyMass = "lean_body_mass"

    // Nutrition & Wellness
    case water = "water"
    case mindfulMinutes = "mindful_minutes"
    case dietarySugar = "dietary_sugar"
    case dietaryProtein = "dietary_protein"
    case dietaryCarbs = "dietary_carbs"
    case dietaryFat = "dietary_fat"

    // MARK: Reproductive Health
    case menstrualFlow = "menstrual_flow"
    case intermenstrualBleeding = "intermenstrual_bleeding"
    case cervicalMucusQuality = "cervical_mucus_quality"
    case ovulationTestResult = "ovulation_test_result"
    case pregnancyTestResult = "pregnancy_test_result"           // iOS 15+
    case progesteroneTestResult = "progesterone_test_result"     // iOS 15+
    case sexualActivity = "sexual_activity"
    case contraceptive = "contraceptive"                         // iOS 14.3+
    case pregnancy = "pregnancy"                                 // iOS 14.3+
    case lactation = "lactation"                                 // iOS 14.3+
    case bleedingAfterPregnancy = "bleeding_after_pregnancy"     // iOS 18+
    case bleedingDuringPregnancy = "bleeding_during_pregnancy"   // iOS 18+

    // MARK: Reproductive Health - Cycle Irregularities (iOS 16+)
    case infrequentMenstrualCycles = "infrequent_menstrual_cycles"
    case irregularMenstrualCycles = "irregular_menstrual_cycles"
    case persistentIntermenstrualBleeding = "persistent_intermenstrual_bleeding"
    case prolongedMenstrualPeriods = "prolonged_menstrual_periods"

    // MARK: Reproductive Health - Symptoms (iOS 13.6+, HKCategoryValueSeverity)
    case abdominalCramps = "abdominal_cramps"
    case acne = "acne"
    case appetiteChanges = "appetite_changes"
    case bladderIncontinence = "bladder_incontinence"
    case bloating = "bloating"
    case breastPain = "breast_pain"
    case chills = "chills"
    case constipation = "constipation"
    case diarrhea = "diarrhea"
    case dizziness = "dizziness"
    case drySkin = "dry_skin"
    case fatigue = "fatigue"
    case hairLoss = "hair_loss"
    case headache = "headache"
    case hotFlashes = "hot_flashes"
    case lowerBackPain = "lower_back_pain"
    case memoryLapse = "memory_lapse"
    case moodChanges = "mood_changes"
    case nausea = "nausea"
    case nightSweats = "night_sweats"
    case pelvicPain = "pelvic_pain"
    case rapidPoundingOrFlutteringHeartbeat = "rapid_pounding_or_fluttering_heartbeat"
    case runnyNose = "runny_nose"
    case sinusCongestion = "sinus_congestion"
    case skippedHeartbeat = "skipped_heartbeat"
    case sleepChanges = "sleep_changes"
    case soreThroat = "sore_throat"
    case vaginalDryness = "vaginal_dryness"
    case vomiting = "vomiting"
    case bodyAndMuscleAche = "body_and_muscle_ache"
    case chestTightnessOrPain = "chest_tightness_or_pain"
    case coughing = "coughing"
    case fainting = "fainting"
    case fever = "fever"
    case heartburn = "heartburn"
    case lossOfSmell = "loss_of_smell"
    case lossOfTaste = "loss_of_taste"
    case shortnessOfBreath = "shortness_of_breath"
    case wheezing = "wheezing"

    /// All non-reproductive metrics — safe for all profiles and the default for generation.
    public static let standardMetrics: Set<HealthMetric> = Set(HealthMetric.allCases)
        .subtracting(HealthMetric.reproductiveMetrics)
        .subtracting(HealthMetric.cycleIrregularityMetrics)
        .subtracting(HealthMetric.symptomMetrics)

    /// Core reproductive cycle metrics — opt-in only; not included in standard generation.
    public static let reproductiveMetrics: Set<HealthMetric> = [
        .menstrualFlow, .intermenstrualBleeding, .cervicalMucusQuality,
        .ovulationTestResult, .pregnancyTestResult, .progesteroneTestResult,
        .sexualActivity, .contraceptive, .pregnancy, .lactation,
        .bleedingAfterPregnancy, .bleedingDuringPregnancy
    ]

    /// Cycle irregularity metrics — READ-ONLY. Computed by HealthKit from logged cycle data.
    /// These are available to query but cannot be written by third-party apps.
    /// Do NOT include in metricsToGenerate.
    public static let cycleIrregularityMetrics: Set<HealthMetric> = [
        .infrequentMenstrualCycles, .irregularMenstrualCycles,
        .persistentIntermenstrualBleeding, .prolongedMenstrualPeriods
    ]

    /// Symptom metrics — opt-in only; tied to cycle phase and health profile.
    public static let symptomMetrics: Set<HealthMetric> = [
        .abdominalCramps, .acne, .appetiteChanges, .bladderIncontinence,
        .bloating, .breastPain, .chills, .constipation, .diarrhea,
        .dizziness, .drySkin, .fatigue, .hairLoss, .headache,
        .hotFlashes, .lowerBackPain, .memoryLapse, .moodChanges,
        .nausea, .nightSweats, .pelvicPain, .rapidPoundingOrFlutteringHeartbeat,
        .runnyNose, .sinusCongestion, .skippedHeartbeat, .sleepChanges,
        .soreThroat, .vaginalDryness, .vomiting,
        .bodyAndMuscleAche, .chestTightnessOrPain, .coughing, .fainting,
        .fever, .heartburn, .lossOfSmell, .lossOfTaste,
        .shortnessOfBreath, .wheezing
    ]

    /// All writable reproductive health metrics (cycle + symptoms). For generation use.
    /// Note: cycleIrregularityMetrics are excluded — they are read-only and cannot be generated.
    public static let allReproductiveMetrics: Set<HealthMetric> =
        reproductiveMetrics.union(symptomMetrics)

    /// HealthKit identifier mapping
    public var healthKitIdentifier: String {
        switch self {
        case .steps:                  return "HKQuantityTypeIdentifierStepCount"
        case .heartRate:              return "HKQuantityTypeIdentifierHeartRate"
        case .heartRateVariability:   return "HKQuantityTypeIdentifierHeartRateVariabilitySDNN"
        case .sleepAnalysis:          return "HKCategoryTypeIdentifierSleepAnalysis"
        case .workouts:               return "HKWorkoutTypeIdentifier"
        case .activeEnergy:           return "HKQuantityTypeIdentifierActiveEnergyBurned"
        case .basalEnergy:            return "HKQuantityTypeIdentifierBasalEnergyBurned"
        case .bloodPressure:          return "HKCorrelationTypeIdentifierBloodPressure"
        case .bloodGlucose:           return "HKQuantityTypeIdentifierBloodGlucose"
        case .bodyMass:               return "HKQuantityTypeIdentifierBodyMass"
        case .bodyFat:                return "HKQuantityTypeIdentifierBodyFatPercentage"
        case .leanBodyMass:           return "HKQuantityTypeIdentifierLeanBodyMass"
        case .water:                  return "HKQuantityTypeIdentifierDietaryWater"
        case .mindfulMinutes:         return "HKCategoryTypeIdentifierMindfulSession"
        case .dietarySugar:           return "HKQuantityTypeIdentifierDietarySugar"
        case .dietaryProtein:         return "HKQuantityTypeIdentifierDietaryProtein"
        case .dietaryCarbs:           return "HKQuantityTypeIdentifierDietaryCarbohydrates"
        case .dietaryFat:             return "HKQuantityTypeIdentifierDietaryFatTotal"
        case .respiratoryRate:        return "HKQuantityTypeIdentifierRespiratoryRate"
        case .oxygenSaturation:       return "HKQuantityTypeIdentifierOxygenSaturation"
        // Reproductive Health
        case .menstrualFlow:          return "HKCategoryTypeIdentifierMenstrualFlow"
        case .intermenstrualBleeding: return "HKCategoryTypeIdentifierIntermenstrualBleeding"
        case .cervicalMucusQuality:   return "HKCategoryTypeIdentifierCervicalMucusQuality"
        case .ovulationTestResult:    return "HKCategoryTypeIdentifierOvulationTestResult"
        case .pregnancyTestResult:    return "HKCategoryTypeIdentifierPregnancyTestResult"
        case .progesteroneTestResult: return "HKCategoryTypeIdentifierProgesteroneTestResult"
        case .sexualActivity:         return "HKCategoryTypeIdentifierSexualActivity"
        case .contraceptive:          return "HKCategoryTypeIdentifierContraceptive"
        case .pregnancy:              return "HKCategoryTypeIdentifierPregnancy"
        case .lactation:              return "HKCategoryTypeIdentifierLactation"
        // Cycle Irregularities
        case .infrequentMenstrualCycles:
            return "HKCategoryTypeIdentifierInfrequentMenstrualCycles"
        case .irregularMenstrualCycles:
            return "HKCategoryTypeIdentifierIrregularMenstrualCycles"
        case .persistentIntermenstrualBleeding:
            return "HKCategoryTypeIdentifierPersistentIntermenstrualBleeding"
        case .prolongedMenstrualPeriods:
            return "HKCategoryTypeIdentifierProlongedMenstrualPeriods"
        // Symptoms (HKCategoryValueSeverity: notPresent=1, mild=2, moderate=3, severe=4)
        case .abdominalCramps:                         return "HKCategoryTypeIdentifierAbdominalCramps"
        case .acne:                                    return "HKCategoryTypeIdentifierAcne"
        case .appetiteChanges:                         return "HKCategoryTypeIdentifierAppetiteChanges"
        case .bladderIncontinence:                     return "HKCategoryTypeIdentifierBladderIncontinence"
        case .bloating:                                return "HKCategoryTypeIdentifierBloating"
        case .breastPain:                              return "HKCategoryTypeIdentifierBreastPain"
        case .chills:                                  return "HKCategoryTypeIdentifierChills"
        case .constipation:                            return "HKCategoryTypeIdentifierConstipation"
        case .diarrhea:                                return "HKCategoryTypeIdentifierDiarrhea"
        case .dizziness:                               return "HKCategoryTypeIdentifierDizziness"
        case .drySkin:                                 return "HKCategoryTypeIdentifierDrySkin"
        case .fatigue:                                 return "HKCategoryTypeIdentifierFatigue"
        case .hairLoss:                                return "HKCategoryTypeIdentifierHairLoss"
        case .headache:                                return "HKCategoryTypeIdentifierHeadache"
        case .hotFlashes:                              return "HKCategoryTypeIdentifierHotFlashes"
        case .lowerBackPain:                           return "HKCategoryTypeIdentifierLowerBackPain"
        case .memoryLapse:                             return "HKCategoryTypeIdentifierMemoryLapse"
        case .moodChanges:                             return "HKCategoryTypeIdentifierMoodChanges"
        case .nausea:                                  return "HKCategoryTypeIdentifierNausea"
        case .nightSweats:                             return "HKCategoryTypeIdentifierNightSweats"
        case .pelvicPain:                              return "HKCategoryTypeIdentifierPelvicPain"
        case .rapidPoundingOrFlutteringHeartbeat:
            return "HKCategoryTypeIdentifierRapidPoundingOrFlutteringHeartbeat"
        case .runnyNose:                               return "HKCategoryTypeIdentifierRunnyNose"
        case .sinusCongestion:                         return "HKCategoryTypeIdentifierSinusCongestion"
        case .skippedHeartbeat:                        return "HKCategoryTypeIdentifierSkippedHeartbeat"
        case .sleepChanges:                            return "HKCategoryTypeIdentifierSleepChanges"
        case .soreThroat:                              return "HKCategoryTypeIdentifierSoreThroat"
        case .vaginalDryness:                          return "HKCategoryTypeIdentifierVaginalDryness"
        case .vomiting:                                return "HKCategoryTypeIdentifierVomiting"
        case .bodyAndMuscleAche:                        return "HKCategoryTypeIdentifierGeneralizedBodyAche"
        case .chestTightnessOrPain:                     return "HKCategoryTypeIdentifierChestTightnessOrPain"
        case .coughing:                                 return "HKCategoryTypeIdentifierCoughing"
        case .fainting:                                 return "HKCategoryTypeIdentifierFainting"
        case .fever:                                    return "HKCategoryTypeIdentifierFever"
        case .heartburn:                                return "HKCategoryTypeIdentifierHeartburn"
        case .lossOfSmell:                              return "HKCategoryTypeIdentifierLossOfSmell"
        case .lossOfTaste:                              return "HKCategoryTypeIdentifierLossOfTaste"
        case .shortnessOfBreath:                        return "HKCategoryTypeIdentifierShortnessOfBreath"
        case .wheezing:                                 return "HKCategoryTypeIdentifierWheezing"
        // Reproductive — Bleeding (iOS 18+)
        case .bleedingAfterPregnancy:                   return "HKCategoryTypeIdentifierBleedingAfterPregnancy"
        case .bleedingDuringPregnancy:                  return "HKCategoryTypeIdentifierBleedingDuringPregnancy"
        }
    }
}

// MARK: - Generation Pattern

public enum GenerationPattern: String, Codable, CaseIterable {
    /// Generate samples for every day in the range
    case continuous = "continuous"
    
    /// Generate samples with random gaps
    case sparse = "sparse"
    
    /// Generate samples only on weekdays
    case weekdaysOnly = "weekdays_only"
    
    /// Generate samples only on weekends
    case weekendsOnly = "weekends_only"
    
    /// Custom pattern with specific days
    case custom = "custom"
    
    /// Should generate data for this day?
    public func shouldGenerateForDay(_ date: Date, customDays: Set<Int>? = nil) -> Bool {
        let calendar = Calendar.newZealand
        let weekday = calendar.component(.weekday, from: date)
        
        switch self {
        case .continuous:
            return true
        case .sparse:
            return Int.random(in: 0...100) > 30 // 70% chance
        case .weekdaysOnly:
            return weekday >= 2 && weekday <= 6 // Monday-Friday
        case .weekendsOnly:
            return weekday == 1 || weekday == 7 // Saturday-Sunday
        case .custom:
            let dayOfMonth = calendar.component(.day, from: date)
            return customDays?.contains(dayOfMonth) ?? true
        }
    }
}

// MARK: - Metric Override

public struct MetricOverride: Codable {
    public let multiplier: Double?
    public let fixedValue: Double?
    public let variability: Double? // 0.0-1.0
    public let enabled: Bool?
    public let customRange: ClosedRangeWrapper?
    public let timePattern: TimePattern?
    
    public init(
        multiplier: Double? = nil,
        fixedValue: Double? = nil,
        variability: Double? = nil,
        enabled: Bool? = nil,
        customRange: ClosedRangeWrapper? = nil,
        timePattern: TimePattern? = nil
    ) {
        self.multiplier = multiplier
        self.fixedValue = fixedValue
        self.variability = variability
        self.enabled = enabled
        self.customRange = customRange
        self.timePattern = timePattern
    }
}

/// Wrapper for ClosedRange to make it Codable
public struct ClosedRangeWrapper: Codable {
    public let lowerBound: Double
    public let upperBound: Double
    
    public init(lowerBound: Double, upperBound: Double) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
    
    public init(_ range: ClosedRange<Double>) {
        self.lowerBound = range.lowerBound
        self.upperBound = range.upperBound
    }
    
    public var range: ClosedRange<Double> {
        return lowerBound...upperBound
    }
}

/// Time patterns for metric generation
public enum TimePattern: String, Codable {
    case constant = "constant"
    case morningPeak = "morning_peak"
    case middayPeak = "midday_peak"
    case eveningPeak = "evening_peak"
    case nightPeak = "night_peak"
    
    /// Get multiplier for given hour (0-23)
    public func multiplier(for hour: Int) -> Double {
        switch self {
        case .constant:
            return 1.0
        case .morningPeak: // Peak at 6-10 AM
            if hour >= 6 && hour <= 10 { return 1.5 }
            else if hour >= 4 && hour <= 12 { return 1.2 }
            return 0.8
        case .middayPeak: // Peak at 11 AM - 2 PM
            if hour >= 11 && hour <= 14 { return 1.5 }
            else if hour >= 9 && hour <= 16 { return 1.2 }
            return 0.8
        case .eveningPeak: // Peak at 5-9 PM
            if hour >= 17 && hour <= 21 { return 1.5 }
            else if hour >= 15 && hour <= 23 { return 1.2 }
            return 0.8
        case .nightPeak: // Peak at 10 PM - 2 AM
            if hour >= 22 || hour <= 2 { return 1.5 }
            else if hour >= 20 || hour <= 4 { return 1.2 }
            return 0.8
        }
    }
}

// MARK: - Preset Configurations

extension SampleGenerationConfig {
    /// Last 7 days with sporty profile
    public static func lastWeekSporty() -> SampleGenerationConfig {
        return SampleGenerationConfig(profile: .sporty, dateRange: .lastDays(7))
    }
    
    /// Last 30 days with balanced profile
    public static func lastMonthBalanced() -> SampleGenerationConfig {
        return SampleGenerationConfig(profile: .balanced, dateRange: .lastDays(30))
    }
    
    /// Last 7 days with stressed profile
    public static func lastWeekStressed() -> SampleGenerationConfig {
        return SampleGenerationConfig(profile: .stressed, dateRange: .lastDays(7))
    }
    
    /// Custom configuration from JSON (for LLM integration)
    public static func fromJSON(_ jsonString: String) throws -> SampleGenerationConfig {
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SampleGenerationConfig.self, from: data)
    }
    
    /// Export configuration to JSON (for LLM integration)
    public func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}

// MARK: - Enhanced Date Range Types

extension DateRange {
    public static func specificDates(_ dates: [Date]) -> DateRange {
        guard let start = dates.min(), let end = dates.max() else {
            return DateRange(startDate: Date(), endDate: Date())
        }
        return DateRange(startDate: start, endDate: end)
    }
    
    public static func rangeWithGaps(start: Date, end: Date, excludeDates: [Date]) -> DateRange {
        return DateRange(startDate: start, endDate: end)
    }
    
    public static func weekdaysOnly(start: Date, end: Date) -> DateRange {
        return DateRange(startDate: start, endDate: end)
    }
    
    public static func weekendsOnly(start: Date, end: Date) -> DateRange {
        return DateRange(startDate: start, endDate: end)
    }
    
    public static func thisWeek() -> DateRange {
        let now = Date()
        let weekStart = Calendar.newZealand.date(byAdding: .day, value: -7, to: now) ?? now
        return DateRange(startDate: weekStart, endDate: now)
    }
    
    public static func thisMonth() -> DateRange {
        let now = Date()
        let monthStart = Calendar.newZealand.date(byAdding: .day, value: -30, to: now) ?? now
        return DateRange(startDate: monthStart, endDate: now)
    }
}

// MARK: - Enhanced Generation Patterns

extension GenerationPattern {
    public static func sparseWithProbability(_ probability: Double) -> GenerationPattern {
        return .sparse
    }
    
    public func shouldGenerateForDay(_ date: Date, customDays: Set<Int>? = nil, sparseProbability: Double = 0.7) -> Bool {
        let calendar = Calendar.newZealand
        let weekday = calendar.component(.weekday, from: date)
        
        switch self {
        case .continuous: return true
        case .sparse: return Double.random(in: 0...1) < sparseProbability
        case .weekdaysOnly: return weekday >= 2 && weekday <= 6
        case .weekendsOnly: return weekday == 1 || weekday == 7
        case .custom:
            let dayOfMonth = calendar.component(.day, from: date)
            return customDays?.contains(dayOfMonth) ?? true
        }
    }
}

// MARK: - Advanced Generation Patterns

public enum AdvancedPattern: String, Codable {
    case sparseCustom = "sparse_custom"
    case seasonal = "seasonal"
    case progressive = "progressive"
    case everyNthDay = "every_nth_day"
    case cyclical = "cyclical"
}

public struct AdvancedPatternConfig: Codable {
    public let pattern: AdvancedPattern
    public let sparseProbability: Double?
    public let peakMonths: [Int]?
    public let startMultiplier: Double?
    public let endMultiplier: Double?
    public let interval: Int?
    public let cyclePeriod: Int?
    
    public init(
        pattern: AdvancedPattern,
        sparseProbability: Double? = nil,
        peakMonths: [Int]? = nil,
        startMultiplier: Double? = nil,
        endMultiplier: Double? = nil,
        interval: Int? = nil,
        cyclePeriod: Int? = nil
    ) {
        self.pattern = pattern
        self.sparseProbability = sparseProbability
        self.peakMonths = peakMonths
        self.startMultiplier = startMultiplier
        self.endMultiplier = endMultiplier
        self.interval = interval
        self.cyclePeriod = cyclePeriod
    }
    
    public func shouldGenerateForDay(_ date: Date, totalDays: Int, currentDay: Int) -> Bool {
        let calendar = Calendar.newZealand
        switch pattern {
        case .sparseCustom:
            return Double.random(in: 0...1) < (sparseProbability ?? 0.7)
        case .seasonal:
            let month = calendar.component(.month, from: date)
            return peakMonths?.contains(month) ?? true
        case .progressive:
            return true
        case .everyNthDay:
            return currentDay % (interval ?? 2) == 0
        case .cyclical:
            let period = cyclePeriod ?? 7
            return currentDay % period < period / 2
        }
    }
    
    public func getMultiplier(for currentDay: Int, totalDays: Int) -> Double {
        guard pattern == .progressive else { return 1.0 }
        let start = startMultiplier ?? 1.0
        let end = endMultiplier ?? 1.0
        let progress = Double(currentDay) / Double(max(1, totalDays))
        return start + (end - start) * progress
    }
}

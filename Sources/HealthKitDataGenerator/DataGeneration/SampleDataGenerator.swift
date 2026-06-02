import Foundation
import HealthKit
import Logging

/// Generates realistic sample health data using configuration profiles
public class SampleDataGenerator {
    
    private static let logger = AppLogger.generation
    
    // MARK: - Public Methods
    
    /// Generates sample health data based on configuration
    /// - Parameter config: Configuration specifying profile, date range, and metrics
    /// - Returns: Dictionary containing generated sample data
    public static func generateSamples(config: SampleGenerationConfig) -> [String: Any] {
        logger.info("🎯 Starting sample generation", metadata: [
            "profile": "\(config.profile.name)",
            "startDate": "\(config.dateRange.startDate.formatted())",
            "endDate": "\(config.dateRange.endDate.formatted())",
            "days": "\(config.dateRange.numberOfDays)",
            "metrics": "\(config.metricsToGenerate.count)",
            "pattern": "\(config.pattern.rawValue)"
        ])
        
        var result: [String: Any] = [:]
        let calendar = Calendar.newZealand
        var totalSamplesGenerated = 0
        var daysProcessed = 0
        
        // Set random seed if provided for reproducibility
        if let seed = config.randomSeed {
            srand48(seed)
            logger.debug("Using random seed for reproducibility", metadata: ["seed": "\(seed)"])
        }
        
        // Generate samples for each day in the range
        for dayOffset in 0...config.dateRange.numberOfDays {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: config.dateRange.startDate) else {
                logger.warning("Failed to calculate date", metadata: ["offset": "\(dayOffset)"])
                continue
            }
            
            // Check if we should generate for this day based on pattern
            guard config.pattern.shouldGenerateForDay(dayDate) else {
                logger.debug("Skipping day based on pattern", metadata: [
                    "date": "\(dayDate.formatted())",
                    "pattern": "\(config.pattern.rawValue)"
                ])
                continue
            }
            
            daysProcessed += 1
            var daySamples = 0
            
            // Generate each requested metric
            for metric in config.metricsToGenerate {
                let samples = generateMetric(
                    metric,
                    for: dayDate,
                    profile: config.profile,
                    config: config
                )
                
                if !samples.isEmpty {
                    logger.debug("Generated metric samples", metadata: [
                        "metric": "\(metric.rawValue)",
                        "date": "\(dayDate.formatted(date: .abbreviated, time: .omitted))",
                        "count": "\(samples.count)"
                    ])
                    daySamples += samples.count
                }
                
                let key = metric.healthKitIdentifier
                if var existing = result[key] as? [[String: Any]] {
                    existing.append(contentsOf: samples)
                    result[key] = existing
                } else {
                    result[key] = samples
                }
            }
            
            totalSamplesGenerated += daySamples
            
            if daySamples > 0 {
                logger.debug("Day complete", metadata: [
                    "date": "\(dayDate.formatted(date: .abbreviated, time: .omitted))",
                    "samples": "\(daySamples)"
                ])
            }
        }
        
        logger.info("✅ Sample generation complete", metadata: [
            "daysProcessed": "\(daysProcessed)",
            "totalSamples": "\(totalSamplesGenerated)",
            "metricTypes": "\(result.keys.count)"
        ])
        
        return result
    }
    
    // MARK: - Metric Generation
    
    private static func generateMetric(
        _ metric: HealthMetric,
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        switch metric {
        case .steps:
            return generateSteps(for: date, profile: profile, config: config)
        case .heartRate:
            return generateHeartRate(for: date, profile: profile, config: config)
        case .heartRateVariability:
            return generateHRV(for: date, profile: profile, config: config)
        case .sleepAnalysis:
            return generateSleep(for: date, profile: profile, config: config)
        case .workouts:
            return generateWorkouts(for: date, profile: profile, config: config)
        case .activeEnergy:
            return generateActiveEnergy(for: date, profile: profile, config: config)
        case .basalEnergy:
            return generateBasalEnergy(for: date, profile: profile, config: config)
        case .bloodPressure:
            return generateBloodPressure(for: date, profile: profile, config: config)
        case .bodyMass:
            return generateBodyMass(for: date, profile: profile, config: config)
        case .water:
            return generateWater(for: date, profile: profile, config: config)
        case .mindfulMinutes:
            return generateMindfulness(for: date, profile: profile, config: config)
        case .dietarySugar:
            return generateDietarySugar(for: date, profile: profile, config: config)
        case .dietaryProtein:
            return generateDietaryProtein(for: date, profile: profile, config: config)
        case .dietaryCarbs:
            return generateDietaryCarbs(for: date, profile: profile, config: config)
        case .dietaryFat:
            return generateDietaryFat(for: date, profile: profile, config: config)
        case .respiratoryRate:
            return generateRespiratoryRate(for: date, profile: profile, config: config)
        case .oxygenSaturation:
            return generateOxygenSaturation(for: date, profile: profile, config: config)
        // Reproductive Health
        case .menstrualFlow:
            return generateMenstrualFlow(for: date, profile: profile, config: config)
        case .intermenstrualBleeding:
            return generateIntermenstrualBleeding(for: date, profile: profile, config: config)
        case .cervicalMucusQuality:
            return generateCervicalMucusQuality(for: date, profile: profile, config: config)
        case .ovulationTestResult:
            return generateOvulationTestResult(for: date, profile: profile, config: config)
        case .pregnancyTestResult:
            return generatePregnancyTestResult(for: date, profile: profile, config: config)
        case .progesteroneTestResult:
            return generateProgesteroneTestResult(for: date, profile: profile, config: config)
        case .sexualActivity:
            return generateSexualActivity(for: date, profile: profile, config: config)
        case .contraceptive:
            return generateContraceptive(for: date, profile: profile, config: config)
        case .pregnancy:
            return generatePregnancy(for: date, profile: profile, config: config)
        case .lactation:
            return generateLactation(for: date, profile: profile, config: config)
        // Cycle Irregularities — READ-ONLY, computed by HealthKit. Cannot be written by apps.
        case .infrequentMenstrualCycles,
             .irregularMenstrualCycles,
             .persistentIntermenstrualBleeding,
             .prolongedMenstrualPeriods:
            return []
        // Symptoms
        case .abdominalCramps:
            return generateAbdominalCramps(for: date, profile: profile, config: config)
        case .acne:
            return generateAcne(for: date, profile: profile, config: config)
        case .appetiteChanges:
            return generateAppetiteChanges(for: date, profile: profile, config: config)
        case .bladderIncontinence:
            return generateBladderIncontinence(for: date, profile: profile, config: config)
        case .bloating:
            return generateBloating(for: date, profile: profile, config: config)
        case .breastPain:
            return generateBreastPain(for: date, profile: profile, config: config)
        case .chills:
            return generateChills(for: date, profile: profile, config: config)
        case .constipation:
            return generateConstipation(for: date, profile: profile, config: config)
        case .diarrhea:
            return generateDiarrhea(for: date, profile: profile, config: config)
        case .dizziness:
            return generateDizziness(for: date, profile: profile, config: config)
        case .drySkin:
            return generateDrySkin(for: date, profile: profile, config: config)
        case .fatigue:
            return generateFatigue(for: date, profile: profile, config: config)
        case .hairLoss:
            return generateHairLoss(for: date, profile: profile, config: config)
        case .headache:
            return generateHeadache(for: date, profile: profile, config: config)
        case .hotFlashes:
            return generateHotFlashes(for: date, profile: profile, config: config)
        case .lowerBackPain:
            return generateLowerBackPain(for: date, profile: profile, config: config)
        case .memoryLapse:
            return generateMemoryLapse(for: date, profile: profile, config: config)
        case .moodChanges:
            return generateMoodChanges(for: date, profile: profile, config: config)
        case .nausea:
            return generateNausea(for: date, profile: profile, config: config)
        case .nightSweats:
            return generateNightSweats(for: date, profile: profile, config: config)
        case .pelvicPain:
            return generatePelvicPain(for: date, profile: profile, config: config)
        case .rapidPoundingOrFlutteringHeartbeat:
            return generateRapidPoundingOrFlutteringHeartbeat(for: date, profile: profile, config: config)
        case .runnyNose:
            return generateRunnyNose(for: date, profile: profile, config: config)
        case .sinusCongestion:
            return generateSinusCongestion(for: date, profile: profile, config: config)
        case .skippedHeartbeat:
            return generateSkippedHeartbeat(for: date, profile: profile, config: config)
        case .sleepChanges:
            return generateSleepChanges(for: date, profile: profile, config: config)
        case .soreThroat:
            return generateSoreThroat(for: date, profile: profile, config: config)
        case .vaginalDryness:
            return generateVaginalDryness(for: date, profile: profile, config: config)
        case .vomiting:
            return generateVomiting(for: date, profile: profile, config: config)
        case .bodyAndMuscleAche:
            return generateBodyAndMuscleAche(for: date, profile: profile, config: config)
        case .chestTightnessOrPain:
            return generateChestTightnessOrPain(for: date, profile: profile, config: config)
        case .coughing:
            return generateCoughing(for: date, profile: profile, config: config)
        case .fainting:
            return generateFainting(for: date, profile: profile, config: config)
        case .fever:
            return generateFever(for: date, profile: profile, config: config)
        case .heartburn:
            return generateHeartburn(for: date, profile: profile, config: config)
        case .lossOfSmell:
            return generateLossOfSmell(for: date, profile: profile, config: config)
        case .lossOfTaste:
            return generateLossOfTaste(for: date, profile: profile, config: config)
        case .shortnessOfBreath:
            return generateShortnessOfBreath(for: date, profile: profile, config: config)
        case .wheezing:
            return generateWheezing(for: date, profile: profile, config: config)
        case .bleedingAfterPregnancy:
            return generateBleedingAfterPregnancy(for: date, profile: profile, config: config)
        case .bleedingDuringPregnancy:
            return generateBleedingDuringPregnancy(for: date, profile: profile, config: config)
        default:
            return [] // Not yet implemented
        }
    }
    
    // MARK: - Steps Generation
    
    private static func generateSteps(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        var samples: [[String: Any]] = []
        
        // Generate steps throughout the day
        let targetSteps = Int.random(in: profile.dailyStepsRange)
        let numberOfSamples = Int.random(in: 8...15)
        
        for i in 0..<numberOfSamples {
            let hour = 7 + (i * 14 / numberOfSamples) // Spread from 7am to 9pm
            guard let sampleTime = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) else {
                continue
            }
            
            let steps = targetSteps / numberOfSamples + Int.random(in: -100...100)
            
            samples.append([
                "sdate": DateFormatter.iso8601.string(from: sampleTime),
                "value": max(0, steps),
                "unit": "count"
            ])
        }
        
        return samples
    }
    
    // MARK: - Heart Rate Generation
    
    private static func generateHeartRate(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        var samples: [[String: Any]] = []
        
        // Generate resting heart rate samples throughout the day
        let restingHR = Int.random(in: profile.restingHeartRateRange)
        
        for hour in 0..<24 {
            for _ in 0..<Int.random(in: 1...3) {
                guard let sampleTime = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) else {
                    continue
                }
                
                // Vary heart rate based on time of day and activity
                var hr = restingHR
                if hour >= 7 && hour <= 22 { // Awake hours
                    hr += Int.random(in: 5...20)
                }
                
                samples.append([
                    "sdate": DateFormatter.iso8601.string(from: sampleTime),
                    "value": hr,
                    "unit": "count/min"
                ])
            }
        }
        
        return samples
    }
    
    // MARK: - HRV Generation
    
    private static func generateHRV(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        guard let morningTime = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: date) else {
            return []
        }
        
        let hrv = Int.random(in: profile.heartRateVariability.variabilityRange)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: morningTime),
            "value": hrv,
            "unit": "ms"
        ]]
    }
    
    // MARK: - Sleep Generation
    
    private static func generateSleep(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        var samples: [[String: Any]] = []
        
        // Calculate sleep duration based on quality
        let baseSleepDuration = Double.random(in: profile.sleepDurationRange)
        let sleepDuration: Double
        
        // Adjust sleep duration based on quality
        switch profile.sleepQuality {
        case .poor:
            sleepDuration = baseSleepDuration * Double.random(in: 0.6...0.8)
        case .fair:
            sleepDuration = baseSleepDuration * Double.random(in: 0.8...0.9)
        case .good:
            sleepDuration = baseSleepDuration * Double.random(in: 0.9...1.0)
        case .excellent:
            sleepDuration = baseSleepDuration * Double.random(in: 1.0...1.1)
        }
        
        // Adjust bedtime based on sleep quality
        let baseBedtimeHour = Int.random(in: profile.bedtimeRange) % 24
        let bedtimeHour: Int
        
        switch profile.sleepQuality {
        case .poor:
            bedtimeHour = (baseBedtimeHour + Int.random(in: 1...3)) % 24
        case .fair:
            bedtimeHour = (baseBedtimeHour + Int.random(in: 0...2)) % 24
        case .good, .excellent:
            bedtimeHour = baseBedtimeHour
        }
        
        // Sleep start time (previous day if bedtime is late)
        var sleepStart: Date
        if bedtimeHour >= 20 {
            sleepStart = calendar.date(bySettingHour: bedtimeHour, minute: Int.random(in: 0...59), second: 0, of: date)!
        } else {
            let previousDay = calendar.date(byAdding: .day, value: -1, to: date)!
            sleepStart = calendar.date(bySettingHour: bedtimeHour, minute: Int.random(in: 0...59), second: 0, of: previousDay)!
        }
        
        let baseSleepEnd = sleepStart.addingTimeInterval(sleepDuration * 3600)
        let sleepEnd: Date
        
        switch profile.sleepQuality {
        case .poor:
            let wakeVariability = Double.random(in: -1.0...0.5)
            sleepEnd = baseSleepEnd.addingTimeInterval(wakeVariability * 3600)
        case .fair:
            let wakeVariability = Double.random(in: -0.5...0.5)
            sleepEnd = baseSleepEnd.addingTimeInterval(wakeVariability * 3600)
        case .good, .excellent:
            let wakeVariability = Double.random(in: -0.25...0.25)
            sleepEnd = baseSleepEnd.addingTimeInterval(wakeVariability * 3600)
        }
        
        let deepSleepPercentage = Double.random(in: profile.sleepQuality.deepSleepPercentage)
        let deepSleepDuration = sleepDuration * deepSleepPercentage
        
        let remPercentage = profile.sleepQuality == .poor ? 0.10...0.15 :
                           profile.sleepQuality == .fair ? 0.15...0.18 :
                           profile.sleepQuality == .good ? 0.18...0.22 : 0.20...0.25
        let remSleepDuration = sleepDuration * Double.random(in: remPercentage)
        
        let awakePercentage = profile.sleepQuality == .poor ? 0.15...0.30 :
                             profile.sleepQuality == .fair ? 0.08...0.15 :
                             profile.sleepQuality == .good ? 0.03...0.08 : 0.01...0.05
        let awakeDuration = sleepDuration * Double.random(in: awakePercentage)
        let lightSleepDuration = sleepDuration - deepSleepDuration - remSleepDuration - awakeDuration
        
        if profile.sleepQuality == .poor {
            generateFragmentedSleep(
                sleepStart: sleepStart,
                sleepEnd: sleepEnd,
                deepSleepDuration: deepSleepDuration,
                remSleepDuration: remSleepDuration,
                lightSleepDuration: lightSleepDuration,
                awakeDuration: awakeDuration,
                samples: &samples
            )
        } else {
            generateNormalSleep(
                sleepStart: sleepStart,
                sleepEnd: sleepEnd,
                deepSleepDuration: deepSleepDuration,
                remSleepDuration: remSleepDuration,
                lightSleepDuration: lightSleepDuration,
                awakeDuration: awakeDuration,
                samples: &samples
            )
        }
        
        return samples
    }
    
    // MARK: - Sleep Pattern Helpers
    
    private static func generateFragmentedSleep(
        sleepStart: Date,
        sleepEnd: Date,
        deepSleepDuration: Double,
        remSleepDuration: Double,
        lightSleepDuration: Double,
        awakeDuration: Double,
        samples: inout [[String: Any]]
    ) {
        var currentTime = sleepStart
        let totalDuration = sleepEnd.timeIntervalSince(sleepStart) / 3600

        let sleepPeriods = Int.random(in: 3...6)
        let awakePeriods = sleepPeriods - 1

        let periodDuration = totalDuration / Double(sleepPeriods)
        let awakePeriodDuration = awakeDuration / Double(awakePeriods)

        for i in 0..<sleepPeriods {
            let periodStart = currentTime
            let periodEnd = currentTime.addingTimeInterval(periodDuration * 3600)

            let periodDeepSleep = deepSleepDuration / Double(sleepPeriods)
            let periodRemSleep = remSleepDuration / Double(sleepPeriods)
            let periodLightSleep = periodDuration - (periodDeepSleep + periodRemSleep)

            let lightEnd = periodStart.addingTimeInterval(periodLightSleep * 3600)
            samples.append([
                "sdate": DateFormatter.iso8601.string(from: periodStart),
                "edate": DateFormatter.iso8601.string(from: lightEnd),
                "value": HKCategoryValueSleepAnalysis.asleepCore.rawValue
            ])

            if periodDeepSleep > 0.1 {
                let deepEnd = lightEnd.addingTimeInterval(periodDeepSleep * 3600)
                samples.append([
                    "sdate": DateFormatter.iso8601.string(from: lightEnd),
                    "edate": DateFormatter.iso8601.string(from: deepEnd),
                    "value": HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                ])
                currentTime = deepEnd
            } else {
                currentTime = lightEnd
            }

            if periodRemSleep > 0.1 {
                let remEnd = currentTime.addingTimeInterval(periodRemSleep * 3600)
                samples.append([
                    "sdate": DateFormatter.iso8601.string(from: currentTime),
                    "edate": DateFormatter.iso8601.string(from: remEnd),
                    "value": HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ])
                currentTime = remEnd
            }

            // Awake period between sleep segments
            if i < awakePeriods {
                let awakeEnd = currentTime.addingTimeInterval(awakePeriodDuration * 3600)
                samples.append([
                    "sdate": DateFormatter.iso8601.string(from: currentTime),
                    "edate": DateFormatter.iso8601.string(from: awakeEnd),
                    "value": HKCategoryValueSleepAnalysis.awake.rawValue
                ])
                currentTime = awakeEnd
            }
        }
    }

    private static func generateNormalSleep(
        sleepStart: Date,
        sleepEnd: Date,
        deepSleepDuration: Double,
        remSleepDuration: Double,
        lightSleepDuration: Double,
        awakeDuration: Double,
        samples: inout [[String: Any]]
    ) {
        var currentTime = sleepStart

        // Initial light sleep
        let initialLightDuration = lightSleepDuration * 0.3
        let firstLightEnd = currentTime.addingTimeInterval(initialLightDuration * 3600)
        samples.append([
            "sdate": DateFormatter.iso8601.string(from: currentTime),
            "edate": DateFormatter.iso8601.string(from: firstLightEnd),
            "value": HKCategoryValueSleepAnalysis.asleepCore.rawValue
        ])
        currentTime = firstLightEnd

        // Deep sleep
        if deepSleepDuration > 0 {
            let deepEnd = currentTime.addingTimeInterval(deepSleepDuration * 3600)
            samples.append([
                "sdate": DateFormatter.iso8601.string(from: currentTime),
                "edate": DateFormatter.iso8601.string(from: deepEnd),
                "value": HKCategoryValueSleepAnalysis.asleepDeep.rawValue
            ])
            currentTime = deepEnd
        }

        // Middle light sleep
        let middleLightDuration = lightSleepDuration * 0.4
        let middleLightEnd = currentTime.addingTimeInterval(middleLightDuration * 3600)
        samples.append([
            "sdate": DateFormatter.iso8601.string(from: currentTime),
            "edate": DateFormatter.iso8601.string(from: middleLightEnd),
            "value": HKCategoryValueSleepAnalysis.asleepCore.rawValue
        ])
        currentTime = middleLightEnd

        // REM sleep
        if remSleepDuration > 0 {
            let remEnd = currentTime.addingTimeInterval(remSleepDuration * 3600)
            samples.append([
                "sdate": DateFormatter.iso8601.string(from: currentTime),
                "edate": DateFormatter.iso8601.string(from: remEnd),
                "value": HKCategoryValueSleepAnalysis.asleepREM.rawValue
            ])
            currentTime = remEnd
        }

        // Final light sleep phase
        samples.append([
            "sdate": DateFormatter.iso8601.string(from: currentTime),
            "edate": DateFormatter.iso8601.string(from: sleepEnd),
            "value": HKCategoryValueSleepAnalysis.asleepCore.rawValue
        ])
    }
    
    // MARK: - Workouts Generation
    
    private static func generateWorkouts(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        var samples: [[String: Any]] = []
        
        // Determine if there should be a workout today
        let sessionsPerWeek = profile.workoutFrequency.sessionsPerWeek
        let shouldHaveWorkout = Int.random(in: 0...6) < sessionsPerWeek.upperBound
        
        guard shouldHaveWorkout, !profile.preferredWorkoutTypes.isEmpty else {
            return []
        }
        
        // Select workout type
        let workoutType = profile.preferredWorkoutTypes.randomElement()!
        
        // Generate workout time (morning or evening)
        let isEveningWorkout = Bool.random()
        let startHour = isEveningWorkout ? Int.random(in: 17...19) : Int.random(in: 6...8)
        
        guard let workoutStart = calendar.date(bySettingHour: startHour, minute: Int.random(in: 0...59), second: 0, of: date) else {
            return []
        }
        
        // Workout duration based on type
        let duration: TimeInterval
        let distance: Double
        let energyBurned: Int
        
        switch workoutType {
        case .running:
            duration = TimeInterval(Int.random(in: 30...90) * 60)
            distance = Double.random(in: 5000...15000)
            energyBurned = Int(duration / 60 * 10)
        case .cycling:
            duration = TimeInterval(Int.random(in: 45...120) * 60)
            distance = Double.random(in: 15000...40000)
            energyBurned = Int(duration / 60 * 8)
        case .swimming:
            duration = TimeInterval(Int.random(in: 30...60) * 60)
            distance = Double.random(in: 1000...3000)
            energyBurned = Int(duration / 60 * 12)
        case .walking:
            duration = TimeInterval(Int.random(in: 20...60) * 60)
            distance = Double.random(in: 2000...6000)
            energyBurned = Int(duration / 60 * 5)
        case .yoga, .pilates:
            duration = TimeInterval(Int.random(in: 45...90) * 60)
            distance = 0
            energyBurned = Int(duration / 60 * 3)
        case .strengthTraining:
            duration = TimeInterval(Int.random(in: 45...75) * 60)
            distance = 0
            energyBurned = Int(duration / 60 * 6)
        case .hiit:
            duration = TimeInterval(Int.random(in: 20...45) * 60)
            distance = 0
            energyBurned = Int(duration / 60 * 15)
        default:
            duration = TimeInterval(Int.random(in: 30...60) * 60)
            distance = 0
            energyBurned = Int(duration / 60 * 7)
        }
        
        let workoutEnd = workoutStart.addingTimeInterval(duration)
        
        var workout: [String: Any] = [
            "sdate": DateFormatter.iso8601.string(from: workoutStart),
            "edate": DateFormatter.iso8601.string(from: workoutEnd),
            "workoutActivityType": workoutTypeToHKIdentifier(workoutType),
            "duration": duration,
            "totalEnergyBurned": energyBurned,
            "workoutEvents": []
        ]
        
        if distance > 0 {
            workout["totalDistance"] = distance
        }
        
        samples.append(workout)
        
        return samples
    }
    
    // MARK: - Energy Generation
    
    private static func generateActiveEnergy(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        var samples: [[String: Any]] = []
        
        let targetEnergy = Int.random(in: profile.activeEnergyRange)
        let numberOfSamples = Int.random(in: 6...12)
        
        for i in 0..<numberOfSamples {
            let hour = 7 + (i * 14 / numberOfSamples)
            guard let sampleTime = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) else {
                continue
            }
            
            let energy = targetEnergy / numberOfSamples + Int.random(in: -20...20)
            
            samples.append([
                "sdate": DateFormatter.iso8601.string(from: sampleTime),
                "value": max(0, energy),
                "unit": "kcal"
            ])
        }
        
        return samples
    }
    
    private static func generateBasalEnergy(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        var samples: [[String: Any]] = []
        
        let baseBMR = 1600.0
        let dailyBasal = Int(baseBMR * profile.basalEnergyMultiplier)
        
        for hour in 0..<24 {
            guard let sampleTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) else {
                continue
            }
            
            let hourlyBasal = dailyBasal / 24
            
            samples.append([
                "sdate": DateFormatter.iso8601.string(from: sampleTime),
                "value": hourlyBasal,
                "unit": "kcal"
            ])
        }
        
        return samples
    }
    
    // MARK: - Other Metrics
    
    private static func generateBloodPressure(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        guard let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) else {
            return []
        }
        
        let systolic = profile.stressLevel == .veryHigh ? Int.random(in: 130...145) : Int.random(in: 110...125)
        let diastolic = profile.stressLevel == .veryHigh ? Int.random(in: 85...95) : Int.random(in: 70...80)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: morningTime),
            "systolic": systolic,
            "diastolic": diastolic,
            "unit": "mmHg"
        ]]
    }
    
    private static func generateBodyMass(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        guard let morningTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date) else {
            return []
        }
        
        let baseMass = 70.0 // kg
        let variation = Double.random(in: -0.5...0.5)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: morningTime),
            "value": baseMass + variation,
            "unit": "kg"
        ]]
    }
    
    private static func generateWater(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        var samples: [[String: Any]] = []
        
        let dailyWaterML: ClosedRange<Double> = {
            switch profile.hydrationLevel {
            case .low: return 1000...1500
            case .moderate: return 1500...2500
            case .high: return 2500...3500
            }
        }()
        
        let totalWater = Double.random(in: dailyWaterML)
        let numberOfDrinks = Int.random(in: 6...10)
        
        for i in 0..<numberOfDrinks {
            let hour = 7 + (i * 14 / numberOfDrinks)
            guard let sampleTime = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) else {
                continue
            }
            
            let waterAmount = totalWater / Double(numberOfDrinks)
            
            samples.append([
                "sdate": DateFormatter.iso8601.string(from: sampleTime),
                "value": waterAmount,
                "unit": "mL"
            ])
        }
        
        return samples
    }
    
    private static func generateMindfulness(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        
        let shouldMeditate = profile.stressLevel == .veryHigh ? Bool.random() : (Int.random(in: 0...100) < 30)
        
        guard shouldMeditate else { return [] }
        
        let startHour = Int.random(in: 7...9)
        guard let sessionStart = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: date) else {
            return []
        }
        
        let duration = TimeInterval(Int.random(in: 5...20) * 60)
        let sessionEnd = sessionStart.addingTimeInterval(duration)
        
        return [[
            "sdate": DateFormatter.iso8601.string(from: sessionStart),
            "edate": DateFormatter.iso8601.string(from: sessionEnd),
            "value": 0
        ]]
    }
    
    private static func generateDietarySugar(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        guard let mealTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else { return [] }
        let sugar = profile.dietaryPattern == .keto ? Double.random(in: 10...30) : Double.random(in: 40...80)
        return [["sdate": DateFormatter.iso8601.string(from: mealTime), "value": sugar, "unit": "g"]]
    }
    
    private static func generateDietaryProtein(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        guard let mealTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else { return [] }
        let protein = profile.dietaryPattern == .highProtein ? Double.random(in: 120...180) : Double.random(in: 60...100)
        return [["sdate": DateFormatter.iso8601.string(from: mealTime), "value": protein, "unit": "g"]]
    }
    
    private static func generateDietaryCarbs(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        guard let mealTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else { return [] }
        let carbs = profile.dietaryPattern == .keto ? Double.random(in: 20...50) : Double.random(in: 200...350)
        return [["sdate": DateFormatter.iso8601.string(from: mealTime), "value": carbs, "unit": "g"]]
    }
    
    private static func generateDietaryFat(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        guard let mealTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else { return [] }
        let fat = profile.dietaryPattern == .keto ? Double.random(in: 120...180) : Double.random(in: 50...90)
        return [["sdate": DateFormatter.iso8601.string(from: mealTime), "value": fat, "unit": "g"]]
    }
    
    private static func generateRespiratoryRate(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        guard let morningTime = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: date) else { return [] }
        return [["sdate": DateFormatter.iso8601.string(from: morningTime), "value": Double.random(in: 12...20), "unit": "count/min"]]
    }
    
    private static func generateOxygenSaturation(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        guard let morningTime = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: date) else { return [] }
        return [["sdate": DateFormatter.iso8601.string(from: morningTime), "value": Double.random(in: 95...100), "unit": "%"]]
    }
    
    // MARK: - Reproductive Health Generation
    
    /// Returns which day of the menstrual cycle this date falls on (1–28).
    /// Uses a fixed reference date so the cycle is consistent across a generation run.
    private static func menstrualCycleDay(for date: Date) -> Int {
        // Reference: cycle day 1 = Jan 1 2024 (arbitrary anchor, consistent within a run)
        let reference = Calendar.newZealand.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let daysSinceReference = Calendar.newZealand.dateComponents([.day], from: reference, to: date).day ?? 0
        // Typical cycle length of 28 days; keep positive
        return (((daysSinceReference % 28) + 28) % 28) + 1
    }

    // MARK: - Reproductive State Model

    /// A coherent, run-stable reproductive scenario derived deterministically from the
    /// generation configuration.
    ///
    /// Real people occupy exactly one reproductive state at a time. Generating each
    /// reproductive metric independently produces impossible combinations — contraceptive
    /// logs during pregnancy, ovulation surges while on the pill, periods mid-pregnancy.
    /// Every reproductive generator resolves this context first and only emits data that is
    /// consistent with the person's state on the given date.
    private struct ReproductiveContext {

        /// The mutually-exclusive reproductive scenario for an entire generation run.
        enum Scenario {
            case naturalCycle           // ovulatory cycles, no hormonal contraception
            case hormonalContraception  // e.g. the pill — ovulation suppressed, scheduled withdrawal bleed
            case pregnancy              // pregnant, then postpartum / lactation afterwards
        }

        /// The reproductive state resolved for a single day; generators switch on this.
        enum DayState: Equatable {
            case cycling(cycleDay: Int, ovulationSuppressed: Bool)
            case pregnant(week: Int)
            case postpartum(week: Int)
        }

        let scenario: Scenario
        private let windowStart: Date
        private let pregnancyStart: Date?   // only set for the pregnancy scenario
        private let deliveryDate: Date?     // pregnancyStart + full term

        /// A full-term pregnancy spans ~40 weeks.
        static let pregnancyTermDays = 280
        /// Reported contraceptive method (6 == HKCategoryValueContraceptive.oral, the most common).
        static let contraceptiveMethodOral = 6
        /// Postpartum lactation is reported for ~6 months.
        static let lactationWeeks = 26
        /// Postpartum bleeding (lochia) is reported for ~6 weeks.
        static let postpartumBleedingWeeks = 6

        init(config: SampleGenerationConfig) {
            let calendar = Calendar.newZealand
            let start = config.dateRange.startDate
            self.windowStart = start

            // Deterministic, process-independent selection so the same config always yields the
            // same reproductive history. (Swift's Hashable is randomly seeded per run, so we hash
            // a stable key ourselves rather than relying on hashValue.)
            let key = "\(config.profile.id)|\(DateFormatter.iso8601.string(from: start))|\(config.randomSeed ?? 0)"
            let roll = ReproductiveContext.unitInterval(from: key)

            // Distribution roughly reflecting a reproductive-age population.
            if roll < 0.55 {
                self.scenario = .naturalCycle
                self.pregnancyStart = nil
                self.deliveryDate = nil
            } else if roll < 0.90 {
                self.scenario = .hormonalContraception
                self.pregnancyStart = nil
                self.deliveryDate = nil
            } else {
                self.scenario = .pregnancy
                // Anchor conception so the window opens partway through gestation (4–31 weeks along).
                let weeksAlong = 4 + Int(ReproductiveContext.unitInterval(from: key + "|gestation") * 28)
                let conception = calendar.date(byAdding: .day, value: -weeksAlong * 7, to: start)!
                self.pregnancyStart = conception
                self.deliveryDate = calendar.date(byAdding: .day, value: ReproductiveContext.pregnancyTermDays, to: conception)!
            }
        }

        /// Day of the menstrual / pill-pack cycle (1...28) for a date.
        func cycleDay(on date: Date) -> Int {
            return SampleDataGenerator.menstrualCycleDay(for: date)
        }

        /// Resolves the reproductive state for a single date.
        func state(on date: Date) -> DayState {
            switch scenario {
            case .naturalCycle:
                return .cycling(cycleDay: cycleDay(on: date), ovulationSuppressed: false)
            case .hormonalContraception:
                return .cycling(cycleDay: cycleDay(on: date), ovulationSuppressed: true)
            case .pregnancy:
                guard let start = pregnancyStart, let delivery = deliveryDate else {
                    return .cycling(cycleDay: cycleDay(on: date), ovulationSuppressed: false)
                }
                let calendar = Calendar.newZealand
                let day = calendar.startOfDay(for: date)
                if day < calendar.startOfDay(for: start) {
                    return .cycling(cycleDay: cycleDay(on: date), ovulationSuppressed: false)
                } else if day < calendar.startOfDay(for: delivery) {
                    let weeks = (calendar.dateComponents([.day], from: start, to: date).day ?? 0) / 7
                    return .pregnant(week: weeks)
                } else {
                    let weeks = (calendar.dateComponents([.day], from: delivery, to: date).day ?? 0) / 7
                    return .postpartum(week: weeks)
                }
            }
        }

        /// The single date a positive pregnancy test should be logged — around week 5, and only
        /// when that moment falls inside the generation window (you don't re-test every day).
        var pregnancyTestPositiveDay: Date? {
            guard scenario == .pregnancy, let start = pregnancyStart, let delivery = deliveryDate else { return nil }
            let calendar = Calendar.newZealand
            let testDay = calendar.date(byAdding: .day, value: 35, to: start)!  // ~5 weeks
            guard testDay >= calendar.startOfDay(for: windowStart), testDay < delivery else { return nil }
            return testDay
        }

        /// Cycle day used to time cycle-linked symptoms, or nil when there is no menstrual cycle
        /// (pregnant / postpartum) so cycle-keyed symptom phases simply don't apply.
        func symptomCycleDay(on date: Date) -> Int? {
            switch state(on: date) {
            case .cycling(let day, _): return day
            case .pregnant, .postpartum: return nil
            }
        }

        /// Multiplier for cyclical-symptom probability — hormonal contraception dampens PMS.
        func symptomProbabilityScale(on date: Date) -> Double {
            if case .cycling(_, let suppressed) = state(on: date), suppressed { return 0.6 }
            return 1.0
        }

        /// FNV-1a hash folded into [0, 1) — stable across processes (unlike Swift's Hashable).
        private static func unitInterval(from string: String) -> Double {
            var hash: UInt64 = 0xcbf29ce484222325
            for byte in string.utf8 {
                hash ^= UInt64(byte)
                hash = hash &* 0x100000001b3
            }
            return Double(hash >> 11) / Double(UInt64(1) << 53)
        }
    }

    /// Menstrual flow: generates a single all-day sample during days 1–5 of the cycle.
    /// Values map to HKCategoryValueMenstrualFlow: light=2, medium=3, heavy=4.
    private static func generateMenstrualFlow(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)

        // Menstruation only happens during a cycle — never while pregnant or postpartum.
        guard case .cycling(let cycleDay, let ovulationSuppressed) = context.state(on: date),
              cycleDay <= 5 else { return [] }

        // HKCategoryValueMenstrualFlow raw values: light=2, medium=3, heavy=4.
        let flowValue: Int
        if ovulationSuppressed {
            // Hormonal contraception produces a lighter, more uniform withdrawal bleed.
            flowValue = (cycleDay == 2) ? 3 : 2 // medium peak, otherwise light
        } else {
            // Natural period follows a realistic bell curve: builds up, peaks, then tapers.
            switch cycleDay {
            case 1:  flowValue = 3 // medium — flow building
            case 2:  flowValue = 4 // heavy — peak flow
            case 3:  flowValue = 3 // medium
            default: flowValue = 2 // light — tapering off
            }
        }

        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return [[
            "sdate": DateFormatter.iso8601.string(from: dayStart),
            "edate": DateFormatter.iso8601.string(from: dayEnd),
            "value": flowValue,
            // isCycleStart is a flat top-level field rather than nested inside metaData,
            // because nested dicts don't survive the custom JSON tokenizer pipeline intact.
            // SampleCreator reads this and injects HKMetadataKeyMenstrualCycleStart directly.
            "isCycleStart": (cycleDay == 1)
        ]]
    }

    /// Intermenstrual bleeding: mid-cycle spotting around ovulation (day 14), low probability.
    /// Value maps to HKCategoryValue.notApplicable (0) — presence is the data point.
    private static func generateIntermenstrualBleeding(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)

        // Ovulation spotting requires an ovulatory cycle — not while pregnant/postpartum, and
        // not when ovulation is suppressed by hormonal contraception.
        guard case .cycling(let cycleDay, let ovulationSuppressed) = context.state(on: date),
              !ovulationSuppressed else { return [] }

        // Mid-cycle spotting is possible around ovulation (days 13–15), ~15% chance
        guard (13...15).contains(cycleDay), Double.random(in: 0...1) < 0.15 else { return [] }

        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return [[
            "sdate": DateFormatter.iso8601.string(from: dayStart),
            "edate": DateFormatter.iso8601.string(from: dayEnd),
            "value": 0 // HKCategoryValue.notApplicable
        ]]
    }

    /// Cervical mucus quality: varies predictably across the cycle.
    /// HKCategoryValueCervicalMucusQuality: dry=1, sticky=2, creamy=3, watery=4, eggWhite=5
    private static func generateCervicalMucusQuality(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)

        // The fertile cervical-mucus pattern only appears in an ovulatory cycle. Hormonal
        // contraception suppresses it, and there is no pattern while pregnant/postpartum.
        guard case .cycling(let cycleDay, let ovulationSuppressed) = context.state(on: date),
              !ovulationSuppressed else { return [] }

        // No mucus observation during menstruation
        guard cycleDay > 5 else { return [] }

        let mucusValue: Int
        switch cycleDay {
        case 6...8:   mucusValue = 1 // dry — post-period
        case 9...10:  mucusValue = 2 // sticky
        case 11...12: mucusValue = 3 // creamy — approaching fertile window
        case 13:      mucusValue = 4 // watery
        case 14:      mucusValue = 5 // egg white — peak fertility / ovulation
        case 15:      mucusValue = 4 // watery — just post-ovulation
        case 16...18: mucusValue = 2 // sticky — luteal phase begins
        default:      mucusValue = 1 // dry — luteal phase
        }

        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return [[
            "sdate": DateFormatter.iso8601.string(from: dayStart),
            "edate": DateFormatter.iso8601.string(from: dayEnd),
            "value": mucusValue
        ]]
    }

    /// Ovulation test result: LH surge peaks at day 14.
    /// HKCategoryValueOvulationTestResult: negative=1, luteinizingHormoneSurge=2, indeterminate=3, estrogenSurge=4
    private static func generateOvulationTestResult(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)

        // Ovulation tests only make sense in an ovulatory cycle — suppressed on hormonal
        // contraception, and not while pregnant/postpartum.
        guard case .cycling(let cycleDay, let ovulationSuppressed) = context.state(on: date),
              !ovulationSuppressed else { return [] }

        // Only generate a test result during the fertile window (days 10–17)
        guard (10...17).contains(cycleDay) else { return [] }

        let testValue: Int
        switch cycleDay {
        case 12:    testValue = 4 // estrogenSurge — rises first (iOS 15+)
        case 13:    testValue = 3 // indeterminate — LH building
        case 14:    testValue = 2 // luteinizingHormoneSurge — peak
        case 15:    testValue = 2 // luteinizingHormoneSurge — still elevated
        default:    testValue = 1 // negative
        }

        guard let noonTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) else { return [] }

        return [[
            "sdate": DateFormatter.iso8601.string(from: noonTime),
            "value": testValue
        ]]
    }

    /// Progesterone test result: positive during the luteal phase (days 18–26).
    /// HKCategoryValueProgesteroneTestResult: negative=1, positive=2, indeterminate=3 (iOS 15+)
    private static func generateProgesteroneTestResult(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)

        // A luteal progesterone rise only occurs after ovulation in a natural cycle — not when
        // anovulatory on hormonal contraception, and not while pregnant/postpartum.
        guard case .cycling(let cycleDay, let ovulationSuppressed) = context.state(on: date),
              !ovulationSuppressed else { return [] }

        // Only generate a test result during the luteal phase (days 18–26)
        guard (18...26).contains(cycleDay) else { return [] }

        // Positive during mid-luteal phase, indeterminate at edges
        let testValue: Int
        switch cycleDay {
        case 18, 26: testValue = 3  // indeterminate — transitional
        default:     testValue = 2  // positive — confirmed luteal progesterone rise
        }

        guard let morningTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) else { return [] }

        return [[
            "sdate": DateFormatter.iso8601.string(from: morningTime),
            "value": testValue
        ]]
    }

    /// Pregnancy test result: negative in a normal cycle simulation.
    /// HKCategoryValuePregnancyTestResult: negative=1, positive=2, indeterminate=3 (iOS 15+)
    private static func generatePregnancyTestResult(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)
        guard let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) else { return [] }

        switch context.state(on: date) {
        case .cycling(let cycleDay, let ovulationSuppressed):
            // Someone on hormonal contraception isn't testing for conception.
            guard !ovulationSuppressed else { return [] }
            // Tests are typically taken around the expected period (day 28 / day 1); negative here.
            guard cycleDay == 28 || cycleDay == 1, Double.random(in: 0...1) < 0.85 else { return [] }
            return [[
                "sdate": DateFormatter.iso8601.string(from: morningTime),
                "value": 1 // negative
            ]]
        case .pregnant:
            // A single positive test on the day the pregnancy is confirmed (~5 weeks).
            guard let positiveDay = context.pregnancyTestPositiveDay,
                  calendar.isDate(date, inSameDayAs: positiveDay) else { return [] }
            return [[
                "sdate": DateFormatter.iso8601.string(from: morningTime),
                "value": 2 // positive
            ]]
        case .postpartum:
            return []
        }
    }

    /// Sexual activity: random occurrence, ~25% of days.
    /// Value is HKCategoryValue.notApplicable (0) — presence is the data point.
    private static func generateSexualActivity(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand

        guard Double.random(in: 0...1) < 0.25 else { return [] }

        let hour = [21, 22, 23, 7, 8].randomElement()!
        guard let activityTime = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...30), second: 0, of: date) else {
            return []
        }

        return [[
            "sdate": DateFormatter.iso8601.string(from: activityTime),
            "value": 0 // HKCategoryValue.notApplicable
        ]]
    }

    /// Contraceptive: one entry per day representing ongoing use.
    /// HKCategoryValueContraceptive: unspecified=1, implant=2, injection=3, IUD=4,
    ///                               intravaginalRing=5, oral=6, patch=7 (iOS 14.3+)
    private static func generateContraceptive(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)

        // Contraceptive use is logged only in the hormonal-contraception scenario — never while
        // pregnant or postpartum, and never in a natural (non-contracepting) cycle. It is logged
        // every day to represent ongoing use, rather than flickering on and off day to day.
        guard context.scenario == .hormonalContraception else { return [] }

        let methodValue = ReproductiveContext.contraceptiveMethodOral

        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return [[
            "sdate": DateFormatter.iso8601.string(from: dayStart),
            "edate": DateFormatter.iso8601.string(from: dayEnd),
            "value": methodValue
        ]]
    }

    /// Pregnancy state: a single all-day category sample, emitted on every day the person is
    /// pregnant. Value is HKCategoryValue.notApplicable (0) — presence indicates the state.
    private static func generatePregnancy(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)
        guard case .pregnant = context.state(on: date) else { return [] }

        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return [[
            "sdate": DateFormatter.iso8601.string(from: dayStart),
            "edate": DateFormatter.iso8601.string(from: dayEnd),
            "value": 0 // HKCategoryValue.notApplicable
        ]]
    }

    /// Lactation state: a single all-day category sample, emitted through the postpartum period
    /// (~6 months after delivery). Value is HKCategoryValue.notApplicable (0).
    private static func generateLactation(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)
        guard case .postpartum(let week) = context.state(on: date),
              week < ReproductiveContext.lactationWeeks else { return [] }

        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return [[
            "sdate": DateFormatter.iso8601.string(from: dayStart),
            "edate": DateFormatter.iso8601.string(from: dayEnd),
            "value": 0 // HKCategoryValue.notApplicable
        ]]
    }

    /// Bleeding after pregnancy (lochia): postpartum bleeding that tapers over ~6 weeks.
    /// iOS 18+ only — the type identifier doesn't exist on earlier OSes, and the sample creator
    /// force-unwraps it, so we must not emit a dict for this type there.
    /// Uses HKCategoryValueVaginalBleeding raw values: light=2, medium=3, heavy=4.
    private static func generateBleedingAfterPregnancy(
        for date: Date, profile: HealthProfile, config: SampleGenerationConfig
    ) -> [[String: Any]] {
        guard #available(iOS 18.0, macOS 15.0, *) else { return [] }
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)
        guard case .postpartum(let week) = context.state(on: date),
              week < ReproductiveContext.postpartumBleedingWeeks else { return [] }

        // Lochia is heaviest right after delivery, then tapers.
        let value: Int
        switch week {
        case 0:  value = 4 // heavy
        case 1:  value = 3 // medium
        default: value = 2 // light, tapering off
        }

        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return [[
            "sdate": DateFormatter.iso8601.string(from: dayStart),
            "edate": DateFormatter.iso8601.string(from: dayEnd),
            "value": value
        ]]
    }

    /// Bleeding during pregnancy: an abnormal event / potential complication, so it is not part
    /// of a healthy default pregnancy and is left ungenerated.
    private static func generateBleedingDuringPregnancy(
        for date: Date, profile: HealthProfile, config: SampleGenerationConfig
    ) -> [[String: Any]] {
        return []
    }

    // MARK: - Cycle Irregularity Generation

    /// Infrequent menstrual cycles (cycle length > 35 days).
    /// Represented as a single notApplicable (0) sample at the start of a "late" period.
    /// Only emitted ~20% of the time on cycle day 1 (simulating occasional long cycles).
    private static func generateInfrequentMenstrualCycles(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let cycleDay = menstrualCycleDay(for: date)
        guard cycleDay == 1, Double.random(in: 0...1) < 0.20 else { return [] }
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return [["sdate": DateFormatter.iso8601.string(from: dayStart),
                 "edate": DateFormatter.iso8601.string(from: dayEnd),
                 "value": 0]]
    }

    /// Irregular menstrual cycles (variable cycle length).
    /// Emitted ~30% of the time on cycle day 1. More likely for the stressed profile.
    private static func generateIrregularMenstrualCycles(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let cycleDay = menstrualCycleDay(for: date)
        let probability: Double = profile.stressLevel == .veryHigh ? 0.45 : 0.20
        guard cycleDay == 1, Double.random(in: 0...1) < probability else { return [] }
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return [["sdate": DateFormatter.iso8601.string(from: dayStart),
                 "edate": DateFormatter.iso8601.string(from: dayEnd),
                 "value": 0]]
    }

    /// Persistent intermenstrual bleeding (ongoing spotting outside the normal period).
    /// Generated on days outside menstruation with low probability.
    private static func generatePersistentIntermenstrualBleeding(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let cycleDay = menstrualCycleDay(for: date)
        // Not generated during normal menstruation (days 1–5) or normal spotting window (13–15)
        guard !(1...5).contains(cycleDay), !(13...15).contains(cycleDay) else { return [] }
        guard Double.random(in: 0...1) < 0.08 else { return [] }
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return [["sdate": DateFormatter.iso8601.string(from: dayStart),
                 "edate": DateFormatter.iso8601.string(from: dayEnd),
                 "value": 0]]
    }

    /// Prolonged menstrual periods (period lasting more than 7 days).
    /// Generated on days 6–8 of the cycle at moderate probability.
    private static func generateProlongedMenstrualPeriods(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let cycleDay = menstrualCycleDay(for: date)
        guard (6...8).contains(cycleDay), Double.random(in: 0...1) < 0.30 else { return [] }
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return [["sdate": DateFormatter.iso8601.string(from: dayStart),
                 "edate": DateFormatter.iso8601.string(from: dayEnd),
                 "value": 0]]
    }

    // MARK: - Symptom Generation

    /// Shared symptom sample builder.
    ///
    /// Each `PhaseConfig` describes a cycle-day window with an associated probability and
    /// HKCategoryValueSeverity range (notPresent=0, mild=1, moderate=2, severe=3).
    /// `baseProbability` covers days outside all defined phases.
    /// The stress level of the profile scales all probabilities upward.
    private struct PhaseConfig {
        let days: ClosedRange<Int>
        let probability: Double
        let severityRange: ClosedRange<Int>
    }

    private static func generateSymptomSample(
        for date: Date,
        profile: HealthProfile,
        config: SampleGenerationConfig,
        phases: [PhaseConfig],
        baseProbability: Double = 0.0,
        baseSeverityRange: ClosedRange<Int> = 1...2
    ) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)

        var probability = baseProbability
        var severityRange = baseSeverityRange

        // Cycle-keyed phases only apply when there is a menstrual cycle. While pregnant or
        // postpartum there is no cycle day, so only the (non-cyclical) base probability applies —
        // this is what stops, e.g., "menstrual cramps" appearing mid-pregnancy.
        if let cycleDay = context.symptomCycleDay(on: date) {
            for phase in phases {
                if phase.days.contains(cycleDay) {
                    // Hormonal contraception dampens premenstrual symptoms.
                    probability = max(probability, phase.probability * context.symptomProbabilityScale(on: date))
                    severityRange = phase.severityRange
                    break
                }
            }
        }

        // Stress amplifies symptom likelihood
        let stressMultiplier: Double
        switch profile.stressLevel {
        case .veryHigh: stressMultiplier = 1.6
        case .high:     stressMultiplier = 1.3
        case .moderate: stressMultiplier = 1.0
        case .low:      stressMultiplier = 0.65
        }

        guard Double.random(in: 0...1) < min(1.0, probability * stressMultiplier) else { return [] }

        // Clamp to valid HKCategoryValueSeverity range.
        // notPresent=1, mild=2, moderate=3, severe=4 — never emit 0 (notApplicable).
        // Since we only create a sample when a symptom is present, floor at mild (2).
        let clampedRange = max(2, severityRange.lowerBound)...min(4, severityRange.upperBound)
        let severity = Int.random(in: clampedRange)
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return [["sdate": DateFormatter.iso8601.string(from: dayStart),
                 "edate": DateFormatter.iso8601.string(from: dayEnd),
                 "value": severity]]
    }

    // MARK: Symptom Generators

    /// Abdominal cramps: peak during menstruation (days 1–5) and premenstrual phase (22–28).
    private static func generateAbdominalCramps(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 1...3,   probability: 0.75, severityRange: 2...3),
            PhaseConfig(days: 4...5,   probability: 0.55, severityRange: 2...3),
            PhaseConfig(days: 22...28, probability: 0.35, severityRange: 2...3)
        ])
    }

    /// Acne: elevated during late luteal phase (days 20–28) due to hormonal shifts.
    private static func generateAcne(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 20...28, probability: 0.40, severityRange: 2...3),
            PhaseConfig(days: 1...5,   probability: 0.25, severityRange: 2...2)
        ])
    }

    /// Premenstrual cravings and post-ovulation fluctuations.
    /// Appetite changes: uses HKCategoryValueAppetiteChanges, NOT severity.
    /// noChange=1, decreased=2, increased=3. Premenstrual cravings (increased) dominate days 20–28.
    private static func generateAppetiteChanges(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)
        // Cyclical appetite changes require a menstrual cycle — skip while pregnant/postpartum.
        guard let cycleDay = context.symptomCycleDay(on: date) else { return [] }
        let phases: [(days: ClosedRange<Int>, probability: Double)] = [
            (20...28, 0.45),
            (1...3,   0.25)
        ]
        var probability = 0.0
        for phase in phases {
            if phase.days.contains(cycleDay) { probability = phase.probability; break }
        }
        probability *= context.symptomProbabilityScale(on: date) // contraception dampens PMS
        let stressMultiplier: Double
        switch profile.stressLevel {
        case .veryHigh: stressMultiplier = 1.6
        case .high:     stressMultiplier = 1.3
        case .moderate: stressMultiplier = 1.0
        case .low:      stressMultiplier = 0.65
        }
        guard Double.random(in: 0...1) < min(1.0, probability * stressMultiplier) else { return [] }
        // HKCategoryValueAppetiteChanges: noChange=1, decreased=2, increased=3
        // Luteal phase (20–28) skews toward increased; menstruation toward decreased.
        let value: Int
        if (20...28).contains(cycleDay) {
            value = [1, 2, 3, 3].randomElement()! // increased most likely
        } else if (1...3).contains(cycleDay) {
            value = [1, 2, 2, 3].randomElement()! // decreased most likely
        } else {
            value = [1, 2, 3].randomElement()!
        }
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return [["sdate": DateFormatter.iso8601.string(from: dayStart),
                 "edate": DateFormatter.iso8601.string(from: dayEnd),
                 "value": value]]
    }

    /// Bladder incontinence: low baseline; slightly elevated premenstrually.
    private static func generateBladderIncontinence(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 22...28, probability: 0.12, severityRange: 2...2)
        ], baseProbability: 0.05)
    }

    /// Bloating: strongest premenstrually; mild around ovulation.
    private static func generateBloating(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 22...28, probability: 0.55, severityRange: 2...3),
            PhaseConfig(days: 1...3,   probability: 0.35, severityRange: 2...3),
            PhaseConfig(days: 13...15, probability: 0.20, severityRange: 2...2)
        ])
    }

    /// Breast pain (mastalgia): classic premenstrual symptom, peaks days 18–28.
    private static func generateBreastPain(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 18...28, probability: 0.45, severityRange: 2...3),
            PhaseConfig(days: 1...5,   probability: 0.20, severityRange: 2...2)
        ])
    }

    /// Chills: low baseline; elevated during menstruation.
    private static func generateChills(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 1...3, probability: 0.20, severityRange: 2...2)
        ], baseProbability: 0.04)
    }

    /// Constipation: progesterone-driven; most common in the luteal phase (days 16–28).
    private static func generateConstipation(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 16...28, probability: 0.25, severityRange: 2...3)
        ], baseProbability: 0.05)
    }

    /// Diarrhea: prostaglandin-driven; peak at onset of menstruation (days 1–3).
    private static func generateDiarrhea(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 1...3, probability: 0.30, severityRange: 2...3)
        ], baseProbability: 0.03)
    }

    /// Dizziness: mild baseline; slightly elevated during heavy flow (days 1–2).
    private static func generateDizziness(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 1...2, probability: 0.20, severityRange: 2...2)
        ], baseProbability: 0.05)
    }

    /// Dry skin: linked to oestrogen drop late in cycle; low but persistent baseline.
    private static func generateDrySkin(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 20...28, probability: 0.20, severityRange: 2...2)
        ], baseProbability: 0.08)
    }

    /// Fatigue: elevated during menstruation and premenstrual phase; stressed profile amplifies.
    private static func generateFatigue(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 1...5,   probability: 0.60, severityRange: 2...3),
            PhaseConfig(days: 22...28, probability: 0.45, severityRange: 2...3)
        ], baseProbability: 0.10)
    }

    /// Hair loss: chronic low-level symptom; slightly elevated post-menstruation.
    private static func generateHairLoss(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 6...12, probability: 0.12, severityRange: 2...2)
        ], baseProbability: 0.05)
    }

    /// Headache: premenstrual oestrogen drop causes tension headaches; stress amplifies.
    private static func generateHeadache(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 22...28, probability: 0.40, severityRange: 2...3),
            PhaseConfig(days: 1...3,   probability: 0.30, severityRange: 2...3)
        ], baseProbability: 0.06)
    }

    /// Hot flashes: driven by oestrogen fluctuations late in the luteal phase.
    private static func generateHotFlashes(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 20...28, probability: 0.25, severityRange: 2...3)
        ], baseProbability: 0.04)
    }

    /// Lower back pain: peak during menstruation; mild premenstrual presence.
    private static func generateLowerBackPain(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 1...4,   probability: 0.60, severityRange: 2...3),
            PhaseConfig(days: 22...28, probability: 0.30, severityRange: 2...3)
        ])
    }

    /// Memory lapse: linked to hormonal brain-fog, especially late-luteal and stressed profiles.
    private static func generateMemoryLapse(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 22...28, probability: 0.22, severityRange: 2...3)
        ], baseProbability: 0.06)
    }

    /// PMS/PMDD spectrum; strong premenstrual signal, eases after period starts.
    /// Mood changes: uses HKCategoryValuePresence, NOT severity.
    /// HKCategoryValuePresence: present=0, notPresent=1. We only emit a sample when present.
    /// Strong premenstrual signal, eases after period starts.
    private static func generateMoodChanges(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)
        // PMS/PMDD mood changes require a menstrual cycle — skip while pregnant/postpartum.
        guard let cycleDay = context.symptomCycleDay(on: date) else { return [] }
        var probability = 0.0
        if (20...28).contains(cycleDay)  { probability = 0.55 }
        else if (1...3).contains(cycleDay) { probability = 0.30 }
        probability *= context.symptomProbabilityScale(on: date) // contraception dampens PMS
        let stressMultiplier: Double
        switch profile.stressLevel {
        case .veryHigh: stressMultiplier = 1.6
        case .high:     stressMultiplier = 1.3
        case .moderate: stressMultiplier = 1.0
        case .low:      stressMultiplier = 0.65
        }
        guard Double.random(in: 0...1) < min(1.0, probability * stressMultiplier) else { return [] }
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return [["sdate": DateFormatter.iso8601.string(from: dayStart),
                 "edate": DateFormatter.iso8601.string(from: dayEnd),
                 "value": 0]] // HKCategoryValuePresence.present = 0
    }

    /// Nausea: common at onset of menstruation due to prostaglandins; baseline for other days.
    private static func generateNausea(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 1...3,   probability: 0.35, severityRange: 2...3),
            PhaseConfig(days: 22...28, probability: 0.15, severityRange: 2...2)
        ], baseProbability: 0.03)
    }

    /// Night sweats: hormonally driven; primarily premenstrual and stress-related.
    private static func generateNightSweats(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 20...28, probability: 0.22, severityRange: 2...3)
        ], baseProbability: 0.05)
    }

    /// Pelvic pain: menstrual cramping (days 1–5) and mittelschmerz around ovulation (13–15).
    private static func generatePelvicPain(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 1...4,   probability: 0.60, severityRange: 2...3),
            PhaseConfig(days: 13...15, probability: 0.25, severityRange: 2...2),
            PhaseConfig(days: 22...28, probability: 0.20, severityRange: 2...2)
        ])
    }

    /// Rapid, pounding, or fluttering heartbeat: low baseline; slightly elevated premenstrually.
    private static func generateRapidPoundingOrFlutteringHeartbeat(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 22...28, probability: 0.12, severityRange: 2...2)
        ], baseProbability: 0.04)
    }

    /// Runny nose: non-cyclic; low constant probability, stress-independent.
    private static func generateRunnyNose(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.06)
    }

    /// Sinus congestion: non-cyclic; low constant probability.
    private static func generateSinusCongestion(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.06)
    }

    /// Skipped heartbeat: very low probability; independent of cycle phase.
    private static func generateSkippedHeartbeat(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.03)
    }

    /// Sleep changes: uses HKCategoryValuePresence, NOT severity.
    /// HKCategoryValuePresence: present=0, notPresent=1. We only emit a sample when present.
    /// Elevated premenstrually and during menstruation; stress-driven otherwise.
    private static func generateSleepChanges(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        let calendar = Calendar.newZealand
        let context = ReproductiveContext(config: config)
        var probability = 0.08 // baseline — sleep disruption can occur in any reproductive state
        if let cycleDay = context.symptomCycleDay(on: date) {
            let scale = context.symptomProbabilityScale(on: date) // contraception dampens PMS
            if (20...28).contains(cycleDay)  { probability = max(probability, 0.35 * scale) }
            else if (1...5).contains(cycleDay) { probability = max(probability, 0.25 * scale) }
        }
        let stressMultiplier: Double
        switch profile.stressLevel {
        case .veryHigh: stressMultiplier = 1.6
        case .high:     stressMultiplier = 1.3
        case .moderate: stressMultiplier = 1.0
        case .low:      stressMultiplier = 0.65
        }
        guard Double.random(in: 0...1) < min(1.0, probability * stressMultiplier) else { return [] }
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return [["sdate": DateFormatter.iso8601.string(from: dayStart),
                 "edate": DateFormatter.iso8601.string(from: dayEnd),
                 "value": 0]] // HKCategoryValuePresence.present = 0
    }

    /// Sore throat: non-cyclic; low constant probability.
    private static func generateSoreThroat(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.05)
    }

    /// Vaginal dryness: low oestrogen during luteal phase; elevated days 18–28.
    private static func generateVaginalDryness(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 18...28, probability: 0.20, severityRange: 2...3)
        ], baseProbability: 0.05)
    }

    /// Vomiting: rare; occurs at peak prostaglandin surge (days 1–2).
    private static func generateVomiting(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 1...2, probability: 0.12, severityRange: 2...3)
        ], baseProbability: 0.02)
    }

    /// Body and muscle ache: mild cyclic pattern during menstruation; low baseline.
    private static func generateBodyAndMuscleAche(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 1...5, probability: 0.35, severityRange: 2...3),
            PhaseConfig(days: 22...28, probability: 0.15, severityRange: 2...2)
        ], baseProbability: 0.05)
    }

    /// Chest tightness or pain: non-cyclic; rare.
    private static func generateChestTightnessOrPain(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.03)
    }

    /// Coughing: non-cyclic; low probability.
    private static func generateCoughing(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.05)
    }

    /// Fainting: very rare; non-cyclic.
    private static func generateFainting(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.01)
    }

    /// Fever: non-cyclic; very low probability.
    private static func generateFever(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.02)
    }

    /// Heartburn: progesterone relaxes lower oesophageal sphincter; elevated in luteal phase.
    private static func generateHeartburn(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [
            PhaseConfig(days: 16...28, probability: 0.20, severityRange: 2...3)
        ], baseProbability: 0.04)
    }

    /// Loss of smell: non-cyclic; very low probability.
    private static func generateLossOfSmell(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.02)
    }

    /// Loss of taste: non-cyclic; very low probability.
    private static func generateLossOfTaste(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.02)
    }

    /// Shortness of breath: mild; non-cyclic.
    private static func generateShortnessOfBreath(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.04)
    }

    /// Wheezing: non-cyclic; low probability.
    private static func generateWheezing(for date: Date, profile: HealthProfile, config: SampleGenerationConfig) -> [[String: Any]] {
        generateSymptomSample(for: date, profile: profile, config: config, phases: [],
                              baseProbability: 0.04)
    }

    // MARK: - Helper Methods
    
    private static func workoutTypeToHKIdentifier(_ type: WorkoutType) -> Int {
        switch type {
        case .running: return 37 // HKWorkoutActivityTypeRunning
        case .cycling: return 13 // HKWorkoutActivityTypeCycling
        case .swimming: return 46 // HKWorkoutActivityTypeSwimming
        case .walking: return 52 // HKWorkoutActivityTypeWalking
        case .yoga: return 57 // HKWorkoutActivityTypeYoga
        case .strengthTraining: return 50 // HKWorkoutActivityTypeTraditionalStrengthTraining
        case .hiit: return 63 // HKWorkoutActivityTypeHighIntensityIntervalTraining
        case .pilates: return 31 // HKWorkoutActivityTypePilates
        case .dancing: return 19 // HKWorkoutActivityTypeDance
        case .sports: return 3 // HKWorkoutActivityTypeAmericanFootball
        }
    }
}

// MARK: - Generation Timezone

extension TimeZone {
    /// Timezone all generated samples are anchored to. `Pacific/Auckland` tracks
    /// NZDT (+13) and NZST (+12) automatically based on the date being generated.
    static let newZealand = TimeZone(identifier: "Pacific/Auckland")!
}

extension Calendar {
    /// Calendar used to construct sample wall-clock times. Anchored to New Zealand
    /// time so generated hours (morning/noon/evening) are independent of the machine
    /// running generation. Gregorian (not `.current`) keeps weekday/day math deterministic.
    static let newZealand: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .newZealand
        return calendar
    }()
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = .newZealand
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

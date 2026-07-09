import SwiftUI
import MapKit

struct TopSheetCard: View {
    let step: MKRoute.Step
    let currentIndex: Int
    let totalSteps: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.normalActiveNd)
                    .frame(width: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text(distanceText)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.darkActive)
                    Text(directionText)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.darkActive.opacity(0.7))
                }

                Spacer()
            }

            StepIndicator(current: currentIndex, total: totalSteps)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    private var distanceText: String {
        let meters = Int(step.distance)
        if meters >= 1000 {
            return String(format: "%.1fkm", Double(meters) / 1000)
        }
        return "\(meters)m"
    }

    private var iconName: String {
        let lowercased = step.instructions.lowercased()
        if lowercased.contains("slight right") {
            return "arrow.up.right"
        } else if lowercased.contains("slight left") {
            return "arrow.up.left"
        } else if lowercased.contains("right") {
            return "arrow.turn.up.right"
        } else if lowercased.contains("left") {
            return "arrow.turn.up.left"
        } else if lowercased.contains("arrived") || lowercased.contains("destination") {
            return "flag.fill"
        } else {
            return "arrow.up"
        }
    }

    private var directionText: String {
        let lowercased = step.instructions.lowercased()
        if lowercased.contains("slight right") {
            return "Turn Slightly Right"
        } else if lowercased.contains("slight left") {
            return "Turn Slightly Left"
        } else if lowercased.contains("right") {
            return "Turn Right"
        } else if lowercased.contains("left") {
            return "Turn Left"
        } else if lowercased.contains("arrived") || lowercased.contains("destination") {
            return "You've arrived!"
        } else {
            return "Keep Straight"
        }
    }
}

private struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? .normalActiveNd : .normalActiveNd.opacity(0.25))
                    .frame(width: index == current ? 8 : 6, height: index == current ? 8 : 6)
            }
        }
    }
}

#Preview("Light") {
    TopSheetCard(
        step: MKRoute.Step(),
        currentIndex: 0,
        totalSteps: 7
    )
    .padding(15)
}

#Preview("Dark") {
    TopSheetCard(
        step: MKRoute.Step(),
        currentIndex: 0,
        totalSteps: 7
    )
    .padding(15)
    .preferredColorScheme(.dark)
}

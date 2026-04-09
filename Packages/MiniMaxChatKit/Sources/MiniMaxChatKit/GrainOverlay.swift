import SwiftUI

public enum GrainIntensity: Sendable {
    case subtle
    case light
    case medium
    case custom(Double)

    var value: Double {
        switch self {
        case .subtle: return 0.035
        case .light: return 0.055
        case .medium: return 0.080
        case .custom(let v): return v
        }
    }
}

public struct GrainOverlay: View {
    public var intensity: GrainIntensity = .light
    public var dotSize: CGFloat = 1.0
    public var seed: UInt64 = 42

    public init(intensity: GrainIntensity = .light, dotSize: CGFloat = 1.0, seed: UInt64 = 42) {
        self.intensity = intensity
        self.dotSize = dotSize
        self.seed = seed
    }

    public var body: some View {
        Canvas { context, size in
            let count = Int(size.width * size.height * 0.18)
            var rng = SeededRNG(seed: seed)

            for _ in 0..<count {
                let x = CGFloat(rng.next()) * size.width
                let y = CGFloat(rng.next()) * size.height
                let alpha = intensity.value * (0.4 + Double(rng.next()) * 0.6)

                let rect = CGRect(
                    x: x - dotSize / 2,
                    y: y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.black.opacity(alpha))
                )
            }
        }
        .drawingGroup()
        .allowsHitTesting(false)
    }
}

private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed &+ 1 }

    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 33) / Double(1 << 31)
    }
}

public struct GrainTextureModifier: ViewModifier {
    public var intensity: GrainIntensity
    public var dotSize: CGFloat
    public var seed: UInt64

    public func body(content: Content) -> some View {
        content.overlay(
            GrainOverlay(intensity: intensity, dotSize: dotSize, seed: seed)
                .clipped()
        )
    }
}

extension View {
    public func grainTexture(
        intensity: GrainIntensity = .light,
        dotSize: CGFloat = 1.0,
        seed: UInt64 = 42
    ) -> some View {
        modifier(GrainTextureModifier(intensity: intensity, dotSize: dotSize, seed: seed))
    }
}

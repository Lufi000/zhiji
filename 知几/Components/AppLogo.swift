import SwiftUI

// MARK: - App Logo（Zion National Park 极简风格）

struct AppLogo: View {
    var size: CGFloat = 80

    // 颜色定义
    private let grassColor = Color(hex: "2D5A3D")
    private let sunColor = Color(hex: "F5B041")
    private let stoneColor = Color(hex: "D35400")
    private let waveColor = Color(hex: "2980B9")

    var body: some View {
        let cellSize = size * 0.45
        let spacing = size * 0.08

        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                // 左上 - 草叶
                GrassView(color: grassColor)
                    .frame(width: cellSize, height: cellSize)

                // 右上 - 太阳
                Circle()
                    .fill(sunColor)
                    .frame(width: cellSize * 0.85, height: cellSize * 0.85)
                    .frame(width: cellSize, height: cellSize)
            }

            HStack(spacing: spacing) {
                // 左下 - 堆叠石头
                StackedStonesView(color: stoneColor)
                    .frame(width: cellSize, height: cellSize)

                // 右下 - 波浪
                WavesView(color: waveColor)
                    .frame(width: cellSize, height: cellSize)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 草叶形状

struct GrassView: View {
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let strokeWidth = w * 0.12

            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    GrassBladeShape(index: i)
                        .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                }
            }
            .frame(width: w, height: h)
        }
    }
}

// MARK: - 单条草叶路径

struct GrassBladeShape: Shape {
    var index: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        let angles: [Double] = [-35, -18, 0, 18, 35]
        let angle = angles[index] * .pi / 180

        let startX = w * 0.5
        let startY = h * 0.95

        let length = h * 0.85
        let endX = startX + sin(angle) * length * 0.6
        let endY = startY - length

        let ctrlX = startX + sin(angle) * length * 0.3
        let ctrlY = startY - length * 0.5

        path.move(to: CGPoint(x: startX, y: startY))
        path.addQuadCurve(
            to: CGPoint(x: endX, y: endY),
            control: CGPoint(x: ctrlX, y: ctrlY)
        )

        return path
    }
}

// MARK: - 堆叠石头

struct StackedStonesView: View {
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // 底部大石头
                Ellipse()
                    .fill(color)
                    .frame(width: w * 0.75, height: h * 0.35)
                    .offset(y: h * 0.28)

                // 中间石头
                Ellipse()
                    .fill(color)
                    .frame(width: w * 0.55, height: h * 0.3)
                    .offset(y: h * 0.0)

                // 顶部小石头
                Ellipse()
                    .fill(color)
                    .frame(width: w * 0.4, height: h * 0.25)
                    .offset(y: h * -0.25)
            }
            .frame(width: w, height: h)
        }
    }
}

// MARK: - 波浪

struct WavesView: View {
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let waveCount = 4
            let spacing = h / CGFloat(waveCount + 1)
            let strokeWidth = h * 0.08

            VStack(spacing: spacing * 0.5) {
                ForEach(0..<waveCount, id: \.self) { i in
                    WaveShape()
                        .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                        .frame(width: w * 0.9, height: spacing * 0.6)
                }
            }
            .frame(width: w, height: h)
        }
    }
}

// MARK: - 单条波浪路径

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midY = h * 0.5

        path.move(to: CGPoint(x: 0, y: midY))

        let waveWidth = w / 2

        // 第一个波浪
        path.addQuadCurve(
            to: CGPoint(x: waveWidth * 0.5, y: midY),
            control: CGPoint(x: waveWidth * 0.25, y: midY - h * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: waveWidth, y: midY),
            control: CGPoint(x: waveWidth * 0.75, y: midY + h * 0.5)
        )

        // 第二个波浪
        path.addQuadCurve(
            to: CGPoint(x: waveWidth * 1.5, y: midY),
            control: CGPoint(x: waveWidth * 1.25, y: midY - h * 0.5)
        )
        path.addQuadCurve(
            to: CGPoint(x: w, y: midY),
            control: CGPoint(x: waveWidth * 1.75, y: midY + h * 0.5)
        )

        return path
    }
}

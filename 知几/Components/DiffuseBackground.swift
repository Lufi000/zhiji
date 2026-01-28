import SwiftUI

// MARK: - 噪点纹理

struct NoiseTexture: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<Int(size.width * size.height * 0.02) {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let opacity = Double.random(in: 0.02...0.06)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.black.opacity(opacity))
                )
            }
        }
    }
}

// MARK: - 模糊背景（五行元素渐变 - 均匀分布）

struct DiffuseBackground: View {
    var body: some View {
        ZStack {
            // 深一点的米灰背景
            Color(hex: "EBE8E3")

            // 左上 - 木（草叶绿）
            Circle()
                .fill(RadialGradient(
                    colors: [WuXingColor.grassColor.opacity(0.25), WuXingColor.grassColor.opacity(0.02)],
                    center: .center, startRadius: 0, endRadius: 180
                ))
                .frame(width: 360, height: 360)
                .offset(x: -120, y: -320)
                .blur(radius: 60)

            // 右上 - 金（太阳橙黄）
            Circle()
                .fill(RadialGradient(
                    colors: [WuXingColor.sunColor.opacity(0.2), WuXingColor.sunColor.opacity(0.02)],
                    center: .center, startRadius: 0, endRadius: 160
                ))
                .frame(width: 320, height: 320)
                .offset(x: 140, y: -200)
                .blur(radius: 55)

            // 左中 - 水（波浪蓝）
            Circle()
                .fill(RadialGradient(
                    colors: [WuXingColor.waveColor.opacity(0.2), WuXingColor.waveColor.opacity(0.02)],
                    center: .center, startRadius: 0, endRadius: 150
                ))
                .frame(width: 300, height: 300)
                .offset(x: -150, y: 150)
                .blur(radius: 55)

            // 右中 - 火（石头橙红）
            Circle()
                .fill(RadialGradient(
                    colors: [WuXingColor.stoneColor.opacity(0.18), WuXingColor.stoneColor.opacity(0.02)],
                    center: .center, startRadius: 0, endRadius: 160
                ))
                .frame(width: 320, height: 320)
                .offset(x: 160, y: 250)
                .blur(radius: 60)

            // 底部中间 - 土（大地棕）
            Circle()
                .fill(RadialGradient(
                    colors: [WuXingColor.earthColor.opacity(0.15), WuXingColor.earthColor.opacity(0.02)],
                    center: .center, startRadius: 0, endRadius: 140
                ))
                .frame(width: 280, height: 280)
                .offset(x: 0, y: 500)
                .blur(radius: 50)

            // 噪点纹理叠加
            NoiseTexture()
                .blendMode(.multiply)
        }
        .ignoresSafeArea()
    }
}

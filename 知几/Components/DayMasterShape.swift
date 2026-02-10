import SwiftUI

// MARK: - 日主有机形状
// 根据十天干的五行和阴阳属性，设计10种独特的有机几何图形
// 所有形状边缘圆润，并带有噪点纹理增加艺术感

struct DayMasterShape: View {
    let tianGan: String
    let size: CGFloat
    
    private var wuXing: String {
        BaziConstants.wuXing[tianGan] ?? "木"
    }
    
    private var color: Color {
        WuXingColor.colors(for: wuXing).secondary
    }
    
    var body: some View {
        ZStack {
            // 形状本体
            shapeForTianGan
            
            // 形状上的肌理（使用五行深色）
            ShapeTexture(darkColor: color)
                .blendMode(.multiply)
                .opacity(0.7)
                .clipShape(ShapeClip(tianGan: tianGan))
        }
        .frame(width: size, height: size)
    }
    
    @ViewBuilder
    private var shapeForTianGan: some View {
        switch tianGan {
        case "甲": JiaShape(color: color)      // 阳木：参天大树，向上双叶
        case "乙": YiShape(color: color)       // 阴木：藤蔓花草，S形曲线
        case "丙": BingShape(color: color)     // 阳火：太阳烈火，圆润星芒
        case "丁": DingShape(color: color)     // 阴火：烛火灯火，圆润火苗
        case "戊": WuShape(color: color)       // 阳土：高山大地，圆润山形
        case "己": JiShape(color: color)       // 阴土：田园沃土，云朵形
        case "庚": GengShape(color: color)     // 阳金：刀剑斧钺，圆角菱形
        case "辛": XinShape(color: color)      // 阴金：珠玉首饰，圆形
        case "壬": RenShape(color: color)      // 阳水：江河大海，U形波浪
        case "癸": GuiShape(color: color)      // 阴水：雨露泉水，圆润水滴
        default: Circle().fill(color)
        }
    }
}

// MARK: - 背景肌理（较淡，覆盖整个背景区域）

struct BackgroundTexture: View {
    var body: some View {
        Canvas { context, size in
            // 1. 深色细小颗粒 - 主要纹理
            for _ in 0..<Int(size.width * size.height * 0.04) {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let opacity = Double.random(in: 0.08...0.2)
                let dotSize = CGFloat.random(in: 0.5...1.2)
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                    with: .color(.black.opacity(opacity))
                )
            }
            
            // 2. 白色颗粒 - 增加层次
            for _ in 0..<Int(size.width * size.height * 0.02) {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let opacity = Double.random(in: 0.1...0.25)
                let dotSize = CGFloat.random(in: 0.4...1)
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
    }
}

// MARK: - 图案肌理（较明显，用于有机形状上）

struct ShapeTexture: View {
    var darkColor: Color = .black  // 深色噪点颜色，默认黑色
    
    var body: some View {
        Canvas { context, size in
            // 1. 白色中等颗粒斑点
            for _ in 0..<Int(size.width * size.height * 0.012) {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let opacity = Double.random(in: 0.12...0.35)
                let dotSize = CGFloat.random(in: 1...2.5)
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize * CGFloat.random(in: 0.8...1.2))),
                    with: .color(.white.opacity(opacity))
                )
            }
            
            // 2. 白色细小颗粒
            for _ in 0..<Int(size.width * size.height * 0.05) {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let opacity = Double.random(in: 0.06...0.18)
                let dotSize = CGFloat.random(in: 0.3...0.8)
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                    with: .color(.white.opacity(opacity))
                )
            }
            
            // 3. 深色小噪点（使用五行色，加深显示）
            for _ in 0..<Int(size.width * size.height * 0.12) {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let opacity = Double.random(in: 0.5...0.9)
                let dotSize = CGFloat.random(in: 0.5...1.0)
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                    with: .color(darkColor.opacity(opacity))
                )
            }
            
            // 4. 细微划痕
            for _ in 0..<Int(size.width * 0.08) {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let length = CGFloat.random(in: 1.5...5)
                let angle = CGFloat.random(in: 0...CGFloat.pi)
                let opacity = Double.random(in: 0.08...0.2)
                
                var scratchPath = Path()
                scratchPath.move(to: CGPoint(x: x, y: y))
                scratchPath.addLine(to: CGPoint(
                    x: x + cos(angle) * length,
                    y: y + sin(angle) * length
                ))
                
                context.stroke(
                    scratchPath,
                    with: .color(.white.opacity(opacity)),
                    lineWidth: CGFloat.random(in: 0.3...0.8)
                )
            }
        }
    }
}

// MARK: - 兼容旧代码的别名

typealias RisographTexture = BackgroundTexture

// MARK: - 形状裁剪（用于噪点遮罩）

struct ShapeClip: Shape {
    let tianGan: String
    
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        
        switch tianGan {
        case "甲": return jiaPath(w: w, h: h)
        case "乙": return yiPath(w: w, h: h)
        case "丙": return bingPath(w: w, h: h)
        case "丁": return dingPath(w: w, h: h)
        case "戊": return wuPath(w: w, h: h)
        case "己": return jiPath(w: w, h: h)
        case "庚": return gengPath(w: w, h: h)
        case "辛": return xinPath(w: w, h: h)
        case "壬": return renPath(w: w, h: h)
        case "癸": return guiPath(w: w, h: h)
        default: return Path(ellipseIn: rect)
        }
    }
    
    // 甲：双叶形
    private func jiaPath(w: CGFloat, h: CGFloat) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: w * 0.08, y: h * 0.15, width: w * 0.38, height: h * 0.7))
        path.addEllipse(in: CGRect(x: w * 0.54, y: h * 0.15, width: w * 0.38, height: h * 0.7))
        return path
    }
    
    // 乙：S形
    private func yiPath(w: CGFloat, h: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: w * 0.65, y: h * 0.08))
        path.addQuadCurve(to: CGPoint(x: w * 0.35, y: h * 0.5), control: CGPoint(x: w * 0.15, y: h * 0.22))
        path.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.92), control: CGPoint(x: w * 0.85, y: h * 0.78))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.5), control: CGPoint(x: w * 0.7, y: h * 0.72))
        path.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.08), control: CGPoint(x: w * 0.3, y: h * 0.28))
        return path
    }
    
    // 丙：柔和花瓣形
    private func bingPath(w: CGFloat, h: CGFloat) -> Path {
        var path = Path()
        let center = CGPoint(x: w / 2, y: h / 2)
        let outerRadius = min(w, h) * 0.44
        let innerRadius = outerRadius * 0.65
        let points = 8
        
        for i in 0..<points * 2 {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                let prevAngle = Double(i - 1) * .pi / Double(points) - .pi / 2
                let prevRadius = (i - 1).isMultiple(of: 2) ? outerRadius : innerRadius
                let midRadius = (radius + prevRadius) / 2 * 1.12
                let midAngle = (angle + prevAngle) / 2
                let controlPoint = CGPoint(
                    x: center.x + CGFloat(cos(midAngle)) * midRadius,
                    y: center.y + CGFloat(sin(midAngle)) * midRadius
                )
                path.addQuadCurve(to: point, control: controlPoint)
            }
        }
        path.closeSubpath()
        return path
    }
    
    // 丁：圆润心形
    private func dingPath(w: CGFloat, h: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.22))
        path.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.35), control: CGPoint(x: w * 0.25, y: h * 0.12))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.88), control: CGPoint(x: w * 0.15, y: h * 0.65))
        path.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.35), control: CGPoint(x: w * 0.85, y: h * 0.65))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.22), control: CGPoint(x: w * 0.75, y: h * 0.12))
        return path
    }
    
    // 戊：圆润山形
    private func wuPath(w: CGFloat, h: CGFloat) -> Path {
        var path = Path()
        // 顶部圆润
        path.move(to: CGPoint(x: w * 0.35, y: h * 0.2))
        path.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.2), control: CGPoint(x: w * 0.5, y: h * 0.08))
        path.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.55), control: CGPoint(x: w * 0.85, y: h * 0.3))
        path.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.85), control: CGPoint(x: w * 0.92, y: h * 0.7))
        path.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.85), control: CGPoint(x: w * 0.5, y: h * 0.92))
        path.addQuadCurve(to: CGPoint(x: w * 0.12, y: h * 0.55), control: CGPoint(x: w * 0.08, y: h * 0.7))
        path.addQuadCurve(to: CGPoint(x: w * 0.35, y: h * 0.2), control: CGPoint(x: w * 0.15, y: h * 0.3))
        return path
    }
    
    // 己：云朵形
    private func jiPath(w: CGFloat, h: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.6))
        path.addQuadCurve(to: CGPoint(x: w * 0.35, y: h * 0.28), control: CGPoint(x: w * 0.1, y: h * 0.38))
        path.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.28), control: CGPoint(x: w * 0.5, y: h * 0.12))
        path.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.6), control: CGPoint(x: w * 0.9, y: h * 0.38))
        path.addQuadCurve(to: CGPoint(x: w * 0.2, y: h * 0.6), control: CGPoint(x: w * 0.5, y: h * 0.82))
        return path
    }
    
    // 庚：圆润方形
    private func gengPath(w: CGFloat, h: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.12))
        path.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.5), control: CGPoint(x: w * 0.82, y: h * 0.18))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.88), control: CGPoint(x: w * 0.82, y: h * 0.82))
        path.addQuadCurve(to: CGPoint(x: w * 0.12, y: h * 0.5), control: CGPoint(x: w * 0.18, y: h * 0.82))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.12), control: CGPoint(x: w * 0.18, y: h * 0.18))
        return path
    }
    
    // 辛：圆形
    private func xinPath(w: CGFloat, h: CGFloat) -> Path {
        let size = min(w, h) * 0.85
        let offset = (min(w, h) - size) / 2
        return Path(ellipseIn: CGRect(x: offset, y: offset, width: size, height: size))
    }
    
    // 壬：圆润U形
    private func renPath(w: CGFloat, h: CGFloat) -> Path {
        var path = Path()
        let thickness = w * 0.28
        
        // 外轮廓 - 完全圆润的顶部
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.12))
        path.addQuadCurve(to: CGPoint(x: w * 0.1, y: h * 0.25), control: CGPoint(x: w * 0.1, y: h * 0.12))
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.5))
        path.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.5), control: CGPoint(x: w * 0.5, y: h * 0.95))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.25))
        path.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.12), control: CGPoint(x: w * 0.9, y: h * 0.12))
        
        // 内轮廓
        path.addLine(to: CGPoint(x: w * 0.9 - thickness + w * 0.08, y: h * 0.12))
        path.addQuadCurve(to: CGPoint(x: w * 0.9 - thickness, y: h * 0.22), control: CGPoint(x: w * 0.9 - thickness, y: h * 0.12))
        path.addLine(to: CGPoint(x: w * 0.9 - thickness, y: h * 0.5))
        path.addQuadCurve(to: CGPoint(x: w * 0.1 + thickness, y: h * 0.5), control: CGPoint(x: w * 0.5, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.1 + thickness, y: h * 0.22))
        path.addQuadCurve(to: CGPoint(x: w * 0.1 + thickness + w * 0.08, y: h * 0.12), control: CGPoint(x: w * 0.1 + thickness, y: h * 0.12))
        path.closeSubpath()
        return path
    }
    
    // 癸：圆润卵形
    private func guiPath(w: CGFloat, h: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.1))
        path.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.4), control: CGPoint(x: w * 0.72, y: h * 0.15))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.88), control: CGPoint(x: w * 0.82, y: h * 0.7))
        path.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.4), control: CGPoint(x: w * 0.18, y: h * 0.7))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.1), control: CGPoint(x: w * 0.28, y: h * 0.15))
        return path
    }
}

// MARK: - 甲：阳木 - 参天大树，向上的双叶形

struct JiaShape: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            Path { path in
                path.addEllipse(in: CGRect(x: w * 0.08, y: h * 0.15, width: w * 0.38, height: h * 0.7))
                path.addEllipse(in: CGRect(x: w * 0.54, y: h * 0.15, width: w * 0.38, height: h * 0.7))
            }
            .fill(color)
        }
    }
}

// MARK: - 乙：阴木 - 藤蔓花草，S形曲线

struct YiShape: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            Path { path in
                path.move(to: CGPoint(x: w * 0.65, y: h * 0.08))
                path.addQuadCurve(to: CGPoint(x: w * 0.35, y: h * 0.5), control: CGPoint(x: w * 0.15, y: h * 0.22))
                path.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.92), control: CGPoint(x: w * 0.85, y: h * 0.78))
                path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.5), control: CGPoint(x: w * 0.7, y: h * 0.72))
                path.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.08), control: CGPoint(x: w * 0.3, y: h * 0.28))
            }
            .fill(color)
        }
    }
}

// MARK: - 丙：阳火 - 太阳烈火，柔和花瓣形

struct BingShape: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let center = CGPoint(x: w / 2, y: h / 2)
            let outerRadius = min(w, h) * 0.44
            let innerRadius = outerRadius * 0.65  // 更大的内半径，减少尖锐感
            let points = 8  // 减少瓣数，更柔和
            
            Path { path in
                for i in 0..<points * 2 {
                    let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
                    let angle = Double(i) * .pi / Double(points) - .pi / 2
                    let point = CGPoint(
                        x: center.x + CGFloat(cos(angle)) * radius,
                        y: center.y + CGFloat(sin(angle)) * radius
                    )
                    
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        // 用更平滑的曲线连接
                        let prevAngle = Double(i - 1) * .pi / Double(points) - .pi / 2
                        let prevRadius = (i - 1).isMultiple(of: 2) ? outerRadius : innerRadius
                        let midRadius = (radius + prevRadius) / 2 * 1.12  // 更饱满的曲线
                        let midAngle = (angle + prevAngle) / 2
                        let controlPoint = CGPoint(
                            x: center.x + CGFloat(cos(midAngle)) * midRadius,
                            y: center.y + CGFloat(sin(midAngle)) * midRadius
                        )
                        path.addQuadCurve(to: point, control: controlPoint)
                    }
                }
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

// MARK: - 丁：阴火 - 烛火灯火，圆润心形

struct DingShape: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            // 类似心形但更圆润，顶部两个弧
            Path { path in
                path.move(to: CGPoint(x: w * 0.5, y: h * 0.22))
                // 左上弧
                path.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.35), control: CGPoint(x: w * 0.25, y: h * 0.12))
                // 左侧弧到底部
                path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.88), control: CGPoint(x: w * 0.15, y: h * 0.65))
                // 右侧弧
                path.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.35), control: CGPoint(x: w * 0.85, y: h * 0.65))
                // 右上弧回到中心
                path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.22), control: CGPoint(x: w * 0.75, y: h * 0.12))
            }
            .fill(color)
        }
    }
}

// MARK: - 戊：阳土 - 高山大地，圆润山形

struct WuShape: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            Path { path in
                path.move(to: CGPoint(x: w * 0.35, y: h * 0.2))
                path.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.2), control: CGPoint(x: w * 0.5, y: h * 0.08))
                path.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.55), control: CGPoint(x: w * 0.85, y: h * 0.3))
                path.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.85), control: CGPoint(x: w * 0.92, y: h * 0.7))
                path.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.85), control: CGPoint(x: w * 0.5, y: h * 0.92))
                path.addQuadCurve(to: CGPoint(x: w * 0.12, y: h * 0.55), control: CGPoint(x: w * 0.08, y: h * 0.7))
                path.addQuadCurve(to: CGPoint(x: w * 0.35, y: h * 0.2), control: CGPoint(x: w * 0.15, y: h * 0.3))
            }
            .fill(color)
        }
    }
}

// MARK: - 己：阴土 - 田园沃土，柔和云朵形

struct JiShape: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            Path { path in
                path.move(to: CGPoint(x: w * 0.2, y: h * 0.6))
                path.addQuadCurve(to: CGPoint(x: w * 0.35, y: h * 0.28), control: CGPoint(x: w * 0.1, y: h * 0.38))
                path.addQuadCurve(to: CGPoint(x: w * 0.65, y: h * 0.28), control: CGPoint(x: w * 0.5, y: h * 0.12))
                path.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.6), control: CGPoint(x: w * 0.9, y: h * 0.38))
                path.addQuadCurve(to: CGPoint(x: w * 0.2, y: h * 0.6), control: CGPoint(x: w * 0.5, y: h * 0.82))
            }
            .fill(color)
        }
    }
}

// MARK: - 庚：阳金 - 刀剑斧钺，圆润方形

struct GengShape: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            // 使用更圆润的四边形，控制点更靠近中心
            Path { path in
                path.move(to: CGPoint(x: w * 0.5, y: h * 0.12))
                path.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.5), control: CGPoint(x: w * 0.82, y: h * 0.18))
                path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.88), control: CGPoint(x: w * 0.82, y: h * 0.82))
                path.addQuadCurve(to: CGPoint(x: w * 0.12, y: h * 0.5), control: CGPoint(x: w * 0.18, y: h * 0.82))
                path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.12), control: CGPoint(x: w * 0.18, y: h * 0.18))
            }
            .fill(color)
        }
    }
}

// MARK: - 辛：阴金 - 珠玉首饰，圆润圆形

struct XinShape: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) * 0.85
            let offset = (min(geo.size.width, geo.size.height) - size) / 2
            
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .offset(x: offset, y: offset)
        }
    }
}

// MARK: - 壬：阳水 - 江河大海，圆润U形

struct RenShape: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let thickness = w * 0.28
            
            Path { path in
                // 外轮廓 - 完全圆润的顶部
                path.move(to: CGPoint(x: w * 0.2, y: h * 0.12))
                // 左上圆角
                path.addQuadCurve(to: CGPoint(x: w * 0.1, y: h * 0.25), control: CGPoint(x: w * 0.1, y: h * 0.12))
                // 左侧直线到底部弧
                path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.5))
                // 底部大弧
                path.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.5), control: CGPoint(x: w * 0.5, y: h * 0.95))
                // 右侧直线
                path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.25))
                // 右上圆角
                path.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.12), control: CGPoint(x: w * 0.9, y: h * 0.12))
                
                // 内轮廓
                path.addLine(to: CGPoint(x: w * 0.9 - thickness + w * 0.08, y: h * 0.12))
                path.addQuadCurve(to: CGPoint(x: w * 0.9 - thickness, y: h * 0.22), control: CGPoint(x: w * 0.9 - thickness, y: h * 0.12))
                path.addLine(to: CGPoint(x: w * 0.9 - thickness, y: h * 0.5))
                path.addQuadCurve(to: CGPoint(x: w * 0.1 + thickness, y: h * 0.5), control: CGPoint(x: w * 0.5, y: h * 0.72))
                path.addLine(to: CGPoint(x: w * 0.1 + thickness, y: h * 0.22))
                path.addQuadCurve(to: CGPoint(x: w * 0.1 + thickness + w * 0.08, y: h * 0.12), control: CGPoint(x: w * 0.1 + thickness, y: h * 0.12))
                path.closeSubpath()
            }
            .fill(color, style: FillStyle(eoFill: true))
        }
    }
}

// MARK: - 癸：阴水 - 雨露泉水，圆润卵形

struct GuiShape: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            // 卵形/椭圆形，顶部稍窄但圆润，底部更宽
            Path { path in
                path.move(to: CGPoint(x: w * 0.5, y: h * 0.1))
                // 右上弧
                path.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.4), control: CGPoint(x: w * 0.72, y: h * 0.15))
                // 右下弧
                path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.88), control: CGPoint(x: w * 0.82, y: h * 0.7))
                // 左下弧
                path.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.4), control: CGPoint(x: w * 0.18, y: h * 0.7))
                // 左上弧回到顶部
                path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.1), control: CGPoint(x: w * 0.28, y: h * 0.15))
            }
            .fill(color)
        }
    }
}

// MARK: - Preview

#Preview("所有天干形状") {
    let tianGans = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 20) {
        ForEach(tianGans, id: \.self) { gan in
            VStack(spacing: 8) {
                DayMasterShape(tianGan: gan, size: 60)
                Text(gan)
                    .font(.system(size: 14, weight: .medium))
            }
        }
    }
    .padding(24)
    .background(Color(hex: "F5F5F5"))
}

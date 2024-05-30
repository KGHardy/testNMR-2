//
//  ContentView.swift
//  testNMR
//
//  Created by Ken Hardy on 09/05/2023.
//

import SwiftUI
/*
extension String
{
   func sizeUsingFont(usingFont font: UIFont) -> CGSize
    {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: fontAttributes)
    }
}
// calculate render width and height of text using provided font (without actually rendering)
//let sizeOfText: CGSize = "test string".sizeUsingFont(usingFont: UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.bold))
*/
struct GraphMargins {
    var error: CGFloat
    var top: CGFloat
    var bottom: CGFloat
    var left: CGFloat
    var right: CGFloat
    var ratio: CGFloat
    var lineWidth: CGFloat
    var radius: CGFloat
    var xTicks: Int             // number of x axis ticks including extreme left and right
    var yTicks: Int             // number of y axis ticks including extreme top and bottom
    var tickLength: CGFloat
}

var graphMargins = GraphMargins(error: 0, top:20, bottom:40, left: 70, right: 30, ratio: oniPad ? 0.65 : 0.6, lineWidth: 2, radius: 2, xTicks: 5, yTicks: 5, tickLength: 20)

var xLabels: [String] = []
var yLabels: [String] = []

struct ViewSet1 : View {
    @EnvironmentObject var vC: ViewControl
    @FocusState.Binding var focus: Focusable?
    var page: Int
    var v: Int

    var body: some View {
        
        if v == 0 { ExperimentView(page: page) }
        if v == 1 { SampleView(page: page) }
        if v == 2 { FrequencyView(focus: $focus, page:page) }
        if v == 3 { PulseLengthView(focus: $focus, page: page) }
        if v == 4 { Text("Parameter 4") }
        if v == 5 { LittleDeltaView(focus: $focus, page: page) }
        if v == 6 { BigDeltaView(focus: $focus, page: page) }
        if v == 7 { GradientView(focus: $focus, page: page) }
    }
}

struct ViewSet2 : View {
    @EnvironmentObject var vC: ViewControl
    @FocusState.Binding var focus: Focusable?
    var page: Int
    var v: Int

    var body: some View {
        
        if v == 8 { RepeatTimeView(focus: $focus, page: page) }
        if v == 9 { TauTimeView(focus: $focus, page: page) }
        if v == 10 { TauIncView(focus: $focus, page: page) }
        if v == 11 { NoDataView(focus: $focus, page: page) }
        if v == 12 { Text("Parameter 12") }
        if v == 13 { DelayInSecondsView(focus: $focus, page: page) }
        if v == 14 { TauDView(focus: $focus, page: page) }
        if v == 15 { Text("Parameter 15") }
    }
}

struct ViewSet3 : View {
    @EnvironmentObject var vC: ViewControl
    @FocusState.Binding var focus: Focusable?
    var page: Int
    var v: Int

    var body: some View {
        
        if v == 16 { UserTagView(focus: $focus, page: page)}
        if v == 17 { NumberOfRunsView(focus: $focus, page: page) }
        if v == 18 { NumberOfExperimentsView(focus: $focus, page: page) }
        if v == 19 { NumberOfScansView(focus: $focus, page: page) }
        if v == 20 { UserTagView(focus: $focus, page: page) }
        if v == 21 { T1GuessView(focus: $focus, page: page) }
        if v == 22 { T2GuessView(focus: $focus, page: page) }
        if v == 23 { TauStepView(focus: $focus, page: page) }
    }
}

struct ViewSet4 : View {
    @EnvironmentObject var vC: ViewControl
    @FocusState.Binding var focus: Focusable?
    var page: Int
    var v: Int

    var body: some View {
        
        if v == 24 { NoOfDataPointsView(focus: $focus, page: page) }
        if v == 25 { SamplingTimeView(focus: $focus, page: page) }
        if v == 26 { FilterFrequencyView(focus: $focus, page: page) }
        if v == 27 { WindowTimeView(focus: $focus, page: page) }
        if v == 28 { ActionButtons(page: page) }
    }
}

struct TabPageView : View {
    @EnvironmentObject var vC: ViewControl
    @FocusState.Binding var focus: Focusable?
    var page: Int
    
    var body: some View {
        VStack (spacing: -10){
            ForEach(paramPos.pageSeq[page],id:\.self) {v in
                if allSettings.paramMap.prompts[v] != "" {
                    if v < 8 {
                        ViewSet1(focus: $focus, page: page, v: v)
                    } else {
                        if v < 16 {
                            ViewSet2(focus: $focus, page: page, v: v)
                        } else {
                            if v < 24 {
                                ViewSet3(focus: $focus, page: page, v: v)
                            } else {
                                if v < 32 {
                                    ViewSet4(focus: $focus, page: page, v: v)
                                }
                            }
                        }
                    }
                }
            }
            Spacer()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var vC: ViewControl
    @FocusState var focus: Focusable?

    func frame1(size: CGSize) -> (w: CGFloat, h: CGFloat, x: CGFloat, y: CGFloat) {
        var h,w,x,y : CGFloat
        
        landscape = size.width >= size.height
        w = size.width;
        h = size.height * (1 - graphMargins.ratio)
        x = size.width / 2
        y = h / 2
        return (w,h,x,y)
    }

    func frame2(size: CGSize) -> (w: CGFloat, h: CGFloat, x: CGFloat, y: CGFloat) {
        var h,w,x,y : CGFloat
        
        w = size.width;
        h = size.height * graphMargins.ratio
        x = size.width / 2
        y = h / 2 + size.height * (1 - graphMargins.ratio)
        if runData.errorMsg == "" {
            if graphMargins.error > 0 {
                graphMargins.top -= graphMargins.error
                graphMargins.error = 0
            }
        } else {
            if graphMargins.error == 0 {
                graphMargins.error = 20
                graphMargins.top += graphMargins.error
            }
        }
        return (w,h,x,y)
    }

    var body: some View {
        
        NavigationView {
            GeometryReader { reader in
                let f1 = frame1(size: reader.size)
                let f2 = frame2(size: reader.size)
                ZStack {
                    if vC.viewName == .settings {
                        Settings(size: reader.size)
                    } else {
                        TabView(selection: $vC.viewTag) {
                            ForEach(paramPos.pages, id:\.self) {page in
                                TabPageView(focus: $focus, page: page)
                                    .tabItem{Image(systemName: "\(page + 1).circle")}
                                    .tag(page)
                            }
                        }
                        .frame(width: f1.w, height: f1.h)
                        .position(x: f1.x, y: f1.y)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                        if runData.errorMsg != "" {
                            Text(runData.errorMsg)
                                .foregroundColor(.white)
                                .background(Color.red)
                                .position(x: f2.x, y: f1.h + graphMargins.error / 2)
                        }
                        if vC.viewName == .results {
                            switch vC.viewResult {
                            case .raw:
                                ResultView(xRData: [], yRData: yRealdata, xIData: [], yIData: yImagdata, gm: graphMargins) // position and size frame for the view
                                    .frame(width: f2.w, height: f2.h)
                                    .position(x: f2.x, y: f2.y)
                            case .ft:
                                ResultView(xRData: xFTdata, yRData: yFTdata, xIData: xFitdata, yIData: yFitdata, gm: graphMargins) // position and size frame for the view
                                    .frame(width: f2.w, height: f2.h)
                                    .position(x: f2.x, y: f2.y)
                            case .fit:
                                if frequencyScan.count > 1 || pulseScan.count > 1 {
                                    ResultView(xRData: xPsd, yRData: yPsd, xIData: xFit, yIData: yFit, gm: graphMargins) // position and size frame for the view
                                        .frame(width: f2.w, height: f2.h)
                                        .position(x: f2.x, y: f2.y)
                                }
                            }
                        }
                    }
                    if vC.viewMenu {
                        MenuView(size: reader.size)
                    }
                }
                .navigationBarTitle("nmrClient App", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            vC.viewMenu.toggle()
                               },
                               label: {Image(systemName: "line.3.horizontal")
                               }
                        )
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {print("Save selected")
                               },
                               label: {Image(systemName: "folder")
                               }
                        )
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {copySettings = allSettings
                                        if vC.viewName != .settings {
                                            vC.pushName()
                                            vC.viewName = .settings
                                        } else {
                                            vC.viewName = vC.popName()
                                        }
                               },
                               label: {Image(systemName: "gearshape")
                               }
                        )
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MenuView: View {
    @EnvironmentObject var vC: ViewControl
    var size: CGSize
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Toggle("Disable Frequency Entry", isOn: $vC.disableNcoFreq)
                    .padding(.leading, 10)
                Spacer()
            }
            Spacer()
        }
        .frame(width: size.width / 2, height: size.height / 2)
        .background(Color(red: 218/255, green: 218/255, blue: 218/255))
        .position(CGPoint(x: size.width / 4, y: size.height / 4))
    }
}

struct ResultView: View {
    var xRData: [Double]
    var yRData: [Double]
    var xIData: [Double]
    var yIData: [Double]
    var gm: GraphMargins

    func setLabels(_ minX: CGFloat, _ maxX: CGFloat, _ xScale: CGFloat, _ minY: CGFloat, _ maxY: CGFloat, _ yScale: CGFloat) -> Void {
        
        func fmt(_ max:CGFloat, _ x: CGFloat) -> String {
            if abs(max) > 1000 {
                return String(format: "%.0f", x)
            }
            if abs(max) > 100 {
                return String(format: "%.1f", x)
            }
            if abs(max) > 10{
                return String(format: "%.2f", x)
            }
            return String(format: "%.4f",x)
        }
        
        xLabels.removeAll()
        xLabels.append(fmt(maxX, minX))
        let vx = (maxX - minX) / CGFloat(gm.xTicks - 1)
        for ix in 1..<gm.xTicks - 1 {
            let v = minX + vx * CGFloat(ix)
            xLabels.append(fmt(maxX, v))
        }
        xLabels.append(fmt(maxX, maxX))
        
        yLabels.removeAll()
        yLabels.append(fmt(maxY, maxY))
        let vy = (maxY - minY) / CGFloat(gm.yTicks - 1)
        for iy in 1..<gm.yTicks - 1 {
            let v = maxY - vy * CGFloat(iy)
            yLabels.append(fmt(maxY, v))
        }
        yLabels.append(fmt(maxY, minY))
    }
    
    func scaleValues(size: CGSize,ftOption: Int) -> (maxX: CGFloat, minX:CGFloat, maxY: CGFloat, minY: CGFloat, xScale: CGFloat, yScale:CGFloat) {
        
        var maxX : CGFloat
        var minX : CGFloat
        var maxY : CGFloat
        var minY : CGFloat
        
        if ftOption < 2 {
            if xRData.count == 0 {
                maxX = CGFloat(yRData.count - 1)
                minX = 0
            } else {
                maxX = xRData.max()!
                minX = xRData.min()!
            }
        } else {
            if xIData.count == 0 {
                maxX = CGFloat(yIData.count - 1)
                minX = 0
            } else {
                maxX = xIData.max()!
                minX = xIData.min()!
            }
        }
        if maxX > 0 && minX < 0 {
            minX = [0 - maxX, minX].min()!
            maxX = [0 - minX, maxX].max()!
        }
        
        if ftOption == 0 {
            if yIData.count == 0 {
                if yRData.count == 0 {
                    maxY = 0
                    minY = 0
                } else {
                    maxY = yRData.max()!
                    minY = yRData.min()!
                }
            } else {
                maxY = [yRData.max()!, yIData.max()!].max()!
                minY = [yRData.min()!, yIData.min()!].min()!
            }
        } else {
            if ftOption == 1 {
                if yRData.count == 0 {
                    maxY = 0
                    minY = 0
                } else {
                    maxY = yRData.max()!
                    minY = yRData.min()!
                }
            } else {
                if yIData.count == 0 {
                    maxY = 0
                    minY = 0
                } else {
                    maxY = yIData.max()!
                    minY = yIData.min()!
                }
            }
        }
        if maxY > 0 && minY < 0 {
            minY = [0 - maxY, minY].min()!
            maxY = [0 - minY, maxY].max()!
        }
        let xScale = (size.width - gm.left - gm.right) / (maxX - minX)
        let yScale = (size.height - gm.top - gm.bottom) / (maxY - minY)
        setLabels(minX, maxX, xScale, minY, maxY, yScale)
        return (maxX: maxX, minX: minX, maxY: maxY, minY: minY, xScale: xScale, yScale: yScale)
    }
    
    func xR(_ index: Int, _ minX: CGFloat) -> CGFloat {
        if xRData.count == 0 { return CGFloat(index)}
        return xRData[index] - minX
    }
    
    func xI(_ index: Int, _ minX: CGFloat) -> CGFloat {
        if xIData.count == 0 { return CGFloat(index)}
        return xIData[index] - minX
    }
    
    func xRCount() -> Int {
        if xRData.count == 0 {
            return yRData.count
        }
        return xRData.count
    }
    
    func xICount() -> Int {
        if xIData.count == 0 {
            return yIData.count
        }
        return xIData.count
    }
    
    var body: some View {
        GeometryReader { reader in
            
            let scale1 = scaleValues(size: reader.size, ftOption: viewControl.viewResult == .raw ? 0 : 0)
            
            Path() {path in // Graph Bounds and Drawing Area
                func draw(_ x: [CGFloat], _ y: [CGFloat]) -> Void {
                    path.move(to: CGPoint(x: x[0],y: y[0]))
                    path.addLine(to: CGPoint(x: x[1], y: y[0]))
                    path.addLine(to: CGPoint(x: x[1], y: y[1]))
                    path.addLine(to: CGPoint(x: x[0], y: y[1]))
                    path.addLine(to: CGPoint(x: x[0], y: y[0]))
                    path.move(to: CGPoint(x: x[0], y: y[0]))
                    path.addLine(to: CGPoint(x: x[0], y: y[1]))
                    path.move(to: CGPoint(x: x[0],y: y[0]))
                }
                var x : [CGFloat] = [0, reader.size.width]
                var y : [CGFloat] = [0, reader.size.height]
                draw(x, y) // outer frame
                x = [gm.left, reader.size.width - gm.right]
                y = [gm.top, reader.size.height - gm.bottom]
                draw(x, y) // inner graph area
            }
            .stroke(Color.black, lineWidth: gm.lineWidth)
            
            if scale1.minX < 0 && scale1.maxX > 0 { // need y axis
                let x = (0 - scale1.minX) * scale1.xScale + gm.left
                let step = (reader.size.height - gm.top - gm.bottom) / Double(gm.yTicks - 1)
                Path() { path in
                    for yT in 0..<gm.yTicks {
                        let y = gm.top + step * Double(yT)
                        path.move(to: CGPoint(x: x - gm.tickLength / 2, y: y))
                        path.addLine(to: CGPoint(x: x + gm.tickLength / 2, y: y))
                    }
                }
                .stroke(Color.black, lineWidth: gm.lineWidth * 2)
                Path() {path in
                    path.move(to: CGPoint(x: x, y: gm.top))
                    path.addLine(to: CGPoint(x: x, y: reader.size.height - gm.bottom))
                }
                .stroke(Color.black, lineWidth: gm.lineWidth)
            } else {
                if gm.yTicks > 0 {
                    let x = gm.left
                    let step = (reader.size.height - gm.top - gm.bottom) / Double(gm.yTicks - 1)
                    Path() {path in
                        for yT in 0..<gm.yTicks {
                            let y = gm.top + step * Double(yT)
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x + gm.tickLength / 2, y: y))
                        }
                    }
                    .stroke(Color.black, lineWidth: gm.lineWidth * 2)
                }
            }
                
            if scale1.minY < 0 && scale1.maxY > 0 { // need x axis
                let y = (scale1.maxY - 0 ) * scale1.yScale + gm.top
                let step = (reader.size.width - gm.left - gm.right) / Double(gm.xTicks - 1)
                Path() {path in
                    for xT in 0..<gm.xTicks {
                        let x = gm.left + step * Double(xT)
                        path.move(to: CGPoint(x: x, y: y - gm.tickLength / 2))
                        path.addLine(to: CGPoint(x: x, y: y + gm.tickLength / 2))
                    }
                }
                .stroke(Color.black, lineWidth: gm.lineWidth * 2)
                Path() {path in
                    path.move(to: CGPoint(x: gm.left, y: y))
                    path.addLine(to: CGPoint(x: reader.size.width - gm.right, y: y))
                }
                .stroke(Color.black, lineWidth: gm.lineWidth)
            } else {
                if gm.xTicks > 0 {
                    let y = reader.size.height - gm.bottom
                    Path() {path in
                        for xT in 0..<gm.xTicks {
                            let step = (reader.size.width - gm.left - gm.right) / Double(gm.xTicks - 1)
                            let x = gm.left + step * Double(xT)
                            path.move(to: CGPoint(x: x, y: y - gm.tickLength / 2))
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(Color.black, lineWidth: gm.lineWidth * 2)
                }
            }
                
            Path() {path in
                for ix in 0..<yRData.count {
                    if ix < xRCount() {
                        let vx = xR(ix, scale1.minX) * scale1.xScale + gm.left
                        let vy = (scale1.maxY - yRData[ix]) * scale1.yScale + gm.top
                        path.addArc(center: CGPoint(x: vx, y: vy), radius: viewControl.viewResult == .fit ? gm.radius * 2 : gm.radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
                    }
                }
            }
            .stroke(Color.blue, lineWidth: viewControl.viewResult == .fit ? gm.lineWidth * 2 : gm.lineWidth)
                
            let scale2 = scaleValues(size: reader.size, ftOption: viewControl.viewResult == .raw ? 0 : 0)
            Path() {path in
                for ix in 0..<yIData.count {
                    if ix < xICount() {
                        let vx = xI(ix,scale2.minX) * scale2.xScale + gm.left
                        let vy = (scale2.maxY - yIData[ix]) * scale2.yScale + gm.top
                        if viewControl.viewResult == .raw {
                            path.addArc(center: CGPoint(x: vx, y: vy), radius: gm.radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
                        } else {
                            if ix == 0 {
                                path.move(to: CGPoint(x: vx, y: vy))
                            } else {
                                path.addLine(to: CGPoint(x: vx, y: vy))
                            }
                        }
                    }
                }
            }
            .stroke(Color.red, lineWidth: gm.lineWidth)
            
            if gm.xTicks > 0 {
                ForEach (0..<gm.xTicks, id: \.self) {ix in
                    let step = (reader.size.width - gm.left - gm.right) / Double(gm.xTicks - 1)
                    let x = gm.left + step * Double(ix)
                    Text(xLabels[ix])
                        .position(x: x, y: reader.size.height - gm.bottom / 2)
                }
            }
            if gm.yTicks > 0 {
                ForEach (0..<gm.yTicks, id: \.self) {iy in
                    let step = (reader.size.height - gm.top - gm.bottom) / Double(gm.yTicks - 1)
                    let y = gm.top + step * Double(iy)
                    Text(yLabels[iy])
                        .position(x: gm.left / 2, y:y)
                }
            }
                
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

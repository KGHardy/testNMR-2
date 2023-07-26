//
//  Settings.swift
//  testNMR
//
//  Created by Ken Hardy on 23/05/2023.
//

import SwiftUI

enum Focusable: Hashable {
    case none
    case field(id: Int)
}

struct EntryField : View {
    @Binding var value : String
    @FocusState.Binding var focusField: Focusable?
    var max: Int
    var index: [Int]

     func storeValue() {
        copySettings.paramMap.page[index[0]][index[1]] = Int(value) ?? 0
    }
    
    var body: some View {
        
        var ovalue = value
        TextField("", text: $value)
            .focused($focusField, equals: .field(id: index[0] * 100 + index[1]))
            .padding(.leading, 2)
            .border(.black)
            .foregroundColor(.black)
            .keyboardType(oniPad ? .asciiCapableNumberPad : .asciiCapable)
            .submitLabel(.done)
            /*.onChange(of: focused, perform: { isFocused in
                if !isFocused {
                    storeValue()
                }
            })*/
            .onChange(of: value, perform: {entry in
                if entry == "" {
                    value = entry
                    ovalue = entry
                } else {
                    let nvalue = entry.filter{$0.isNumber}
                    if let nv = Int(nvalue) {
                        if nv >= 0 && nv <= max {
                            value = "\(nv)"
                            ovalue = value
                            storeValue()
                        } else {
                            value = ovalue
                        }
                    } else {
                        value = ovalue
                    }
                }
            })
            .onSubmit {
                storeValue()
                focusField = .field(id: allSettings.paramMap.nextFocus(index: index))
            }
    }
}

struct ScannerSettings: Codable {
    var hostname: String = "10.42.0.1"
    var hostport: Int = 1001
}
/*
 
 let hostName = p.hostName!               // 0
 let portNo = p.portNo!                   // 1
 let ncoFreq = p.ncoFreq!                 // 2
 let pulseLength = p.pulseLength!         // 3
 //var pulseStep = 0                        // 4
 let littleDelta = p.littleDelta!         // 5   in micros
 let bigDelta = p.bigDelta! * 1000        // 6   in ms
 //let noScans: Int = 1
 let gradient = p.gradient!               // 7
 //let noExpts:Int  = 1
 var rptTime = p.rptTime!                 // 8
 rptTime *= 1000
 var tauTime = p.tauTime!                 // 9
 var t1Guess = tauTime
 if t1Guess > 2000 { t1Guess = 2000 }
 if tauTime < 25 && tauTime > 0 { tauTime = 50 }
 var tau = tauTime
 let tauInc = p.tauInc!                   // 10
 let noData = p.noData!                   // 11
 let exptSelect = p.exptSelect!           // 12
 var noEchoes: Int = 0
 if ["CPMG", "CPMGX", "CPMXY"].contains(exptSelect) {noEchoes = tauInc }
 let delayInSeconds = p.delayInSeconds!   // 13
 var tauD = p.tauD!                       // 14
 if tauD > 100000 { tauD = 100000 }
 var progSatDelay = p.progSatDelay!       //15
 
 var hostName: String?           // 0
 var portNo: Int?                // 1
 var ncoFreq: Int?               // 2
 var pulseLength: Int?           // 3
 var pulseStep: Int?             // 4 superceded
 var littleDelta: Int?           // 5
 var bigDelta: Int?              // 6
 var gradient: Int?              // 7
 var rptTime: Int?               // 8
 var tauTime: Int?               // 9
 var tauInc: Int?                // 10
 var noData: Int?                // 11
 var exptSelect: String?         // 12
 var delayInSeconds: Double?     // 13
 var tauD: Int?                  // 14
 var progSatDelay: [Int]?        // 15

 */

enum ParamType {
    case integer
    case string
    case double
    case integerarray
}

enum ParamView {
    case nothing
    case picker
    case stepper
    case slider
    case input
}
/*
struct Param {
    var pName: String
    var pPrompt: String
    var pType: ParamType
    var pView: ParamView
    
    var min: Double?
    var max: Double?
    
    var values: [String]?
    
    init(_ pName: String, _ pPrompt: String, _ pType: ParamType, _ pView: ParamView) {
        self.pName = pName
        self.pPrompt = pPrompt
        self.pType = pType
        self.pView = pView
    }
}

var Parameters: [Param] = [Param("hostname", "Host Name", .string, .text),
                           Param("portno", "Port Number", .integer, .text),
                           Param("ncofreq", "nco Frequency", .integer, .slider)
]


struct NewParameterMap {
    var params  = ["hostname",          // 0                String
                   "portno",            // 1                Integer
                   "ncofreq",           // 2                Integer
                   "pulselength",       // 3                Integer
                   "pulsestep",         // 4 = 0            Integer
                   "littledelta",       // 5                Integer
                   "bigdelta",          // 6                Integer
                   "gradient",          // 7                Integer
                   "rpttime",           // 8                Integer
                   "tautime",           // 9                Integer
                   "tauinc",            // 10               Integer
                   "nodata",            // 11               Integer
                   "exptselect",        // 12               String
                   "delayinseconds",    // 13               Double
                   "taud",              // 14               Integer
                   "progsatarray",      // 15               Integer Array
                   "sample",            //                  String
                   "noruns",            //                  Integer
                   "noexperiments",     //                  Integer
                   "noscans"            //                  Integer
                  ]
    
    var paramTypes: [ParamType] = [
                    .string,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .integer,
                    .string,
                    .double,
                    .integer,
                    .integerarray,
                    .string,
                    .integer,
                    .integer,
                    .integer
    ]
    var prompts = [
                                            // Passed parameter data
                    "Host Name",
                    "Port Number",
                    "Frequency",
                    "Pulse Length",
                    "Pulse Step",
                    "Little Delta",
                    "Big Delta",
                    "Gradient",
                    "Repeat Time",
                    "Tau Time",
                    "Tau Inc",
                    "Number of Datapoints",
                    "Experiment Name",
                    "Delay in Seconds",
                    "Tau D",
                    "Prog Sat Delay",
                                            // Other data to be entered
                    "Sample",
                    "Number of Runs",
                    "Number of Experiments",
                    "Number of Scans"
                  ]
}
*/
struct ParameterMap: Codable {
    var prompts = ["Experiment",                //  0
                   "Sample",                    //  1
                   "Frequency Hz",              //  2
                   "Pulse Length/ns",           //  3
                   "",                          //  4 Not Used
                   "Little Delta",              //  5
                   "Big Delta",                 //  6
                   "Gradient",                  //  7
                   "Repeat Time ms",            //  8
                   "Tau Time",                  //  9
                   "Tau Inc",                   // 10
                   "No Data",                   // 11
                   "",                          // 12 exptSelect
                   "Delay In Seconds",          // 13
                   "Tau D",                     // 14
                   "",                          // 15 Prog Sat Delay
                   "User Tag",                  // 16 User Tag
                   "No of Runs",                // 17
                   "No of Exeriments",          // 18
                   "No of Scans",               // 19
                   "Action Buttons"             // 20
    ]
    
    var page : [[Int]] = [[1,2,3,0,4,5,6,0,0,0,0,0,0,0,0,0,0,0,0,0,7],
                          [0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,0,9,0,0,0,10],
                          [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,4],
                          [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]
/*
    @ViewBuilder func getView(page: Int, index: Int) -> some View {
        
        switch index {
        case 0:  ExperimentView(page: page)
        case 1:  SampleView(page: page)
        case 2:  FrequencyView(page: page)
        case 3:  PulseLengthView(page: page)
        case 4:  Text("Parameter 4")
        case 5:  LittleDeltaView(page: page)
        case 6:  BigDeltaView(page: page)
        case 7:  GradientView(page: page)
        case 8:  RepeatTimeView(page: page)
        case 9:  TauTimeView(page: page)
        case 10: TauIncView(page: page)
        case 11: NoDataView(page: page)
        case 12: Text("Parameter 12")
        case 13: DelayInSecondsView(page: page)
        case 14: TauDView(page: page)
        case 15: Text("Parameter 15")
        case 16: Text("Parameter 16")
        case 17: NumberOfRunsView(page: page)
        case 18: NumberOfExperimentsView(page: page)
        case 19: NumberOfScansView(page: page)
        case 20: ActionButtons(page: page)
        default: EmptyView()
        }
    }
*/
    func nextFocus(index: [Int]) -> Int {
        var ix0 = index[0]
        var ix1 = index[1] + 1
        
        while ix1 < prompts.count {
            if prompts[ix1] != "" { break }
            ix1 += 1
        }
        if ix1 >= prompts.count {
            ix0 += 1
            ix1 = 0
            if ix0 < page.count {
                while ix1 < prompts.count {
                    if prompts[ix1] != "" { break }
                    ix1 += 1
                }
            }
        }
        return ix0 * 100 + ix1
    }
}

struct AllSettings: Codable {
    var paramMap = ParameterMap()
    var scanner = ScannerSettings()
}

enum ViewTypes {
    case notused
    case slider
    case stepper
    case picker
    case input
    case button
}

struct ParamPos {
    var pages : [Int] = [0,1,2]
    
    var pageSeq: [[Int]] = [[0,1,2,3,5,6,20],[7,8,9,10,11,13,14,16,20],[17,18,19,20]]
    
        var paramViewType: [ViewTypes] = [.picker,      //  0
                                          .picker,      //  1
                                          .input,       //  2
                                          .input,       //  3
                                          .notused,     //  4
                                          .input,       //  5
                                          .input,       //  6
                                          .input,       //  7
                                          .input,       //  8
                                          .input,       //  9
                                          .input,       // 10
                                          .input,       // 11
                                          .notused,     // 12
                                          .input,       // 13
                                          .input,       // 14
                                          .notused,     // 15
                                          .input,       // 16
                                          .stepper,     // 17
                                          .stepper,     // 18
                                          .stepper,     // 19
                                          .button]      // 20
    
    mutating func build(paramMap: ParameterMap) -> Void {
        pageSeq.removeAll(keepingCapacity: true)
        pages.removeAll(keepingCapacity: true)
        
        var maxS: Int = 0
        var p = -1
        
        for x in 0..<paramMap.page.count {
            maxS = 0
            for y in 0..<paramMap.page[x].count {
                if paramMap.page[x][y] > maxS { maxS = paramMap.page[x][y]}
            }
            if maxS > 0 {
                p += 1
                pages.append(p)
                pageSeq.append([])
                for s in 1...maxS {
                    for y in 0..<paramMap.page[x].count {
                        if paramMap.page[x][y] == s {
                            pageSeq[p].append(y)
                        }
                    }
                }
            }
        }
        maxS = 0
    }
    
    mutating func setParamViewType(index: Int, viewType: ViewTypes) -> Int {
        while paramViewType.count <= index { paramViewType.append(.notused)}
        paramViewType[index] = viewType
        return 0
    }
    
    func nextFocus(page: Int, index: Int) -> Int {
        if page >= pages.count { return nextFocus(page: 0, index: -1) }
        var pos = 0
        if index >= 0 {
            while true {                                // find index position in pageSeq[page]
                if pageSeq[page][pos] == index { break }
                pos += 1
                if pos >= pageSeq[page].count { return -1 }
            }
            pos += 1
        }
        while pos < pageSeq[page].count {               // find next input parameter
            if paramViewType[pageSeq[page][pos]] == .input {
                return page * 100 + pageSeq[page][pos]
            }
            pos += 1
        }
        if page + 1 < pages.count {                     // try next tab page
            viewControl.viewTag = page + 1
            return nextFocus(page: page + 1, index: -1)
        }
        return -1
    }
}

var paramPos = ParamPos()

var allSettings = AllSettings()
var copySettings = AllSettings()        // copy for cancellation in settings

struct ParameterPosition : View {
    @FocusState.Binding var focusField: Focusable?
    
    @State var redraw: Bool = false

    @State var page0 : String
    @State var page1 : String
    @State var page2 : String
    @State var page3 : String

    var index: Int

    /*init(index: Int) {
        self.focusField = Focusable.none
        self.index = index
        self.page0 = "\(allSettings.paramMap.page[0][index])"
        self.page1 = "\(allSettings.paramMap.page[1][index])"
        self.page2 = "\(allSettings.paramMap.page[2][index])"
        self.page3 = "\(allSettings.paramMap.page[3][index])"
    }*/
    
    var body: some View {
        GeometryReader { reader in
            HStack {
                Text("\(copySettings.paramMap.prompts[index])")
                    .padding(.leading, 10)
                    .frame(width: reader.size.width * 0.6, alignment: .leading)
                    .onTapGesture {
                        focusField = .field(id: index)
                        redraw.toggle()
                    }
                Spacer()
                EntryField(value: $page0, focusField: $focusField, max: 99, index: [0,index])
                EntryField(value: $page1, focusField: $focusField, max: 99, index: [1,index])
                EntryField(value: $page2, focusField: $focusField, max: 99, index: [2,index])
                EntryField(value: $page3, focusField: $focusField, max: 99, index: [3,index])
            }
        }
    }
}

struct SettingsPP: View {
    @EnvironmentObject var vC : ViewControl
    @Environment(\.presentationMode) var presentationMode
    //var size : CGSize
    
    @FocusState var focusField: Focusable?
    @State var redraw: Bool = false

    var body: some View {
        //let fontSize : CGFloat  = oniPad ? 24 : 16
        NavigationView {
            GeometryReader {reader in
                    //List {
                    //Group() {
                VStack(spacing: -5) {
                    ForEach (0..<allSettings.paramMap.prompts.count, id: \.self) { index in
                            if allSettings.paramMap.prompts[index] != "" {
                                if index == 0 {
                                    HStack {
                                        Text("Parameter Name")
                                            .padding(.leading, 10)
                                            .frame(width: reader.size.width * 0.58, height: vH.stepper, alignment: .leading)
                                            .onTapGesture {
                                                focusField = Focusable.none
                                                redraw.toggle()
                                            }
                                        Spacer()
                                        Text(oniPad ? "P1 seq" : "P1")
                                            .frame(width: reader.size.width * 0.09, height: vH.stepper, alignment: .leading)
                                            //.font(.system(size: oniPad ? 17 : 15))
                                        Text(oniPad ? "P2 seq" : "P2")
                                            .frame(width: reader.size.width * 0.09, height: vH.stepper, alignment: .leading)
                                            //.font(.system(size: oniPad ? 17 : 15))
                                        Text(oniPad ? "P3 seq" : "P3")
                                            .frame(width: reader.size.width * 0.09, height: vH.stepper, alignment: .leading)
                                            //.font(.system(size: oniPad ? 17 : 15))
                                        Text(oniPad ? "P4 seq" : "P4")
                                            .frame(width: reader.size.width * 0.09, height: vH.stepper, alignment: .leading)
                                            //.font(.system(size: oniPad ? 17 : 15))
                                    }
                                    .frame(height: vH.stepper)
                                }
                                ParameterPosition(focusField: $focusField,
                                                  page0: "\(allSettings.paramMap.page[0][index])",
                                                  page1: "\(allSettings.paramMap.page[1][index])",
                                                  page2: "\(allSettings.paramMap.page[2][index])",
                                                  page3: "\(allSettings.paramMap.page[3][index])",
                                                  index: index)
                                .frame(height: vH.stepper)
                            }
                        }
                    HStack {
                        Spacer()
                        Button(action:{
                            allSettings.paramMap = copySettings.paramMap
                            paramPos.build(paramMap: allSettings.paramMap)
                            saveSettings()
                            presentationMode.wrappedValue.dismiss()
                        }, label:{
                            Text("Save")
                                .font(.system(size: oniPad ? 24 : 16))
                                .padding(5)
                                .border(.black)
                        })
                        Button(action:{
                            copySettings.paramMap = allSettings.paramMap
                            presentationMode.wrappedValue.dismiss()
                        }, label:{
                            Text("Cancel")
                                .font(.system(size: oniPad ? 24 : 16))
                                .foregroundColor(.red)
                                .padding(5)
                                .border(.black)
                        })
                        Spacer()
                    }
                    Spacer()
                }
                .navigationBarTitle("Parameter Map", displayMode: .inline)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            focusField = .field(id: 0)
        }
    }
}

struct Settings: View {
    var size: CGSize
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: ScannerSettingsView(size: size)) {
                    HStack {
                        Text("Scanner Settings")
                            .font(.system(size: 20))
                            .padding(.leading, 40)
                        Spacer()
                        Text(">")
                            .font(.system(size: 20))
                            .padding(.trailing, 40)
                    }
                }
                .padding(.top, 10)
                NavigationLink(destination: SettingsPP()) {
                    HStack {
                        Text("Parameter Map")
                            .font(.system(size: 20))
                            .padding(.leading, 40)
                        Spacer()
                        Text(">")
                            .font(.system(size: 20))
                            .padding(.trailing, 40)
                    }
                }
                .padding(.top, 10)
                HStack {
                    Text("Return")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .padding(.leading, 40)
                    Spacer()
                    Text(">")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .padding(.trailing, 40)
                }
                .padding(.top, 10)
                .onTapGesture {
                    viewControl.viewName = viewControl.popName()
                }
                .navigationBarTitle("Settings", displayMode: .inline)
                Spacer()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings(size: CGSize(width: 100, height: 00))
    }
}

struct ScannerSettingsView : View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var vC : ViewControl
    var size : CGSize
    @State private var hostName : String = allSettings.scanner.hostname
    @State private var portNumber : String = "\(allSettings.scanner.hostport)"
    @FocusState var focusField: Focusable?
    
    var body: some View {
            
        let fontSize : CGFloat  = oniPad ? 24 : 16

        NavigationView {
            VStack {
                Section(header: Text("Scanner Address").font(.system(size: fontSize)))
                {
                    HStack {
                        Text("Host Name")
                            .font(.system(size: fontSize))
                            .padding(.leading, 5)
                        TextField("Host Name", text: $hostName)
                            .focused($focusField, equals: .field(id: 1))
                            .font(.system(size: fontSize))
                            .border(.black)
                            .padding(.leading)
                            .onSubmit {
                                focusField = .field(id: 2)
                            }
                    }
                    HStack {
                        Text("Port Number")
                            .font(.system(size: fontSize))
                            .padding(.leading, 5)
                        TextField("Port Number", text: $portNumber)
                            .focused($focusField, equals: .field(id: 2))
                            .font(.system(size: fontSize))
                            .border(.black)
                            .padding(.leading)
                            .keyboardType(.decimalPad)
                            .onChange(of: portNumber, perform: { value in
                                portNumber = value.filter { $0.isNumber}
                            })
                            .onSubmit {
                                focusField = .field(id: 1)
                            }
                    }
                }
                Section("") {
                    HStack {
                        Spacer()
                        Button(action:{
                            allSettings.scanner.hostname = hostName
                            redPitayaIp = hostName
                            allSettings.scanner.hostport = Int(portNumber) ?? 0
                            saveSettings()
                            presentationMode.wrappedValue.dismiss()
                        }, label:{
                            Text("Save")
                                .font(.system(size: fontSize))
                                .padding(5)
                                .border(.black)
                        })
                        Button(action:{
                            hostName = allSettings.scanner.hostname
                            portNumber = "\(allSettings.scanner.hostport)"
                            presentationMode.wrappedValue.dismiss()
                        }, label:{
                            Text("Cancel")
                                .font(.system(size: fontSize))
                                .foregroundColor(.red)
                                .padding(5)
                                .border(.black)
                        })
                        Spacer()
                    }
                }
                Spacer()
            }
        }
        .navigationBarTitle("Scanner Settings", displayMode: .inline)
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            focusField = .field(id: 1)
            hostName = allSettings.scanner.hostname
            portNumber = "\(allSettings.scanner.hostport)"
        }
    }
}

func buildFilename(name: String) -> URL
{
    let homeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    if name != "" {
        if let fileURL = homeURL?.appendingPathComponent(name) {
            return fileURL
        }
    }
    return homeURL!
}


func deleteAFile(filename: String) -> Void {
    let fileURL = buildFilename(name: filename)
    let fm = FileManager.default
    var filePath = fileURL.absoluteString
    filePath.removeFirst(7)
    if fm.fileExists(atPath: filePath) {
        do {
            try fm.removeItem(at: fileURL)
        }
        catch {
        }
    }
}

func saveToFile(string: String, filename: String) -> Void {
    let fileURL = buildFilename(name: filename)
    let fm = FileManager.default
    var filePath = fileURL.absoluteString
    filePath.removeFirst(7)
    if fm.fileExists(atPath: filePath) {
        do {
            try fm.removeItem(at: fileURL)
        }
        catch {
        }
    }
    do {
        try string.write(to: fileURL, atomically: false, encoding: .utf8)
    } catch {
        print("Write Failed")
    }
}

func readFromFile(fileName: String) -> String {
    let fileURL = buildFilename(name: fileName)
    do {
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        return contents
    } catch {
        return ""
    }
}

func readSettings() -> Bool {
    do {
        let settingsString = readFromFile(fileName: "testNMR.json")
        if settingsString.count > 0 {
            let decoder = JSONDecoder()
            allSettings = try decoder.decode(AllSettings.self, from: settingsString.data(using: .utf8)!)
            redPitayaIp = allSettings.scanner.hostname
            paramPos.build(paramMap: allSettings.paramMap)
            return true
        }
        return false
    } catch {
        return false
    }
}

func saveSettings() -> Void {
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    do {
        let data = try encoder.encode(allSettings)
        let settingsString = String(data: data, encoding: .utf8)!
        saveToFile(string: settingsString, filename: "testNMR.json")
    } catch {
        return
    }
}

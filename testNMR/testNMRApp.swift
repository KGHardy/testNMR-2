//
//  testNMRApp.swift
//  testNMR
//
//  Created by Ken Hardy on 09/05/2023.
//

import SwiftUI
/*
 var hostName: String?           // 0
 var portNo: Int?                // 1
 var ncoFreq: Int?               // 2
 var pulseLength: Int?           // 3
 var pulseStep: Int?             // 4 superceded
 var littleDelta: Int?           // 5
 var bigDelta: Int?              // 6
 var noScans: Int?               // 6 superceded
 var gradient: Int?              // 7
 var noExpts: Int?               // 7 superceded
 var rptTime: Int?               // 8
 var tauTime: Int?               // 9
 var tauInc: Int?                // 10
 var noData: Int?                // 11
 var exptSelect: String?         // 12
 var delayInSeconds: Double?     // 13
 var tauD: Int?                  // 14
 var progSatDelay: [Int]?        // 15
 var userTag: String?
 
 mutating func defaults() -> Void {
     if hostName == nil { hostName = redPitayaIp }
     if portNo == nil { portNo = 1001 }
     if ncoFreq == nil { ncoFreq = 16004000 }
     if pulseLength == nil { pulseLength = 5000 }
     if pulseStep == nil { pulseStep = 0}
     if littleDelta == nil { littleDelta = 0 }
     if bigDelta == nil { bigDelta = 0 }
     if noScans == nil { noScans = 1 }
     if gradient == nil { gradient = 0 }
     if noExpts == nil { noExpts = 1 }
     if rptTime == nil { rptTime = 1000 }
     if tauTime == nil { tauTime = 0 }
     if tauInc == nil { tauInc = 0 }
     if noData == nil { noData = 5000 }
     if exptSelect == nil { exptSelect = "FID" }
     if delayInSeconds == nil { delayInSeconds = 1.0 }
     if tauD == nil { tauD = 0 }
     if progSatDelay == nil { progSatDelay = [-1]}
     if userTag == nil {userTag = "" }
 }
 */

struct GlobalData {
    //index 0
    var experiments = [ "Find Resonance", "Find Pulse Length", "Free Induction Decay", "Spin-Lattice Relaxation","Spin-Spin Relaxation"]
    var experiment: String = "Find Resonance"
    var exptNames = ["FID", "FID", "FID", "", "", ""]
    
    
    //index 1
    var sample: String = ""
    var samples = ["Solvent","Inorganic Dispersion","Organic Dispersion","Polymer Solution","Paramagnetic Solution"]
    
    // index 2
    var frequency: Int = 16004000
    
    // index 3
    var pulseLength: Int = 0
    
    // index 4
    var pulseStep: Int = 0          // not used
    
    // index 5
    var littleDelta : Int = 0
    
    // index 6
    var bigDelta: Int = 0
    
    // index 7
    var gradient: Int = 0
    
    // index 8
    var rptTime: Int = 1000
    
    // index 9
    var tauTime: Int = 0
    
    // index 10
    var tauInc: Int = 0
    
    // index 11
    var noData: Int = 5000
    
    // index 12:
    var exptSelect: String = ""
    
    // index 13
    var delayInSeconds: Double = 1.0
    
    // index 14
    var tauD: Int = 0
    
    // index 15
    var progSatArray: [Int] = [-1]
    
    // index 16
    var userTag: String = ""
    
    // index 17
    var noOfRuns: Int = 1
    
    // index 18
    var noOfExperiments: Int = 1
    
    // index 19
    var noOfScans: Int = 1
    
    mutating func initialValues() -> Void {
        experiment = experiments[0]
        sample = samples[0]
    }
    
    func buildParameters() -> NewParameters {
        var dparams = NewParameters()
        dparams.defaults()
        var nparams = NewParameters()
        if allSettings.scanner.hostname != dparams.hostName {
            nparams.hostName = allSettings.scanner.hostname
        }
        if allSettings.scanner.hostport != dparams.portNo {
            nparams.portNo = allSettings.scanner.hostport
        }
        if frequency != dparams.ncoFreq {
            nparams.ncoFreq = frequency
        }
        if pulseLength != dparams.pulseLength {
            nparams.pulseLength = pulseLength
        }
        if dparams.pulseStep != pulseStep {
            nparams.pulseStep = pulseStep
        }
        if dparams.littleDelta != littleDelta {
            nparams.littleDelta = littleDelta
        }
        if dparams.bigDelta != bigDelta {
            nparams.bigDelta = bigDelta
        }
        if dparams.gradient != gradient {
            nparams.gradient = gradient
        }
        if dparams.rptTime != rptTime {
            nparams.rptTime = rptTime
        }
        if dparams.tauTime != tauTime {
            nparams.tauTime = tauTime
        }
        if dparams.tauInc != tauInc {
            nparams.tauInc = tauInc
        }
        if dparams.noData != noData {
            nparams.noData = noData
        }
        nparams.exptSelect = ""
        for ix in 0..<experiments.count {
            if experiment == experiments[ix]  && ix < exptNames.count {
                nparams.exptSelect = exptNames[ix]
                break
            }
        }
        if dparams.delayInSeconds != delayInSeconds {
            nparams.delayInSeconds = delayInSeconds
        }
        if dparams.tauD != tauD {
            nparams.tauD = tauD
        }
        nparams.progSatDelay = [-1]
        nparams.userTag = ""
        return nparams
    }
}

var gData = GlobalData()

let queue = DispatchQueue(label: "work-queue", qos: .default)
var nmr = NMRServer()

enum ViewNames {
    case parameters     // 0
    case running        // 1
    case results        // 2
    case settings       // 3
}

enum ViewResults {
    case raw            // 0
    case ft             // 1
    case fit            // 2
}

class ViewControl: ObservableObject {
    @Published var viewName = ViewNames.parameters
    @Published var viewRefreshFlag: Bool = false
    @Published var viewResult = ViewResults.raw
    @Published var viewMenu: Bool = false
    
    @Published var viewTag: Int = 0
    
    @Published var frequency : String = "\(gData.frequency)"
    @Published var disableFrequency: Bool = false

    func viewRefresh() -> Void {
        viewRefreshFlag = !viewRefreshFlag
    }
    var viewStack: [ViewNames] = []
    
    func pushName() -> Void {
        viewStack.append(viewName)
    }
    
    func popName() -> ViewNames {
         return viewStack.popLast()!
    }

}

var viewControl = ViewControl()

var running = false
var oniPad = UIDevice.current.userInterfaceIdiom == .pad
var landscape = UIDevice.current.orientation.isLandscape

@main
struct testNMRApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        gData.initialValues()
        _ = readSettings()
    }

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(viewControl)
        }
        .onChange(of: scenePhase) {newPhase in
            switch newPhase {
            case .background:
                break
            case .inactive:
                break
            case .active:
                if !running { // startup code runs after first ContentView
                    running = true
                }
            default:
                break
            }
        }
    }
}

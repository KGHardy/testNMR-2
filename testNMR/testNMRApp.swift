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
     if pulseStep == nil { pulseStep = 1000}
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

class GlobalData {
/*
 All redpitaya parameter fields are declared here.
 
 Parameters that are updated outside the views are also declared in ViewControl.
 Changing the value in ViewControl will cause the redrawing of the view showing its value.
 This is so that the GlobalData value can be updated from a queue other than the main queue and the
 ViewControl value updated when it is safe to redraw the views
*/
    //index 0
    var experiments = [ "Find Resonance", "Find Pulse Length", "Free Induction Decay", "Spin-Lattice Relaxation","Spin-Spin Relaxation"]
    var experiment: String = "Find Resonance"
    var exptNames = ["FID", "FID", "FID", "", "", ""]
    
    var defaultParams = NewParameters()

    //index 1
    var sample: String = "Solvent"
    var samples = ["Solvent","Inorganic Dispersion","Organic Dispersion","Polymer Solution","Paramagnetic Solution"]
    
    // index 2
    var ncoFreq: Int = 12404629
    var ncoFreqEntered = false
    
    // index 3
    var pulseLength: Int = 4000
    var pulseLengthEntered = false
    
    // index 4
    var pulseStep: Int = 0          // not used
    var pulseStepEntered = false
    
    // index 5
    var littleDelta : Int = 0
    var littleDeltaEntered = false
    
    // index 6
    var bigDelta: Int = 0
    var bigDeltaEntered = false
    
    // index 7
    var gradient: Int = 0
    var gradientEntered = false
    
    // index 8
    var rptTime: Int = 1000
    var rptTimeEntered = false
    
    // index 9
    var tauTime: Int = 0
    var tauTimeEntered = false
    
    // index 10
    var tauInc: Int = 0
    var tauIncEntered = false
    
    // index 11
    var noData: Int = 5000
    var noDataEntered = false
    
    // index 12:
    var exptSelect: String = ""
    var exptSelectEntered = false
    
    // index 13
    var delayInSeconds: Double = 1.0
    var delayInSecondsEntered = false
    
    // index 14
    var tauD: Int = 0
    var tauDEntered = false
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
    
    // index 20
    var spectrumMode: String = "FID"
    var spectrumModeEntered = false
    
    // index 21
    var t1Guess: Int = 100              // ma
    var t1GuessEntered = false
    
    // index 22
    var t2Guess: Int = 100              // ms
    var t2GuessEntered = false
    
    // index 23
    var tauStep: Int = 0                // ms
    var tauStepEntered = false
    
    // index 24
    var noOfDataPoints: Int = 5000
    var noOfDataPointsEntered = false
    
    // index 25
    var samplingTime: Double = 1e-6     // seconds
    var samplingTimeEntered = false
    
    // index 26
    var filterFrequency: Int = 200000   // Hz
    var filterFrequencyEntered = false
    
    // index 27
    var windowTime: Int = 1000
    var windowTimeEntered = false

    func initialValues() -> Void {
        experiment = experiments[0]
        sample = samples[0]
    }
    
    init() {
        defaultParams.defaults(exptIndex: 0);
    }
    func switchDefaults(exptIndex: Int) {
        defaultParams.defaults(exptIndex: exptIndex)
    }

    func buildParameters(exptIndex: Int) -> NewParameters {
        var dparams = NewParameters()
        dparams.defaults(exptIndex: exptIndex)
        var nparams = NewParameters()
        nparams.exptIndex = exptIndex
        if allSettings.scanner.hostname != dparams.hostName {
            nparams.hostName = allSettings.scanner.hostname
        }
        if allSettings.scanner.hostport != dparams.portNo {
            nparams.portNo = allSettings.scanner.hostport
        }
        if ncoFreq != dparams.ncoFreq && ncoFreqEntered {
            nparams.ncoFreq = ncoFreq
        }
        if pulseLength > 0 && pulseLength != dparams.pulseLength && pulseLengthEntered {
            nparams.pulseLength = pulseLength
        }
        if dparams.pulseStep != pulseStep && pulseStepEntered {
            nparams.pulseStep = pulseStep
        }
        if dparams.littleDelta != littleDelta && littleDeltaEntered {
            nparams.littleDelta = littleDelta
        }
        if dparams.bigDelta != bigDelta && bigDeltaEntered {
            nparams.bigDelta = bigDelta
        }
        if dparams.gradient != gradient && gradientEntered {
            nparams.gradient = gradient
        }
        if dparams.rptTime != rptTime && rptTimeEntered {
            nparams.rptTime = rptTime
        }
        if dparams.tauTime != tauTime && tauTimeEntered {
            nparams.tauTime = tauTime
        }
        if dparams.tauInc != tauInc && tauIncEntered {
            nparams.tauInc = tauInc
        }
        if dparams.noData != noData && noDataEntered {
            nparams.noData = noData
        }
        nparams.exptSelect = ""
        for ix in 0..<experiments.count {
            if experiment == experiments[ix]  && ix < exptNames.count {
                nparams.exptSelect = exptNames[ix]
                break
            }
        }
        if dparams.delayInSeconds != delayInSeconds && delayInSecondsEntered {
            nparams.delayInSeconds = delayInSeconds
        }
        if dparams.tauD != tauD && tauDEntered {
            nparams.tauD = tauD
        }
        
        nparams.progSatDelay = [-1]
        nparams.userTag = ""
        nparams.version = PARAMETERS_VERSION
        
        if dparams.spectrumMode != spectrumMode && spectrumModeEntered {
            nparams.spectrumMode = spectrumMode
        }
        if dparams.t1Guess != t1Guess && t1GuessEntered {
            nparams.t1Guess = t1Guess
        }
        if dparams.t2Guess != t2Guess && t2GuessEntered {
            nparams.t2Guess = t2Guess
        }
        if dparams.tauStep != tauStep && tauStepEntered {
            nparams.tauStep = tauStep
        }
        if dparams.noOfDataPoints != noOfDataPoints && noOfDataPointsEntered {
            nparams.noOfDataPoints = noOfDataPoints
        }
        if dparams.samplingTime != samplingTime && samplingTimeEntered {
            nparams.samplingTime = samplingTime
        }
        if dparams.filterFrequency != filterFrequency && filterFrequencyEntered {
            nparams.filterFrequency = filterFrequency
        }
        if dparams.windowTime != windowTime && windowTimeEntered {
            nparams.windowTime = windowTime
        }

        return nparams
    }
    
    func itemValue(index: Int) -> String {
        switch index {
        case 2:
            if ncoFreqEntered {
                return "\(gData.ncoFreq)"
            }
        case 3:
            if pulseLengthEntered {
                return "\(pulseLength)"
            }
      //case 4:
          //gData.pulseStep = Int(value)
        case 5:
            if littleDeltaEntered {
                return "\(littleDelta)"
            }
        case 6:
            if bigDeltaEntered {
                return "\(bigDelta)"
            }
        case 7:
            if gradientEntered {
                return "\(gradient)"
            }
        case 8:
            if rptTimeEntered {
                return "\(rptTime)"
            }
        case 9:
            if tauTimeEntered {
                return "\(tauTime)"
            }
        case 10:
            if tauIncEntered {
                return "\(tauInc)"
            }
        case 11:
            if noDataEntered {
                return "\(noData)"
            }
        case 13:
            if delayInSecondsEntered {
                return "\(delayInSeconds)"
            }
        case 14:
            if tauDEntered {
                return "\(tauD)"
            }
        case 17:
            return "\(noOfRuns)"
        case 18:
            return "\(noOfExperiments)"
        case 19:
            return "\(noOfScans)"
        case 21:
            if t1GuessEntered {
                return "\(t1Guess)"
            }
        case 22:
            if t2GuessEntered {
                return "\(t2Guess)"
            }
        case 23:
            if tauStepEntered {
                return "\(tauStep)"
            }
        case 24:
            if noOfDataPointsEntered {
                return "\(noOfDataPoints)"
            }
        case 25:
            if samplingTimeEntered {
                return "\(samplingTime)"
            }
        case 26:
            if filterFrequencyEntered {
                return "\(filterFrequency)"
            }
        case 27:
            if windowTimeEntered {
                return "\(windowTime)"
            }
        default:
            return ""
        }
        return ""
    }
    
    func itemHint(index: Int) -> String {
        switch index {
        case 2:
            if !ncoFreqEntered && defaultParams.ncoFreq != nil {
                return "\(defaultParams.ncoFreq!)"
                //return viewControl.ncoFreqHint
            }
        case 3:
            if !pulseLengthEntered && defaultParams.pulseLength != nil {
                return "\(defaultParams.pulseLength!)"
                //return viewControl.pulseLengthHint
            }
      //case 4:
          //gData.pulseStep = Int(value)
        case 5:
            if !littleDeltaEntered && defaultParams.littleDelta != nil {
                return "\(defaultParams.littleDelta!)"
            }
        case 6:
            if !bigDeltaEntered && defaultParams.bigDelta != nil {
                return "\(defaultParams.bigDelta!)"
            }
        case 7:
            if !gradientEntered && defaultParams.gradient != nil {
                return "\(defaultParams.gradient!)"
            }
        case 8:
            if !rptTimeEntered && defaultParams.rptTime != nil {
                return "\(defaultParams.rptTime!)"
            }
        case 9:
            if !tauTimeEntered && defaultParams.tauTime != nil {
                return "\(defaultParams.tauTime!)"
            }
        case 10:
            if !tauIncEntered && defaultParams.tauInc != nil {
                return "\(defaultParams.tauInc!)"
            }
        case 11:
            if !noDataEntered && defaultParams.noData != nil {
                return "\(defaultParams.noData!)"
            }
        case 13:
            if !delayInSecondsEntered && defaultParams.delayInSeconds != nil {
                return "\(defaultParams.delayInSeconds!)"
            }
        case 14:
            if !tauDEntered && defaultParams.tauD != nil {
                return "\(defaultParams.tauD!)"
            }
        case 17:
            return ""
        case 18:
            return ""
        case 19:
            return ""
        case 21:
            if !t1GuessEntered && defaultParams.t1Guess != nil {
                return "\(defaultParams.t1Guess!)"
            }
        case 22:
            if !t2GuessEntered && defaultParams.t2Guess != nil {
                return "\(defaultParams.t2Guess!)"
            }
        case 23:
            if !tauStepEntered && defaultParams.tauStep != nil{
                return "\(defaultParams.tauStep!)"
            }
        case 24:
            if !noOfDataPointsEntered && defaultParams.noOfDataPoints != nil {
                return "\(defaultParams.noOfDataPoints!)"
            }
        case 25:
            if !samplingTimeEntered && defaultParams.samplingTime != nil {
                return "\(defaultParams.samplingTime!)"
            }
        case 26:
            if !filterFrequencyEntered && defaultParams.filterFrequency != nil {
                return "\(defaultParams.filterFrequency!)"
            }
        case 27:
            if !windowTimeEntered && defaultParams.windowTime != nil {
                return "\(defaultParams.windowTime!)"
            }
        default:
            return ""
        }
        return ""
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
    
    @FocusState var tabFocus: Focusable?
    
    @Published var viewTag: Int = 0
    
    /* see comments in GlobalData above */
    @Published var ncoFreq : String = ""
    @Published var disableNcoFreq: Bool = false
    @Published var ncoFreqHint : String = ""
    @Published var pulseLength : String = ""
    @Published var disablePulseLength: Bool = false
    @Published var pulseLengthHint : String = ""

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

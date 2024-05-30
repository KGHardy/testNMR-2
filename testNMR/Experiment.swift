//
//  Experiment.swift
//  testNMR
//
//  Created by Ken Hardy on 11/06/2023.
//

import Foundation

struct ScanResult: Codable {
    var parameters: NewParameters
    var datapoints : [[Int16]]
}

struct RunData {
    var run: Int = 0
    var experiment: Int = 0
    var scan: Int = 0
    var running = false
    var runCount: Int = 0
    var experimentCount: Int = 0
    var scanCount: Int = 0
    
    var definition: ExperimentDefinition?
    var nmrResult: [[Int16]] = []
    var results: [[[NewResult]]] = []
    var errorMsg = ""
}

var runData = RunData()

class ExperimentDefinition {
    enum WhenToAction {
        case run
        case experiment
        case scan
    }
    struct ParameterStep {
        var name: String
        var index = 0
        var step: Double
        var when: WhenToAction
        var pause: Double
    }
    var runCount: Int = 0
    var experimentCount: Int = 0
    var scanCount: Int = 0
    
    var parameters: [NewParameters] = []
    var parameterIndex = 0
    var steps: [ParameterStep] = []
    
    var preScan: () -> Bool = { return true }
    var postScan: () -> Bool = { return true }
    var postScanUI: () -> Void = { return }
    
    var endRun: () -> Void = { return }
    var endRunUI: () -> Void = { return }
    var startRun: () -> Void = { return }
    
    func doStepPause(step: ParameterStep) -> Void {
        switch step.when {
        case .run:
            if runData.run > 0 && runData.experiment == 0 && runData.scan == 0 { break }
            return
        case .experiment:
            if runData.experiment > 0 && runData.scan == 0 { break }
            return
        case .scan:
            if runData.scan > 0 { break }
            return
        }
        if step.pause > 0 {
            Thread.sleep(forTimeInterval: step.pause)
        }
        if step.index < parameters.count {
            switch step.name {
            case "ncoFreq":
                parameters[step.index].ncoFreq! += Int(step.step)
            case "pulseLength":
                parameters[step.index].pulseLength! += Int(step.step)
            default:
                break
            }
        }
    }
    
    func testStepPause() -> Void {
        for step in steps {
            doStepPause(step: step)
        }
    }
    
    func run() -> Void {
        /*
                run     experiment      scan
                0       0               0               First run, experiment and scan
                0       0               > 0             First run and experiment subsequent scan
                0       > 0             0               First run subsequent experiment first scan
                0       > 0             > 0             First run subsequent experiment and scan
                > 0     0               0               Subsequent run first experiment and scan
                > 0     0               > 0             Subsequent run first experiment subsequent scan
                > 0     > 0             0               Subsequent run and experiment first scan
                > 0     > 0             > 0             Subsequent run experiment and scan
         */
        
        func abortRun(viewName: ViewNames) -> Void {
            runData.running = false
            DispatchQueue.main.async{
                viewControl.viewName = viewName
            }
            
        }
        
        func updateResults() -> Void {
            if runData.experiment == 0 && runData.scan == 0 {
                assert(runData.results.count == runData.run, "runData.results assert run failed")
                runData.results.append([])
            }
            if runData.scan == 0 {
                assert(runData.results[runData.run].count == runData.experiment, "runData.results assert experiment failed")
                runData.results[runData.run].append([])
            }
            assert(runData.results[runData.run][runData.experiment].count == runData.scan, "runData.results assert scan failed")
            runData.results[runData.run][runData.experiment].append(nmr.newResult)
        }
        
        func saveData() -> Void {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            do {
                let data = try encoder.encode(runData.results)
                let format = DateFormatter()
                format.timeZone = .gmt
                format.dateFormat = "yyyyMMddHHmmss"
                let filename = format.string(from: Date()) + ".json"
                saveToFile(string: String(data: data, encoding: .utf8)!, filename: filename)
            }
            catch {
                return
            }

        }
        
        func callExperiment() -> Void {
            runData.errorMsg = ""
            for run in 0..<runData.runCount {
                for experiment in 0..<runData.experimentCount {
                    for scan in 0..<runData.scanCount {
                        runData.run = run
                        runData.experiment = experiment
                        runData.scan = scan
                        self.testStepPause()
                        if self.preScan() {
                            if self.parameterIndex < 0 || self.parameterIndex >= self.parameters.count {
                                runData.errorMsg = "Parameter index out of bounds"
                                abortRun(viewName: .results)
                                break
                            }
                            runData.nmrResult = nmr.experiment(self.parameters[self.parameterIndex])
                            if nmr.newResult.count() > 0 {
                                updateResults()
                                if self.postScan() {
                                    DispatchQueue.main.async {
                                        print(viewControl.viewName)
                                        viewControl.viewName = .results
                                        self.postScanUI()
                                        print(viewControl.viewName)
                                    }
                                } else {
                                    if runData.errorMsg == "" {
                                        runData.errorMsg = "Run cancelled in postScan"
                                    }
                                    abortRun(viewName: .results)
                                    return
                                }
                            } else {
                                runData.errorMsg = nmr.retError
                                abortRun(viewName: .parameters)
                                return
                            }
                        } else {
                            if runData.errorMsg == "" {
                                runData.errorMsg = "Run cancelled in preScan"
                            }
                            abortRun(viewName: .results)
                            return
                        }
                    }
                }
            }
            runData.running = false
            self.endRun()
            DispatchQueue.main.async {
                self.endRunUI()
            }
            saveData()
        }
        
        runData.run = 0
        runData.runCount = runCount
        runData.experiment = 0
        runData.experimentCount = experimentCount
        runData.scan = 0
        runData.scanCount = scanCount

        runData.errorMsg = ""

        runData.definition = self

        runData.nmrResult.removeAll(keepingCapacity: true)
        runData.results.removeAll(keepingCapacity: true)
                
        runData.running = true
        startRun()
        queue.async {
            callExperiment()
        }
    }
}


var xData = Array(stride(from:0.0, through: Double(4095), by: 1.0))
var fitsReturned: [[Double]] = [[]]

// *******  Specific arrays and functionsfor Frequency sweep experiments ********
var frequencyMeasured: [Double] = []
var frequencyScan: [Double] = []

func doFRAnalysis() -> Bool {
    let dataReturn = dataAquirer(xData,runData.nmrResult)
    yRealdata = dataReturn.1
    yImagdata = dataReturn.2
    xFTdata = dataReturn.3
    yFTdata = dataReturn.4
    xFitdata = dataReturn.5
    yFitdata = dataReturn.6
    if runData.scan == 0 {
        fitsReturned.append([dataReturn.7, dataReturn.8, dataReturn.9])
        frequencyMeasured.append(dataReturn.7)
        frequencyScan.append(Double(runData.definition!.parameters[0].ncoFreq!))
    } else {
        fitsReturned[runData.experiment] = [dataReturn.7, dataReturn.8, dataReturn.9]
        frequencyMeasured[runData.experiment] = dataReturn.7
    }
    
    if frequencyScan.count > 1 {
        xPsd = (0..<frequencyScan.count).map {frequencyScan[$0] - 12404629}
        yPsd = (0..<frequencyMeasured.count).map {frequencyMeasured[$0] }
        let result = linearFit(xPsd,yPsd)
        xFit = result.0
        yFit = result.1
        
        let xScale = xFit.max()! - xFit.min()!
        let yScale = yFit.max()! - yFit.min()!
        
        let x0 = 0 - xFit.min()!
        let y0 = yScale * x0 / xScale - yFit.max()!
        
        //print(y0)
        gData.ncoFreq = 12404629 - Int(y0)
    }

    return true
}

func clearFRAnalysis() -> Bool {
    if runData.experiment == 0 && runData.scan == 0 {   //start a run }
        fitsReturned.removeAll(keepingCapacity: true)
        frequencyMeasured.removeAll(keepingCapacity: true)
        frequencyScan.removeAll(keepingCapacity: true)
    }
    return true         // true means continue - false means abort (set runData.errorMsg to say why)
}

func showFRFit() -> Void {
    viewControl.viewResult = runData.experiment > 1 ? .fit : .raw
    viewControl.ncoFreq = "\(gData.ncoFreq)"
    viewControl.disableNcoFreq = true
}

func showFRFitEnd() -> Void {
    showFRFit()
    viewControl.viewTag = 0
}

func doFindResonanceExperiment() -> Void {
    var nparams = gData.buildParameters()
    
    nparams.ncoFreq = gData.ncoFreq               // ensure frequency is set in parameters (if it is to be varied)
    
    let definition = ExperimentDefinition()
    definition.runCount = gData.noOfRuns
    definition.experimentCount = gData.noOfExperiments
    definition.scanCount = gData.noOfScans

    definition.parameters.append(nparams)      // array of parameters so can be different for some scans
    //Specific functions for Frequency Sweep
    definition.preScan = clearFRAnalysis       // clear analysis totals before a new run
    definition.postScan = doFRAnalysis         // calls analysis function after each scan
    definition.postScanUI = showFRFit          // set graph display after each scan
    definition.endRunUI = showFRFitEnd         // set graph display to desired end result
    
    let step1 = ExperimentDefinition.ParameterStep(name: "ncoFreq", index: 0, step: -1000.0, when: .experiment, pause: gData.delayInSeconds)
    definition.steps.append(step1)
    
    definition.run()
}

// ******* Specific arrays and functionsfor Pulse length sweep experiments ********
var pulseMeasured: [Double] = []
var pulseScan: [Double] = []

func doPulseAnalysis() -> Bool {
    let dataReturn = dataAquirer(xData,runData.nmrResult)
    yRealdata = dataReturn.1
    yImagdata = dataReturn.2
    xFTdata = dataReturn.3
    yFTdata = dataReturn.4
    xFitdata = dataReturn.5
    yFitdata = dataReturn.6
    if runData.scan == 0 {
        fitsReturned.append([dataReturn.7, dataReturn.8, dataReturn.9])
        pulseMeasured.append(dataReturn.8)   //FIXME
        pulseScan.append(Double(runData.definition!.parameters[0].pulseLength!)) //FIXME
    } else {
        fitsReturned[runData.experiment] = [dataReturn.7, dataReturn.8, dataReturn.9]
        pulseMeasured[runData.experiment] = dataReturn.8 //FIXME
    }
    // need at least 3 data[poimnts
    if pulseScan.count > 3 {
        xPsd = (0..<pulseScan.count).map {pulseScan[$0]+1000}//FIXME
        yPsd = (0..<pulseMeasured.count).map {pulseMeasured[$0] }
        let resultFit:([Double],[Double]) = lm("Find Pulse Length",xPsd,yPsd)
        //let scaleHeight = resultFit.0[0]
        //let decayConstant = resultFit.0[1]
        let pulseLengthCalculated = resultFit.0[2]
        let xFitLM:[Double] = xPsd //Array(stride(from:minx, through: maxx, by: 2))
        let noOfPoints = 100
        let xPlot = extend(xPsd,noOfPoints)
        let yFitLM = chooseEperiment("Find Pulse Length", resultFit.0,xPlot)
        //let result = linearFit(xPsd,yPsd)
        xFit = xPlot //result.0
        yFit = yFitLM //result.1
        let xScale = xFit.max()! - xFit.min()!
        let yScale = yFit.max()! - yFit.min()!
        
        let x0 = 0 - xFit.min()!
        let y0 = yScale * x0 / xScale - yFit.max()!
        
        print(y0)
        gData.pulseLength = Int(pulseLengthCalculated) //FIXME (may NaN or Overflow)
    }

    return true
}

func clearPulseAnalysis() -> Bool {
    if runData.experiment == 0 && runData.scan == 0 {   //start a run }
        fitsReturned.removeAll(keepingCapacity: true)
        pulseMeasured.removeAll(keepingCapacity: true)
        pulseScan.removeAll(keepingCapacity: true)
    }
    return true         // true means continue - false means abort (set runData.errorMsg to say why)
}
//FIXME
func showPulseFit() -> Void {
    viewControl.viewResult = runData.experiment > 1 ? .fit : .raw
    viewControl.pulseLength = "\(gData.pulseLength)"
    viewControl.disablePulseLength = true
}
//FIXME
func showPulseFitEnd() -> Void {
    showPulseFit()
    viewControl.viewTag = 0
}




func doFindPulseLengthExperiment() -> Void {
    var nparams = gData.buildParameters()
    
    nparams.ncoFreq = gData.ncoFreq               // ensure frequency is set in parameters (if it is to be varied)
    nparams.pulseLength = gData.pulseLength       // ensure pulse length is set in parameters (if it is to be varied)
    
    let definition = ExperimentDefinition()
    definition.runCount = gData.noOfRuns
    definition.experimentCount = gData.noOfExperiments
    definition.scanCount = gData.noOfScans
    
    definition.parameters.append(nparams)
    
    //Specific functions for Pulse Sweep
    definition.preScan = clearPulseAnalysis       // clear analysis totals before a new run
    definition.postScan = doPulseAnalysis         // calls analysis function after each scan
    definition.postScanUI = showPulseFit          // set graph display after each scan
    definition.endRunUI = showPulseFitEnd         // set graph display to desired end result
  
    
    let step1 = ExperimentDefinition.ParameterStep(name: "pulseLength", index: 0, step: 1000.0, when: .experiment, pause: gData.delayInSeconds)
    definition.steps.append(step1)
    
    definition.run()
}

func doExperiment() -> Void {
    for ix in 0..<gData.experiments.count {
        if gData.experiment == gData.experiments[ix] {
            switch ix {
            case 0: doFindResonanceExperiment()
            case 1: doFindPulseLengthExperiment()
           // case 2: doFindT1Experiment()
           // case 3: doFindT2Experiment()
            default: break
            }
            
        }
    }
}

// ******* Specific arrays and functionsfor T1 Experiments ********
func doFindT1Experiment() -> Void {
    var nparams = gData.buildParameters()
    
    nparams.ncoFreq = gData.ncoFreq               // ensure frequency is set in parameters (if it is to be varied)
    nparams.pulseLength = gData.pulseLength       // ensure pulse length is set in parameters (if it is to be varied)
    
    let definition = ExperimentDefinition()
    definition.runCount = gData.noOfRuns
    definition.experimentCount = gData.noOfExperiments
    definition.scanCount = gData.noOfScans
    
    definition.parameters.append(nparams)
    
    //Specific functions for Pulse Sweep
    definition.preScan = clearPulseAnalysis       // clear analysis totals before a new run
    definition.postScan = doPulseAnalysis         // calls analysis function after each scan
    definition.postScanUI = showPulseFit          // set graph display after each scan
    definition.endRunUI = showPulseFitEnd         // set graph display to desired end result
  
    
    let step1 = ExperimentDefinition.ParameterStep(name: "pulseLength", index: 0, step: 1000.0, when: .experiment, pause: gData.delayInSeconds)
    definition.steps.append(step1)
    
    definition.run()
}

//Function to create extended x_array
func extend(_ xIn:[Double],_ noOfPoints:Int) -> [Double]
{
    var x:[Double] = Array(repeating: Double(0.0), count: noOfPoints)
    let xstep = (xIn.max()! - xIn.min()!)/Double(noOfPoints-1)
    for i in 0..<noOfPoints{
        x[i] = xstep*Double(i)
    }
    return x
}

 

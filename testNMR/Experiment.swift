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

 

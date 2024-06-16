//
//  FindResonance.swift
//  testNMR
//
//  Created by Terence Cosgrove on 6/10/24.
//

import Foundation
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
    var nparams = gData.buildParameters(exptIndex: 0)
    
    nparams.ncoFreq = gData.ncoFreq               // ensure frequency is set in parameters (if it is to be varied)
    nparams.defaults(exptIndex: 0)
    
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
    
    let step1 = ExperimentDefinition.ParameterStep(name: "ncoFreq", index: 0, stepArray: [-1000.0, -1000, -1000], when: .experiment, pause: gData.delayInSeconds)
    definition.steps.append(step1)
    
    definition.run()
}

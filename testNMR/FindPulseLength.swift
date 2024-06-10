//
//  FindPulseLength.swift
//  testNMR
//
//  Created by Terence Cosgrove on 6/10/24.
//

import Foundation

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
        //xPsd = (0..<pulseScan.count).map {pulseScan[$0]+1000}//FIXME
        xPsd = (0..<pulseScan.count).map {pulseScan[$0]}//FIXME
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
    //viewControl.viewResult = runData.experiment > 1 ? .fit : .raw
    viewControl.viewResult = pulseScan.count > 3 ? .fit : .raw
    viewControl.pulseLength = "\(gData.pulseLength)"
    viewControl.disablePulseLength = true
}
//FIXME
func showPulseFitEnd() -> Void {
    showPulseFit()
    viewControl.viewTag = 0
}




func doFindPulseLengthExperiment() -> Void {
    var nparams = gData.buildParameters(exptIndex: 1)
    nparams.defaults(exptIndex: 1)
    
    if gData.ncoFreq > 0 {
        nparams.ncoFreq = gData.ncoFreq               // ensure frequency is set in parameters (if it is to be varied)
    }
    if gData.pulseLength > 0 {
        nparams.pulseLength = gData.pulseLength       // ensure pulse length is set in parameters (if it is to be varied)
    }
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

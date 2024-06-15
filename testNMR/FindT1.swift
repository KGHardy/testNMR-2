//
//  FindT1.swift
//  testNMR
//
//  Created by Terence Cosgrove on 6/10/24.
//

import Foundation
// ******* Specific arrays and functionsfor T1 Experiments ********
var T1Measured: [Double] = []
var T1Scan: [Double] = []

func doT1Analysis() -> Bool {
    let dataReturn = dataAquirer(xData,runData.nmrResult)
    yRealdata = dataReturn.1
    yImagdata = dataReturn.2
    xFTdata = dataReturn.3
    yFTdata = dataReturn.4
    xFitdata = dataReturn.5
    yFitdata = dataReturn.6
    if runData.scan == 0 {
        fitsReturned.append([dataReturn.7, dataReturn.8, dataReturn.9])
        T1Measured.append(dataReturn.8)   //FIXME
        T1Scan.append(Double(runData.definition!.parameters[0].pulseLength!)) //FIXME
    } else {
        fitsReturned[runData.experiment] = [dataReturn.7, dataReturn.8, dataReturn.9]
        T1Measured[runData.experiment] = dataReturn.8 //FIXME  Height of Transformed spectrum
    }
    // need at least 3 data[poimnts
    if T1Scan.count > 3 {
        xPsd = (0..<T1Scan.count).map {T1Scan[$0]}//FIXME
        yPsd = (0..<T1Measured.count).map {T1Measured[$0] }
        let resultFit:([Double],[Double]) = lm("Spin-Lattice Relaxation",xPsd,yPsd)
        //let scaleHeight = resultFit.0[0]
        //let decayConstant = resultFit.0[1]
        let T1Calculated = resultFit.0[1]
        let xFitLM:[Double] = xPsd //Array(stride(from:minx, through: maxx, by: 2))
        let noOfPoints = 100
        let xPlot = extend(xPsd,noOfPoints)
        let yFitLM = chooseEperiment("Spin-Lattice Relaxation", resultFit.0,xPlot)
        //let result = linearFit(xPsd,yPsd)
        xFit = xPlot //result.0
        yFit = yFitLM //result.1
        let xScale = xFit.max()! - xFit.min()!
        let yScale = yFit.max()! - yFit.min()!
        
        let x0 = 0 - xFit.min()!
        let y0 = yScale * x0 / xScale - yFit.max()!
        
        print(y0)
        // Where to store result
        gData.t1Guess = Int(T1Calculated) //FIXME (may NaN or Overflow)
    }

    return true
}

func clearT1Analysis() -> Bool {
    if runData.experiment == 0 && runData.scan == 0 {   //start a run }
        fitsReturned.removeAll(keepingCapacity: true)
        T1Measured.removeAll(keepingCapacity: true)
        T1Scan.removeAll(keepingCapacity: true)
    }
    return true         // true means continue - false means abort (set runData.errorMsg to say why)
}
//FIXME
func showT1Fit() -> Void {
    //viewControl.viewResult = runData.experiment > 1 ? .fit : .raw
    viewControl.viewResult = T1Scan.count > 3 ? .fit : .raw
    //viewControl.pulseLength = "\(gData.pulseLength)"
    //viewControl.disablePulseLength = true    //FXIMET1
}
//FIXME
func showT1FitEnd() -> Void {
    showT1Fit()
    viewControl.viewTag = 0
}








func doFindT1Experiment() -> Void {
    var nparams = gData.buildParameters(exptIndex: -1)      // TODO set a proper value
    
    nparams.ncoFreq = gData.ncoFreq               // ensure frequency is set in parameters (if it is to be varied)
    nparams.pulseLength = gData.pulseLength       // ensure pulse length is set in parameters (if it is to be varied)
    
    let definition = ExperimentDefinition()
    definition.runCount = gData.noOfRuns
    definition.experimentCount = gData.noOfExperiments
    definition.scanCount = gData.noOfScans
    
    definition.parameters.append(nparams)
    
    //Specific functions for T1 Experiment
    definition.preScan = clearT1Analysis       // clear analysis totals before a new run
    definition.postScan = doT1Analysis         // calls analysis function after each scan
    definition.postScanUI = showT1Fit          // set graph display after each scan
    definition.endRunUI = showT1FitEnd         // set graph display to desired end result
  
    // Temp defintion assumes T1 is 30 ms 10 data points then taustep= 6*30/9 = 20 ms
    // uses expeontial growth for T1 experiemnt based on T1Guess so step is not constant
    // value is sset as tauD phrs(14)  T1Guess 50  TauSteps  14          21          30          45          66          98         144         213 315         467         691        1022        1513        2239
    //get T1 array
    
    let step1 = ExperimentDefinition.ParameterStep(name: "T1", index: 0, step: 20000000.0, when: .experiment, pause: gData.delayInSeconds)
    definition.steps.append(step1)
    
    definition.run()
}

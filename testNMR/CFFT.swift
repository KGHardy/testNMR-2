//
//  CFFT.swift
//  Complex_FFT
//
//  Created by Terence Cosgrove on 17/09/2022.
//

import Foundation
import Accelerate
//using _ in func definition menas we don't need labels
// call var result=complexFFT(complexReals,complexImaginaries)
// return reals=result.0 imag= result.1
var calcFrequency = 0.0
func complexFFT(_ complexReals:[Double], _ complexImaginaries:[Double])-> (Array<Double>,Array<Double>,Array<Double>,Int,Double,Double,Double) {
    let complexValuesCount = complexReals.count
    // Call to Complex FFT routine need to make copies as input functions are LET
    var localComplexReals=complexReals
    var localComplexImaginaries=complexImaginaries
    if let dft = vDSP_DFT_zop_CreateSetupD(nil,
                                           vDSP_Length(complexValuesCount),
                                           .FORWARD) {
        vDSP_DFT_ExecuteD(dft,
                          localComplexReals,
                          localComplexImaginaries,
                          &localComplexReals,
                          &localComplexImaginaries)
        vDSP_DFT_DestroySetupD(dft)
    }
    // Reorder arrays
    var shiftI = complexImaginaries
    var shiftR = complexReals
    let halfShift = complexValuesCount/2
    for i in 0...halfShift{
        shiftI[i] = localComplexImaginaries[halfShift-1+i]
        shiftR[i] = localComplexReals[halfShift-1+i]
    }
    for i in 0...halfShift-2{
        shiftI[i+halfShift+1] = localComplexImaginaries[i]
        shiftR[i+halfShift+1] = localComplexReals[i]
        
    }
    let flength = complexValuesCount
    let flengthHalf = complexValuesCount/2
    //let n = complexValuesCount
    var frequencyRange:[Double] = Array(stride(from: 0.0, through: Double(flength), by: 1.0))
    // add arrays R and I  and shift
    //var xshifted:[Double] = Array(repeating: Double(0.0), count: flength)
    var sarrayAdd:[Double] = Array(repeating: Double(0.0), count: flength)
    // add arrays R and I  and shift adn limit to +-50000
    for i in 0..<flength{
        //xshifted[i] = (farray[i]-Double(flengthHalf))*1.0e6/(Double(n))
        //add arrays R and I  and get magnitude
        sarrayAdd[i] = pow(shiftI[i],2) + pow(shiftR[i],2)
        sarrayAdd[i] = pow(sarrayAdd[i],0.5)
        frequencyRange[i] = (frequencyRange[i]-Double(flengthHalf+1))*1.0e6/(4096.0)
    }
    // reduce the number of points to 500
    let nlimited:Int = 400//200
       var xLimited:[Double] = Array(repeating: Double(0.0), count: nlimited)
       var sLimited:[Double] = Array(repeating: Double(0.0), count: nlimited)
       var sOutput:[Double] = Array(repeating: Double(0.0), count: nlimited)
    for i in 0..<nlimited{
        xLimited[i] = frequencyRange[flengthHalf-nlimited/2+i]
        sLimited[i] = sarrayAdd[flengthHalf-nlimited/2+i]
    }
    let yftScale = sLimited.max()!
    for i in 0..<nlimited{
        sOutput[i] = sLimited[i]/yftScale
    }
    // add xero
    //sOutput[0] = 0.0

    
    // No do a Levenberg fit toaq Lorentzian
    // get Guesses
    let maxresults = maxd(sOutput)
    //print(maxresults)
    let seeds:[Double] = [maxresults.0, 4.40014002e+03, xLimited[maxresults.1]]
    let args:[[Double]] = [xLimited,sOutput]
    let resultFit:([Double],[Double]) = lm(seeds,args)
    let scaleHeight = resultFit.0[0]
    let maxFrequency = resultFit.0[2]
    let width = resultFit.0[1]
    let scaleHeightError = resultFit.1[0]
    let maxFrequencyError = resultFit.1[2]
    let widthError = resultFit.1[1]
    //print("SEEDS",seeds)
    //print("Results",resultFit.0)
    // make a fit using standard xrange
    let xFit:[Double] = xLimited //Array(stride(from:minx, through: maxx, by: 2))
    let yFit:[Double] = lorentzian(resultFit.0,xFit)
    // scale both fit and data  FIX ME
    /*

 
     minx = xlimited.min()!
     maxx = xlimited.max)!
     step = (maxx-minx)/1000
     var xFit:[Double] = Array(stride(from:minx, through: maxx, by: step))
     var yFit = lorentzian(resultFit,xFit) return xfit to plt whihc niow needs two x arrays
     */
    let yDataMax = sOutput.max()
    let yFitMax = yFit.max()
    //let yBiggest = max(yDataMax!,yFitMax!) // Need to unwrap values from max()
    //FIXME scales fixes  FIXME scales fixes
    /*for i in 0..<nlimited{
        sOutput[i] = sOutput[i]/yBiggest
        yFit[i] = yFit[i]/yBiggest
    }
     */
    //(resultFit.1)
    return(xLimited,sOutput,yFit,nlimited,maxFrequency,scaleHeight,width)
    
    
}


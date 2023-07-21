//
//  dataAqusiition.swift
//  DrawASquare
//
//  Created by Terence Cosgrove on 13/12/2022.
//

import Foundation
import SwiftUI
// Grab the returned data in 16 bt array altreatiung real
// and imaginery

var xFTdata:[Double] = Array(repeating: Double(0.0), count: 4096)
var yFTdata:[Double] = Array(repeating: Double(0.0), count: 4096)

var yRealdata:[Double] = Array(repeating: Double(0.0), count: 4096)
var yImagdata:[Double] = Array(repeating: Double(0.0), count: 4096)
//var yFTdata:[Double] = Array(repeating: Double(0.0), count: 4096)
//var xFTdata:[Double] = Array(repeating: Double(0.0), count: 4096)
var xFitdata:[Double] = Array(repeating: Double(0.0), count: 4096)
var yFitdata:[Double] = Array(repeating: Double(0.0), count: 4096)

var xPsd: [Double] = []
var yPsd: [Double] = []

var xFit: [Double] = []
var yFit: [Double] = []
 
func dataAquirer(_ xData:[Double],_ nmrResult:[[Int16]]) ->([Double],[Double],[Double],[Double],[Double],[Double],[Double],Double,Double,Double){
let returnedData:[[Int16]] = nmrResult
// print(returnedData[0])
let dataLength:Int = returnedData[0].count/2
var maxFrequencyReturned = 0.0
var widthReturned = 0.0
var heightReturned = 0.0
var j = 0
// data stored in two arratys [0] and [1]
    for i in   0..<(dataLength-4) {
    yRealdata[i] = 0.0
    yImagdata[i] = 0.0
    yRealdata[i] = Double(returnedData[0][j+9])
    yImagdata[i] = Double(returnedData[0][j+8])
    yRealdata[i+dataLength-4] = 0.0
    yImagdata[i+dataLength-4] = 0.0
    yRealdata[i+dataLength-4] = Double(returnedData[1][j+1])
    yImagdata[i+dataLength-4] = Double(returnedData[1][j])
    j = j + 2
    }
// Now FT and Fit
   // sizeArray(array: &yRealdata, size: 4096)
    //sizeArray(array: &yImagdata, size: 4096)
    let ftResult = complexFFT(yRealdata,yImagdata)
    xFTdata = ftResult.0
    xFitdata = ftResult.0
    yFTdata = ftResult.1
    yFitdata = ftResult.2
    //let nData = ftResult.3
    maxFrequencyReturned  = ftResult.4
    heightReturned = ftResult.5
    widthReturned = ftResult.6
    //print("Frequency from RP "+String(maxFrequencyReturned))
    // print(yRdata[i],yIdata[i])
    
return(xData,yRealdata,yImagdata,xFTdata,yFTdata,xFitdata,yFitdata,maxFrequencyReturned,heightReturned,widthReturned)
}

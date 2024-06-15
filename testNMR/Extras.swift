//
//  Extras.swift
//  DrawASquare
//
//  Created by Terence Cosgrove on 24/10/2022.
//
//  Make fake Data FiD and FT
// Returns eiethre Time or frequency results depending on bool ftOrNot
import Foundation
import SwiftUI
func fakeData(_ n:Int,_ frequency1:Double,_ pulseLength1:Double,_ noise1:Double,_ t21:Double,_ ftOrNot:Bool,_ filter1:Double) ->([Double],[Double],[Double],Bool,Double,Double,Double){
    let n = 4096 // Should be power of two for the FFT  FIXME
    let pi = Double.pi
    let frequency = frequency1
    let noise = noise1/5
    let filter = filter1
    let phase1 = Double(0.0)
    let amplitude = sin(pulseLength1 / 4000 * pi/2)
    let fs = Double(1000000.0)
    var maxFrequency = 0.0
    var width = 0.0
    var height = 0.0
    let t2 = t21 //scale for time uses n parameter FIXME assumes μseconds
    var yRdata:[Double] = (0..<n).map {amplitude * exp(-Double($0)/t2)*cos(2.0 * pi / fs * Double($0) * frequency + phase1)}
    var yIdata:[Double] = (0..<n).map {amplitude * exp(-Double($0)/t2)*sin(2.0 * pi / fs * Double($0) * frequency + phase1)}
    //Add random Number
    for k in 0 ..< n{
        yRdata[k]=yRdata[k]+noise * (Double(arc4random_uniform(1000000)) - 500000.0)/1.0E7*exp(-Double(k)/filter)
        yIdata[k]=yIdata[k]+noise * (Double(arc4random_uniform(1000000)) - 500000.0)/1.0E7*exp(-Double(k)/filter)
       //print("\(k)   \(sineWave[k])")
    }
    //var xfit = Array(stride(from:0.0, through: Double(n-1), by: 1.0))
    //var yfit = Array(stride(from:0.0, through: Double(n-1), by: 1.0))
    var xdata = Array(stride(from:0.0, through: Double(n-1), by: 1.0))
    // Define integer plotting arrayx
    // scale data
    if(ftOrNot)
    {
        //sizeArray(array: &yRdata, size: 4096)
       // sizeArray(array: &yIdata, size: 4096)
        let ftResult = complexFFT(yRdata,yIdata)
        xdata = ftResult.0
        yRdata = ftResult.1
        yIdata = ftResult.2
       // let nData = ftResult.3
        maxFrequency = ftResult.4
        height = ftResult.5
        width = ftResult.6
        
        //reduced no of data points
    }
  
    return(xdata,yRdata,yIdata,ftOrNot,maxFrequency,height,width)
}
func sizeArray<T>(array: inout [T], size:Int) {
    while (array.count > size) {
        array.removeLast()
    }
}
/*
func maxd( _ x:([Double])) ->(Double,Int){
    let maxvalue = x.sorted(){$0 > $1}
    let index = x.index(of:maxvalue[0])! //force unwrapping
    //print(index)
    return(maxvalue[0],index)
}
 */
func myPrinter(_ string:Int){
    //print("My String ",String(string))
}

func changeState (_ myStatus:String) ->(Bool,Bool) {
    var plotResults:Bool = false
    var ftOrNot:Bool = false
    if(myStatus == "FT"){
        ftOrNot = true
        plotResults = false
        //print(myStatus+" "+String(ftOrNot), String(plotResults)+" >> In FT")
    }
    if(myStatus == "FID"){
        ftOrNot = false
        plotResults = false
        //print(myStatus+" "+String(ftOrNot), String(plotResults)+" >> In FID")
    }
    if(myStatus == "RES"){
        plotResults = true
        // print(myStatus+" "+String(ftOrNot) ,String(plotResults)+" >> In RES")
    }
    return(ftOrNot,plotResults)
}
   
enum FTStatus {
    case FT
    case FID
    case RES
    
    var nextStatus: FTStatus {
        switch self {
        case .FT: return .FID
        case .FID: return .RES
        case .RES: return .FT
        }
    }
    var legend: String {
        switch self {
        case .FT: return "FT"
        case .FID: return "FID"
        case .RES: return "RES"
        }
    }
}
// Functiom to remove n elemnts from the beginning of an arry
//and fill the last values wih the original last value
func modifyArray(arr: [Double], n: Int) -> [Double] {
// Guard clause to ensure n is within bounds
guard n >= 0 && n <= arr.count else {
    print("Invalid value of n")
    return arr
}

// Check if the array is empty or n is 0
if arr.isEmpty || n == 0 {
    return arr
}

// Store the last element of the original array
let lastElement = arr.last!

// Remove the first n elements
var modifiedArr = Array(arr.dropFirst(n))

// Calculate the number of times to append the last element
let elementsToAppend = arr.count - modifiedArr.count

// Append the last element enough times to maintain the original length
for _ in 0..<elementsToAppend {
    modifiedArr.append(lastElement)
}

return modifiedArr
}
// Make T1 array T1 Guess and no of points
func generateArray(_ T1: Double, _ n: Int)->[Double] {
    let exp_max = 5.1
    let exp_min = 0.0
    let no_Expts = n
    let stepSize = (exp_max - exp_min) / Double(no_Expts - 1)
    var array: [Double] = []
    for i in 0..<no_Expts {
        var value = exp_min + stepSize * Double(i % no_Expts)
        value = exp(value)/exp(exp_max);
        value = ceil(value*1000*T1*9/201)
        array.append(value)
    }
    return(array)
}

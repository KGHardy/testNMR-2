//
//  File.swift
//  testNMR
//
//  Created by Terence Cosgrove on 11/5/23.
//

import Foundation
func myFilter(_ spectrumMode:String,_ ndata:Int, _ frequencyIN:Double,_ samplingTimeIN:Double,_ cutOFF:Double,_ windowIn:Double,_ y_filter:[Double])->([Double])
{
    //let frequency = frequencyIN*2*3.1416
    let ts = samplingTimeIN
    let wf = windowIn
    var np = y_filter.count
    //convolute
    var y_real:[Double] = convolute(spectrumMode,np,ts,wf,y_filter)
    // filter
    y_real = Butterworth(y_real, ts, cutOFF)
    
    return(y_real)
}
    func Butterworth(_ indata:[Double], _ deltaTimeinsec:Double, _ CutOff:Double)-> [Double]
    {
        let Samplingrate:Double = 1.0/deltaTimeinsec
        let dF2:Int = indata.count - 1; // The data range is set with

        // Array with 4 extra points front and back double[] data = indata;
        var Dat2:[Double] = Array(repeating: Double(0.0), count: (dF2 + 4))
        var data:[Double] = indata
        // Ptr., changes passed data
        for r in 0..<dF2 {
            Dat2[2 + r] = indata[r]
        }
        Dat2[1]  = indata[0]
        Dat2[0] = indata[0]
        Dat2[dF2 + 3] = indata[dF2]
        Dat2[dF2 + 2] = indata[dF2]

        let pi:Double = 3.14159265358979
        let wc:Double = tan(CutOff * pi / Samplingrate)
        let k1:Double = 1.414213562 * wc; // Sqrt(2) * wc
        let k2:Double = wc * wc;
        let a:Double = k2 / (1 + k1 + k2);
        let b:Double = 2 * a;
        let c:Double = a;
        let k3:Double = b / k2;
        let d:Double = -2 * a + k3;
        let e:Double = 1 - (2 * a) - k3;
        // RECURSIVE TRIGGERS - ENABLE filter is performed (first, last points constant)
        var DatYt:[Double] = Array(repeating: Double(0.0), count: (dF2 + 4))
        DatYt[1] = indata[0]
        DatYt[0] = indata[0]
        for  s in  2..<(dF2 + 2) {
            DatYt[s] = a * Dat2[s] + b * Dat2[s - 1] + c * Dat2[s - 2]  + d * DatYt[s - 1] + e * DatYt[s - 2]
        }
        DatYt[dF2 + 3] = DatYt[dF2 + 1];
        DatYt[dF2 + 2] = DatYt[dF2 + 1];
       // print("IN data",data)
        // FORWARD filter
        var DatZt:[Double] = Array(repeating: Double(0.0), count: (dF2 + 2))
        DatZt[dF2] = DatYt[dF2 + 2]
        DatZt[dF2 + 1] = DatYt[dF2 + 3]
        for t in (-dF2 + 1)..<0{
            DatZt[-t] = a * DatYt[-t + 2] + b * DatYt[-t + 3] + c * DatYt[-t + 4] + d * DatZt[-t + 1] + e * DatZt[-t + 2];
        }
        // Calculated points are written
        for p in 0..<dF2{
            data[p] = DatZt[p]
        }
        //let _ = print("Filtered DATA",data)
        return(data)
    }
func convolute(_ mode:String,_ n:Int,_ ts:Double,_ wf:Double,_ yinput:[Double])->([Double]){

 var t:[Double] = Array(repeating: Double(0.0), count: n)
 var x:[Double] = Array(repeating: Double(0.0), count: n)
 var y:[Double] = Array(repeating: Double(0.0), count: n)
 var  j = 0
 var temp = 0.0
    var np = x.count
 for i in -np/2..<np/2
    {
      t[j] = Double(i)*ts
      x[j] = Double(i+np/2+1)*ts
    j = j + 1
    }
 for i in 0..<np
    {
     if(mode == "SPIN_ECHO"){
         temp = pow((t[i]), 2.0)}
     if(mode == "FID"){
         temp = pow((x[i]), 2.0)}
    y[i] = yinput[i]*exp(-temp/(pow(wf*1e-6,2)))
     }
return(y)
 }

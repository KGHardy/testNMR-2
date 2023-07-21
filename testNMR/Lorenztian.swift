//
//  Lorenztian.swift
//  DrawASquare
//
//  Created by Terence Cosgrove on 29/11/2022.
//

import Foundation
func lorentzian(_ params:[Double],_ x:[Double]) ->[Double]{
    /* Calculate Lorentzian Line
     :param params: parameters for line equation y = mx + b ([m, b])
     :param x: input values
     :return: a vector containing the output of the line equation with noise
     */
    //var mu:Double = 0.0
   // var sigma:Double = 5.0
    let a:Double=params[0]
    let b:Double=params[1]
    let c:Double=params[2]
    let dataLength=x.count
    var y:[Double] = Array(repeating: (0.0), count: dataLength)
    for i in 0..<dataLength{
        y[i] = a*pow(b,2.0)/(pow((x[i]-c),2)+pow(b,2))+a*x[i]/(pow((x[i]-c),2)+pow(b,2))
        y[i] = pow(y[i],0.5)
    }
    
    return y
}

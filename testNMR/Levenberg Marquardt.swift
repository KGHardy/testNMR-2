//
//  TEstLM.swift
//  ffttest
//
//  Created by Terence Cosgrove on 03/10/2022.
//  Copyright © 2022 Christopher Helf. All rights reserved.
//

import Foundation
//
//  Levenberg Marquardt.swift
//  Complex_FFT
//
//  Created by Terence Cosgrove on 20/09/2022.
//

import Foundation
import Accelerate

func determinantOfMatrix( _ mat:[[Double]]) -> (Double)
{
    var ans:Double
    ans = (mat[0][0] * (mat[1][1] * mat[2][2] -
                            mat[2][1] * mat[1][2]) -
            mat[0][1] * (mat[1][0] * mat[2][2] -
                            mat[1][2] * mat[2][0]) +
            mat[0][2] * (mat[1][0] * mat[2][1] -
                            mat[1][1] * mat[2][0]))
    //print(mat)
    //print ("ans ",ans)
    
    return ans
}
// This function finds the solution of system of
// linear equations using cramer's rule
func findSolution(_ newJtJ:[[Double]],_ Jerror:[Double]) -> [Double]
{
    let coeff = newJtJ
    let coeffJ = Jerror
    
    // Matrix d using coeff as given in
    // cramer's rule
    let d = [[coeff[0][0], coeff[0][1], coeff[0][2]],
             [coeff[1][0], coeff[1][1], coeff[1][2]],
             [coeff[2][0], coeff[2][1], coeff[2][2]]]
    
    // Matrix d1 using coeff as given in
    //cramer's rule
    let d1 = [[coeffJ[0], coeff[0][1], coeff[0][2]],
              [coeffJ[1], coeff[1][1], coeff[1][2]],
              [coeffJ[2], coeff[2][1], coeff[2][2]]]
    
    // Matrix d2 using coeff as given in
    // cramer's rule
    let d2 = [[coeff[0][0], coeffJ[0], coeff[0][2]],
              [coeff[1][0], coeffJ[1], coeff[1][2]],
              [coeff[2][0], coeffJ[2], coeff[2][2]]]
    
    // Matrix d3 using coeff as given in
    // cramer's rule
    let d3 = [[coeff[0][0], coeff[0][1], coeffJ[0]],
              [coeff[1][0], coeff[1][1], coeffJ[1]],
              [coeff[2][0], coeff[2][1], coeffJ[2]]]
    
    // Calculating Determinant of Matrices
    // d, d1, d2, d3
    let D:Double = determinantOfMatrix(d)
    let D1:Double = determinantOfMatrix(d1)
    let D2:Double = determinantOfMatrix(d2)
    let D3 = determinantOfMatrix(d3)
    var x: Double = 0.0
    var y: Double = 0.0
    var z: Double = 0.0
    
    //print("D is : ", D)
    //print("D1 is : ", D1)
    //print("D2 is : ", D2)
    //print("D3 is : ", D3)
    
    // Case 1
    if (D != 0.0){
        
        //Coeff have a unique solution.
        //Apply Cramer's Rule
        x = D1 / D
        y = D2 / D
        // calculating z using cramer's rule
        z = D3 / D
    }
    //Case 2
    else {
        if (D1 == 0.0 && D2 == 0.0 &&
                D3 == 0.0){
            print("Infinite solutions")}
        else if (D1 != 0 || D2 != 0 ||
                    D3 != 0) {
            print("No solutions")}
        
    }
    let J:[Double] = [x,y,z]
    return (J)
}
//  Levenberg Routines https://github.com/jjhartmann/Levenberg-Marquardt-Algorithm
func line_error(_ params:[Double],_ args:[[Double]])-> ([Double])
{
    /*
     Line Error, calculates the error for the line equations y = mx + b
     :param params: values to be used in model
     :param x: inputs
     :param y: observations
     :return: difference between observations and estimates
     */
    //let a:Double = params[0]
    //let b:Double = params[1]
    //let c:Double = params[2]
    let x:[Double] = args[0]
    let y:[Double] = args[1]
    let dataLength = x.count
    var ystar:[Double] = Array(repeating: Double(0.0), count: dataLength)
    ystar = lorentzian(params,x)
    for i in 0..<dataLength{
    ystar[i]=y[i]-ystar[i]
}
    return (ystar)
}

/*""" Numerical Differentiation
 Note: we are passing in the effor function for the model we are using, but
 we can substitute the error for the actual model function
 error(x + delta) - error(x) <==> f(x + delta) - f(x)
 :param params: values to be used in model
 :param args: input (x) and observations (y)
 :param error_function: function used to determine error based on params and observations
 :return: The jacobian for the error_function
 def numerical_differentiation(params, args, error_function):
 */
func numerical_differentiation(_ params:[Double],_ args:[[Double]]) -> ([[Double]])
{
    let delta_factor:Double = 1.0e-4
    let min_delta:Double = 1.0e-4
    let paramsIn = params
    let x:[Double] = args[0]
    //var y:[Double] = args[1]
    let dataLength = x.count
    let parsCount = params.count
    let rows = params.count
    let cols = x.count
    //Compute error
    let y_0:[Double] = line_error(params, args)
    // Jacobian [[100][100][100]] count(1) No of observationscount(2) is number of variables
    //Empty Jacobian define
    var J:[[Double]] = Array(repeating: Array(repeating: (0.0), count: cols), count: rows)
    // for each  parameter i
    for  i in 0..<parsCount {
        var params_star:[Double] = paramsIn //copy input parameters
        var delta:Double = params_star[i]*delta_factor //delta for each parameter
        //Update single param and calculate error with updated value
        if( abs(delta) < min_delta) {
            delta=min_delta
        }
        params_star[i] += delta
        // Call line_error(_ params:[Double],_ args:[Double])-
        let y_1:[Double] = line_error(params_star, args)
        // Update Jacobian with gradient
        for j in 0..<dataLength{
            let diff:Double = y_0[j] - y_1[j]
            J[i][j] = diff/delta
        }
    }
    return J
}
/*""" Symbolic Differentiation for Line Equation
 Note: we are passing in the effor function for the model we are using, but
 we can substitute the error for the actual model function
 error(x + delta) - error(x) <==> f(x + delta) - f(x)
 :param params: values to be used in model
 :param args: input (x) and observations (y)
 :return: The jacobian for the error_function
 F = @(x,xdata)(x(1)^2./(x(2)^2+4*((x(3)-xdata).^2)).^0.5);
 a*b**2/(b**2+(x-c)**2)
 */
func line_differentiation(_ params:[Double],_ args:[[Double]])-> ([[Double]])
{
    let a = params[0]
    let b = params[1]
    let c = params[2]
    let x:[Double] = args[0]
    //var y:[Double] = args[1]
    let rows = params.count //parameters
    let cols = x.count  //data
    //Jacobian
    var J:[[Double]] = Array(repeating: Array(repeating: (0.0), count: cols), count: rows)
    for i in 0..<cols{
        let f:Double = pow(b,2) + pow((c-x[i]),2)
        J[0][i] = a*pow(b,2)/f  // d/da = x
        J[1][i] = f*2*b*a/pow(f,2)-pow(a,2)*b*2*b/pow(f,2) // d/db = 1
        J[2][i] = -pow(a,2)*b*(2.0*c-2*x[i])/pow(f,2) //d/dc
    }
    return J
}
func lm(_ seed_params:[Double],_ args:[[Double]]) -> ([Double],[Double])
{     //(Double,[Double],String)
    //  error_function, jacobian_function=numerical_differentiation,
    //  llambda=1e-3, lambda_multiplier=10, kmax=50, eps=1e-3, verbose=True):
    /*""" Levenberg-Marquardt Implementaiton
     //See: (https://en.wikipedia.org/wiki/Levenberg%E2%80%93Marquardt_algorithm)
     :param  seed_params: initial starting guess for the params we are trying to find
     :param  args: the inputs (x) and observations (y)
     :param  error_function: describes how error is calculated for the model
     function args (params, x, y)
     :param  jacobian_function: produces and returns the jacobian for model
     function args (params, args, error_function)
     :param  llambda: initial dampening factor
     :param  lambda_multiplier: scale used to increase/decrease lambda
     :param  kmax: max number of iterations
     :return:  rmserror, params
     """
     */
    var llambda:Double = 1e-3
    let lambda_multiplier:Double = 10
    let  kmax:Int = 50
    let  eps:Double  = 1e-3
    let  verbose:Bool = true
    // Equality : (JtJ + lambda * I * diag(JtJ)) * delta = Jt * error
    //Solve for delta
    var params = seed_params
    var error:[Double] = [0,0,0] //FIXME
    var k:Int = 0
    while (k < kmax)
    {
        k += 1
        //print("Iteration ",k)
        // Retrieve jacobian of function gradients with respect to the params
        let J:[[Double]] = numerical_differentiation(params, args)
        let JtJ:[[Double]] = inner(J, J)
        let Count = params.count
        // I * diag(JtJ)
        let Atest:[[Double]] = eye(params.count)
        let Adiag:[Double] = diag(JtJ)
        var A:[[Double]] = Array(repeating: Array(repeating: (0.0), count: Count), count: Count)
        for i in 0..<Count{
            A[i][i] = Atest[i][i] * Adiag[i]
        }
        //var A:[[Double]] = eye(params.count) * diag(JtJ)
        
        //== Jt * error
        let error:[Double] = line_error(params, args)
        let Jerror:[Double] = innerx(J, error)
        let rmserror:Double = norm(error)
        
        if verbose{
           // print(" RMS: ",rmserror," Params", params)
        }
        if (rmserror < eps){
            print("Converged to min epsilon")
            return(params,Jerror)
        }
        //var reason = ""
        //var error_star:[Double]  = error
        var rmserror_star:Double = rmserror + 1
        //New solution using Cramer;'s metho
        //findSolution(coeff)
        while (rmserror_star >= rmserror){
            //try
            let newA:[[Double]] = mx(A, llambda)
            let newJtJ:[[Double]] = madd(JtJ,newA)
            let delta:[Double] = findSolution(newJtJ, Jerror)
            //   except np.linalg.LinAlgError:
              // print("Error: Singular Matrix")
            //return -1
            //Update params and calculate new error
            let params_star :[Double] = vadd(params,delta)
            let error_star :[Double] = line_error(params_star, args)
            rmserror_star = norm(error_star)
            
            if rmserror_star < rmserror{
                params = params_star
                llambda /= lambda_multiplier
               // print("Stopped at Iteration",k,rmserror_star,"<",rmserror)
                
                break
            }
            llambda *= lambda_multiplier
            
            // Return if lambda explodes or if change is small
            if (llambda > 1e9){
                //reason = "Lambda too large."
                //return (rmserror, params, reason)
                print("Lambda too large")
                return(params,Jerror)
               
            }
        }
        let reduction:Double = abs(rmserror - rmserror_star)
        if (reduction < 1e-18){
            // reason = "Change in error too small"
            // return rmserror, params, reason
            print("Change in error too small")
            
        }
        // return (rmserror, params, "Finished kmax iterations")
    }
    return(params,error) //FIXME need diagonal elements of J
}
//Matrix Routines *************************************************************
// Emulate numpy inner function
func inner(_ A:[[Double]],_ B:[[Double]]) ->[[Double]]{
    let rowsA:Int = A.count
    //print("Rows a",rowsA)
    //let colsA:Int = A[1].count
    //print("Cols a",colsA)
    //let rowsB:Int = B.count
    let colsB:Int = B[1].count
    // Section 2: Store matrix multiplication in a new matrix resut  should be     2 x 2
    var arr:[[Double]] = Array(repeating: Array(repeating: (0.0), count: rowsA), count: rowsA)
    //print(arr)
    for i in 0..<rowsA{
        for k in 0..<rowsA{
            var total:Double = 0.0
            for j in 0..<colsB{
                total += A[i][j] * B[k][j]
                //print(i,j)
                
            }
            arr[i][k] = total
        }
    }
    
    return (arr)
}

// Emulate numpy inner function for [3x3][1x3]
func innerx(_ A:[[Double]],_ B:[Double]) ->[Double]{
    //let rowsA:Int = A[0].count
    let colsA:Int = A.count
    let rowsB:Int = B.count
    // Section 2: Store matrix multiplication in a new matrix
    //print("innerx \n",rowsA,colsA,rowsB)
    var arr:[Double] = Array(repeating: (0.0), count: colsA)
    for i in 0..<colsA{
        var total:Double = 0.0
        for j in 0..<rowsB{
            total += A[i][j] * B[j]
            //print("i and j",i,j)
        }
        arr[i] = total
        //print(arr[i],i)
    }
    return (arr)
}

// Make a zero matrix with 1's on the diagonal
func eye(_ count:Int)->[[Double]]{
    let Count :Int = count
    var my_matrix:[[Double]] = Array(repeating: Array(repeating: (0.0), count: Count), count: Count)
    // Make diagonal 1's
    for i in 0..<count{
        my_matrix[i][i] = 1.0
    }
    return(my_matrix)
}
// get diagonal
func diag(_ in_Matrix:[[Double]])->[Double]{
    let count = in_Matrix[0].count
    var my_diag:[Double] = Array(repeating: (0.0), count: count)
    for i in 0..<count{
        my_diag[i]=in_Matrix[i][i]
    }
    return (my_diag)
}

// Get matrix x factor
func mx(_ A:[[Double]],_ factor:(Double)) ->([[Double]]){
    let Count:Int = A.count //assume square
    var Ax:[[Double]] = Array(repeating: Array(repeating: (0.0), count: Count), count: Count)
    for i in 0..<Count{
        Ax[i] = A[i].map{$0*factor}
    }
    return(Ax)
}


// Add matrix x factor
func madd(_ A:[[Double]],_ B:[[Double]]) ->([[Double]]){
    let Count:Int = A.count //assume square
    var Asum:[[Double]] = Array(repeating: Array(repeating: (0.0), count: Count), count: Count)
    for i in 0..<Count{
        for j in 0..<Count{
            Asum[i][j] = A[i][j]+B[i][j]
        }
    }
    return(Asum)
}
//Add vector
func vadd(_ A:[Double],_ B:[Double]) ->[Double]{
    let Count:Int = A.count
    var sum:[Double] = Array(repeating: Double(0.0), count: A.count)
    for i in 0..<Count{
        sum[i] = A[i] + B[i]
    }
    return(sum)
}
// Get norm of vectore
func norm(_ A:[Double]) ->(Double){
    let rows:Int = A.count
    var sum:Double=0.0
    for i in 0..<rows{
        sum = sum + A[i]*A[i]
    }
    return(pow(sum,0.5))
}

func linearFit(_ x:[Double],_ y:[Double]) -> ([Double],[Double]){

    let sum1 = average(multiply(y, x)) - average(x) * average(y)
    let sum2 = average(multiply(x, x)) - pow(average(x), 2)
    let slope = sum1 / sum2
    let intercept = average(y) - slope * average(x)
// calculate fit
    let n = 20
    var yFit:[Double] = Array(repeating: Double(0.0), count: n)
    var xFit:[Double] = Array(repeating: Double(0.0), count: n)
    let minX = x.min()!
    let maxX = x.max()!
    let xStep =  (maxX-minX)/Double(n-1)
    for i in 0..<n{
        xFit[i] = minX+xStep*Double(i)
        yFit[i] = slope*xFit[i]+intercept
    }
    
    return(xFit,yFit)
}
func average(_ input: [Double]) -> Double {
    return input.reduce(0, +) / Double(input.count)
}
func multiply(_ a: [Double], _ b: [Double]) -> [Double] {
    return zip(a,b).map(*)
}
   


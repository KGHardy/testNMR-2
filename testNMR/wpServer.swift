//
//  wpServer.swift
//  CutDown
//
//  Created by Ken Hardy on 05/08/2022.
//

import Foundation

var redPitayaIp = "10.42.0.1"

let BLKS = 512
let BUFSIZE = 4096

let PARAMETERS_VERSION = "1.0.0"

struct NewParameters: Codable {
    var hostName: String?           // 0
    var portNo: Int?                // 1
    var ncoFreq: Int?               // 2
    var pulseLength: Int?           // 3
    var pulseStep: Int?             // 4 superceded
    var littleDelta: Int?           // 5
    var bigDelta: Int?              // 6
    //var noScans: Int?               // 6 superceded
    var gradient: Int?              // 7
    //var noExpts: Int?               // 7 superceded
    var rptTime: Int?               // 8
    var tauTime: Int?               // 9
    var tauInc: Int?                // 10
    var noData: Int?                // 11
    var exptSelect: String?         // 12
    var delayInSeconds: Double?     // 13
    var tauD: Int?                  // 14
    var progSatDelay: [Int]?        // 15
    var userTag: String?
    var version: String?
    
    // remaining items are not used here. Provided for use in the client app
    //  they are here so they will be saved with the other items
    
    var spectrumMode: String?
    var t1Guess: Int?
    var t2Guess: Int?
    var tauStep: Int?
    var noOfDataPoints: Int?
    var samplingTime: Double?
    var filterFrequency: Int?
    var windowTime: Int?
    
    mutating func defaults() -> Void {
        if PARAMETERS_VERSION == "1.0.0" {
            if hostName == nil { hostName = redPitayaIp }
            if portNo == nil { portNo = 1001 }
            if ncoFreq == nil { ncoFreq = 12404629 }
            if pulseLength == nil { pulseLength = 5000 }
            if pulseStep == nil { pulseStep = 0}
            if littleDelta == nil { littleDelta = 0 }
            if bigDelta == nil { bigDelta = 0 }
            //if noScans == nil { noScans = 1 }
            if gradient == nil { gradient = 0 }
            //if noExpts == nil { noExpts = 1 }
            if rptTime == nil { rptTime = 1000 }
            if tauTime == nil { tauTime = 0 }
            if tauInc == nil { tauInc = 0 }
            if noData == nil { noData = 5000 }
            if exptSelect == nil { exptSelect = "FID" }
            if delayInSeconds == nil { delayInSeconds = 1.0 }
            if tauD == nil { tauD = 0 }
            if progSatDelay == nil { progSatDelay = [-1]}
            if userTag == nil {userTag = "" }
            version = "1.0.0"
            if spectrumMode == nil { spectrumMode = "FID"}
            if t1Guess == nil { t1Guess = 100 }
            if t2Guess == nil { t2Guess = 100 }
            if tauStep == nil { tauStep = 0 }
            if noOfDataPoints == nil { noOfDataPoints = 5000 }
            if samplingTime == nil { samplingTime = 1e-6 }
            if filterFrequency == nil { filterFrequency = 200000 }
            if windowTime == nil { windowTime = 1000 }
        }
    }
    enum CodingKeys: String, CodingKey {
        case hostName = "hostname"
        case portNo = "portno"
        case ncoFreq = "ncofreq"
        case pulseLength = "pulselength"
        case pulseStep = "pulsestep"
        case littleDelta = "littledelta"
        case bigDelta = "bigdelta"
        //case noScans = "noscans"
        case gradient = "gradient"
        //case noExpts = "noexpts"
        case rptTime = "rpttime"
        case tauTime = "tautime"
        case tauInc = "tauinc"
        case noData = "nodata"
        case exptSelect = "exptselect"
        case delayInSeconds = "delayinseconds"
        case tauD = "taud"
        case progSatDelay = "progsatdelay"
        case userTag = "usertag"
        case version = "version"
        case spectrumMode = "spectrummode"
        case t1Guess = "t1guess"
        case t2Guess = "t2guess"
        case tauStep = "taustep"
        case noOfDataPoints = "noofdatapoints"
        case samplingTime = "samplingtime"
        case filterFrequency = "filterfrequency"
        case windowTime = "windowtime"
    }
}

struct NewResult: Codable {
    var params: NewParameters?
    var datapoints: [[Int16]]
    
    func count() -> Int {
        var c = 0
        for a in datapoints {
            c += a.count
        }
        return c
    }
}

class NMRServer: NSObject {

// Following are hardware control lines
    let PA_OFF = 0
    let PA_ON = 2
    let BL_OFF = 0
    let BL_ON = 4

// Following forces TX to be 0
    let RF_OFF = 0
    let ADC_STOP = 1
    let ADC_START = 0
    let DC = 4

//  Line  D03 Hardware Pin 5 for field gradients
    let GA_OFF = 0
    let GA_ON = 8
    let GA_CTRL = 0x8000
    let G_OFF = 0
    
    let int32Size = 4
    let int16Size = 2
    
    //var nmrResult = NMRResult(parameters: nil, datapoints: [])
    
    var newResult = NewResult(params: nil, datapoints: [])
    
    //var parametersString : String!
    
    //var retData: [[Int16]
    var retResult = true
    var retError = ""
    var cancelled = false
    
    let rcvSemaphore = DispatchSemaphore(value: 0) // semaphore to signal (rcvr) has finished
    var rcvSCount = 0
    
    let xmtSemaphore = DispatchSemaphore(value: 0) // semaphore to signal (trnr) has finished
    var xmtSCount = 0
    
    func waitRcv() -> Void {
        rcvSCount -= 1
        rcvSemaphore.wait()
    }
    
    func signalRcv() -> Void {
        rcvSCount += 1
        rcvSemaphore.signal()
    }
        
    func waitXmt() -> Void {
        xmtSCount -= 1
        xmtSemaphore.wait()
    }
        
    func signalXmt() -> Void {
        xmtSCount += 1
        xmtSemaphore.signal()
    }
    
    var xmtSocket : TcpSocket? = nil
    var rcvSocket : TcpSocket? = nil

    func convertData(input: [UInt32],swap: Bool = false) -> Data {
        if swap {
            var sinput: [UInt32] = []
            for v in input {
                sinput.append(CFSwapInt32HostToBig(v))
            }
            let data = Data(bytes:sinput,count:sinput.count * int32Size)
            return data
        } else {
            let data = Data(bytes:input,count:input.count * int32Size)
            return data
        }
    }
    
    func convertData(input: [UInt16], swap: Bool = false) -> Data {
        if swap {
            var sinput: [UInt16] = []
            for v in input {
                sinput.append(CFSwapInt16HostToBig(v))
            }
            let data = Data(bytes:sinput,count:sinput.count * int16Size)
            return data
        } else {
            let data = Data(bytes:input,count:input.count * int16Size)
            return data
        }
    }
    
    func convertData(input: [Int16], swap: Bool = false) -> Data {
        if swap {
            var sinput: [UInt16] = []
            for v in input {
                sinput.append(CFSwapInt16HostToBig(UInt16(v)))
            }
            let data = Data(bytes:sinput,count:sinput.count * int16Size)
            return data
        } else {
            let data = Data(bytes:input,count:input.count * int16Size)
            return data
        }
    }

    func cancel() -> Void {
        cancelled = true
        if xmtSocket != nil {
            xmtSocket!.stop()
        }
        if rcvSocket != nil {
            rcvSocket!.stop()
        }
        
        while rcvSCount < 0 {
            signalRcv()
        }
        while xmtSCount < 0 {
            signalXmt()
        }
        retError = "Cancelled by User"
        retResult = false
    }
    
    func RPInterface(params: NewParameters) -> Bool {
        var p = params
        
        var retval = true
        var trnrFailed = false
        
        var rcvIx = 0
        
        retResult = true
        retError = ""
        cancelled = false

        var bufTrnr = [UInt32](repeating:0,count: BLKS + 1)
        var bufDelay = [UInt32](repeating:0,count: BLKS + 1)
        var bufCPMG = [UInt32](repeating:0,count: BLKS + 1)
        //var tauSteps = [UInt32](repeating:0,count: 13)          // never used?

        p.defaults()
        
        let hostName = p.hostName!               // 0
        let portNo = p.portNo!                   // 1
        let ncoFreq = p.ncoFreq!                 // 2
        let pulseLength = p.pulseLength!         // 3
        //var pulseStep = 0                        // 4
        let littleDelta = p.littleDelta!         // 5   in micros
        let bigDelta = p.bigDelta! * 1000        // 6   in ms
        //let noScans: Int = 1
        let gradient = p.gradient!               // 7
        //let noExpts:Int  = 1
        var rptTime = p.rptTime!                 // 8
        rptTime *= 1000
        var tauTime = p.tauTime!                 // 9
        var t1Guess = tauTime
        if t1Guess > 2000 { t1Guess = 2000 }
        if tauTime < 25 && tauTime > 0 { tauTime = 50 }
        var tau = tauTime
        let tauInc = p.tauInc!                   // 10
        let noData = p.noData!                   // 11
        let exptSelect = p.exptSelect!           // 12
        var noEchoes: Int = 0
        if ["CPMG", "CPMGX", "CPMXY"].contains(exptSelect) {noEchoes = tauInc }
        let delayInSeconds = p.delayInSeconds!   // 13
        var tauD = p.tauD!                       // 14
        if tauD > 100000 { tauD = 100000 }
        var progSatDelay = p.progSatDelay!       //15
        
        // Other variables
        
        var delayM: Int = 0
        var iii: Int = 0
        var jjj: Int = 0
        var scanCounter: Int = 0
        var noFrames: Int = 1
        
        var sendStep = 0
        //var nextStep = 0
        
        if !progSatDelay.contains(-1) { progSatDelay.append(-1) }
        
        func updateBuf2(_ scanCounter: Int) -> Void {
            var noInstructions: Int = 0
            
            var ii: Int
            var pl = pulseLength / 8 // now in 8ns units
            if pl > 3000 { pl = 3000 }
            if pl == 0 { pl = 750 } // 6 microseconds

            var d = Double(ncoFreq)
            d = d / 125.0e6
            d = d * 256.0 * 256.0 * 256.0 * 256.0
            d = d + 0.5
            bufTrnr[0] = UInt32(floor(d))
            bufDelay[0] = bufTrnr[0]
            bufCPMG[0] = bufTrnr[0]
            
            var reVal = [Int](repeating:0,count: BLKS / 2) // Was Int16
            var imVal = [Int](repeating:0,count: BLKS / 2) // Was Int16
            var duration = [Int](repeating:0,count: BLKS / 2) // Was UInt32
            var hwCtrl = [Int](repeating:0,count: BLKS / 2) // Was UInt8

            var reValC = [Int](repeating:0,count: BLKS / 2) // Was Int16
            var imValC = [Int](repeating:0,count: BLKS / 2) // Was Int16
            var durationC = [Int](repeating:0,count: BLKS / 2) // Was UInt32
            var hwCtrlC = [Int](repeating:0,count: BLKS / 2)  // Was UInt8

            //let cntr = 0              // never used
            
            let rw = rptTime / 100000
            ii = 0
            while ii < (BLKS / 2 ) {
                bufDelay[2 * ii + 1] = UInt32(((PA_OFF | ADC_STOP) & 0xFF) << 24 | ((125 * 390 * rw - DC) & 0xffffff))
                bufDelay[2 * ii + 2] = UInt32((RF_OFF & 0xffff) | ((RF_OFF & 0xffff) << 16 ))
                ii += 1
            }
            
            func experimentFID() -> Void {
                noInstructions = 15
                hwCtrl[ 0] = PA_OFF | BL_OFF | ADC_STOP;  duration[ 0] = 125 * 1  - DC; reVal[ 0] = RF_OFF
                hwCtrl[ 1] = PA_OFF | BL_OFF | ADC_STOP;  duration[ 1] = 125 * 1  - DC; reVal[ 1] = RF_OFF
                hwCtrl[ 2] = PA_OFF | BL_OFF | ADC_STOP;  duration[ 2] = 125 * 1  - DC; reVal[ 2] = RF_OFF
                hwCtrl[ 3] = PA_OFF | BL_OFF | ADC_STOP;  duration[ 3] = 125 * 1  - DC; reVal[ 3] = RF_OFF
                hwCtrl[ 4] = PA_OFF | BL_OFF | ADC_STOP;  duration[ 4] = 125 * 1  - DC; reVal[ 4] = RF_OFF
                hwCtrl[ 5] = PA_ON  | BL_OFF | ADC_STOP;  duration[ 5] = 125 * 10 - DC; reVal[ 5] = RF_OFF
                hwCtrl[ 6] = PA_ON  | BL_OFF | ADC_STOP;  duration[ 6] = pl       - DC; reVal[ 6] = 8100
                hwCtrl[ 7] = PA_OFF | BL_OFF | ADC_STOP;  duration[ 7] = 125 * 5  - DC; reVal[ 7] = RF_OFF
                hwCtrl[ 8] = PA_OFF | BL_ON  | ADC_START; duration[ 8] = 125 * noData
                                                                                  - DC; reVal[ 8] = RF_OFF
                hwCtrl[ 9] = PA_OFF | BL_OFF | ADC_STOP;  duration[ 9] = 125 * 1  - DC; reVal[ 9] = RF_OFF
                hwCtrl[10] = PA_OFF | BL_OFF | ADC_STOP;  duration[10] = 125 * 1  - DC; reVal[10] = RF_OFF
                hwCtrl[11] = PA_OFF | BL_OFF | ADC_STOP;  duration[11] = 125 * 1  - DC; reVal[11] = RF_OFF
                hwCtrl[12] = PA_OFF | BL_OFF | ADC_STOP;  duration[12] = 125 * 1  - DC; reVal[12] = RF_OFF
                hwCtrl[13] = PA_OFF | BL_OFF | ADC_STOP;  duration[13] = 125 * 1  - DC; reVal[13] = RF_OFF
                hwCtrl[14] = PA_OFF | BL_OFF | ADC_STOP;  duration[14] = 125 * 1  - DC; reVal[14] = RF_OFF
            }
            
            func experimentCPMG() -> Void {
                noInstructions=noEchoes*3+4
                let oneL = noInstructions-1
                    /* fill array with 4 pulse sequence capture 50us of data 180 degree pulses*/
                    /* no_Instructions =243;  gives 80 echoes to start with. Min tau 50 us. Echo sapcing 100us; CP to begin with*/
                    
                    
                hwCtrl[0]  = PA_ON  | BL_OFF | ADC_STOP; duration[0] = 125 * 10 - DC;              reVal[0]=RF_OFF;     /* wait 10  PA to come on*/
                hwCtrl[1]  = PA_ON  | BL_OFF | ADC_STOP; duration[1] = pl - DC;                    reVal[1]=8100;       /* TX=8100 180 pulse us*/
                hwCtrl[2]  = PA_OFF | BL_OFF | ADC_STOP; duration[2] = 125 * (tau - 10) - pl - DC; reVal[2]=RF_OFF;    /*  tau delay 1 ms corr 10 us s/on*/
                    
                    /*TAU LOOP 80 echoes  240 steps echoes spacing 2 tau*/
                
                ii = 0
                while (ii + 3) < noInstructions {
                    ii += 3
                    hwCtrl[ii]   = PA_ON  | BL_OFF | ADC_STOP;  duration[ii]   = 125 * 10 - DC;                         reVal[ii]=RF_OFF;     /* wait 10  PA to come on*/
                    hwCtrl[ii+1] = PA_ON  | BL_OFF | ADC_STOP;  duration[ii+1] = pl * 2 - DC;                           reVal[ii+1]=0; imVal[ii+1]=8100;    /* TX=8100 180 90Phase*/
                    hwCtrl[ii+2] = PA_OFF | BL_OFF | ADC_START; duration[ii+2]  = 125 * ( 2 * tau - 10) - pl * 2 - DC;  reVal[ii+2]=RF_OFF;   /*  tau corr 10 us s/on*/
                }
                    /*END LOOP*/
                hwCtrl[oneL]  = PA_ON  | BL_OFF  | ADC_STOP;  duration[oneL]  = 125 * 10 - DC;     reVal[oneL] = RF_OFF;     /* wait 10  PA to come on*/
            }
            
            func experimentCPMGX() -> Void {
                // fill ist buffer with  253 Dummy Delyas 1 us then add 90 pl tau-10 3 Instructions*/
                // Cycle second array each has 64 echoes 4 instrcutions each data length tau-10 us*/
                noInstructions = 256  // Real number*/
                for ii in 0..<255 {
                    hwCtrl[ii]  = PA_OFF | BL_OFF | ADC_STOP
                    duration[ii]  = 125 * 1 - DC;
                    reVal[ii] = RF_OFF;   // Dummy wait 1u*/
                }
                // Start of CPMG sequence Make timing adjustments to dealys as JMR v 148 p 372 2001*/
                
                hwCtrl[252]  = PA_ON  | BL_OFF   | ADC_STOP
                duration[252]  = 125 * 10 - DC
                reVal[252] = RF_OFF   // wait 10  PA to come on*/
                hwCtrl[253]  = PA_ON  | BL_OFF   | ADC_STOP
                duration[253]  = pl - DC
                reVal[253] = 8100     // TX=8100 90 pulse us */
                hwCtrl[254]  = PA_OFF | BL_OFF   | ADC_STOP
                duration[254]  = 125 * 5 - DC
                reVal[254] = RF_OFF     // TX off wait 5 us */
           /*     hw_ctrl[255]  = PA_OFF | BL_OFF   | ADC_STOP;  duration[255]  = 125*(tau-10)-pl-DC; re_val[255]=RF_OFF;    tau delay 1 ms corr 10 us son */
           /* Add extra delya in first interval as per reference Journal of Magnetic Resonance 148, 367ñ378 (2001) p372 also sub 5us  */
                var ansis: Double
                var plmod : Int
                ansis=Double(pl) / 3.1415
                plmod=Int(ansis)
                hwCtrl[255]  = PA_OFF | BL_OFF   | ADC_STOP
                duration[255]  = 125 * (tau - 10 - 5 ) - 2 * plmod - DC
                reVal[255] = RF_OFF;
                /*int no_Loops;  Fix values
                no_Loops=no_Echoes
                 */
                
                /* FiLL ARRAYS*/
                for ii in stride(from: 0, to: BLKS / 2, by: 8) {
                //for (ii = 0; ii < BLKS/2; ii+=8) {
                    let noData2: Int = tau
                    hwCtrlC[ii]   = PA_ON  | BL_OFF   | ADC_STOP
                    durationC[ii]   = 125 * 10 - DC
                    reValC[ii] = RF_OFF     // wait 10  PA to come on*/
                    hwCtrlC[ii + 1] = PA_ON  | BL_OFF   | ADC_STOP
                    durationC[ii + 1] = pl * 2 - DC
                    reValC[ii + 1] = 0
                    imValC[ii + 1] = 8100 // 180 90Phase*/
                    hwCtrlC[ii + 2]   = PA_OFF  | BL_OFF   | ADC_STOP
                    durationC[ii + 2]   = 125 * 5 - DC
                    reValC[ ii + 2] = RF_OFF     // wait 5  PA to go off*/
                 //    hw_ctrl_C[ii+2] = PA_OFF | BL_OFF   | ADC_STOP;  duration_C[ii+2] = 125*(tau-no_Data2/2)-pl*2-DC;       re_val_C[ii+2]=RF_OFF;     // delay before Echo*/
                    hwCtrlC[ii + 3] = PA_OFF | BL_OFF   | ADC_STOP
                    durationC[ii+3] = 125 * (tau - noData2 / 2 - 5) - pl - DC
                    reValC[ii + 3] = RF_OFF    // delay before Echo*/
                    hwCtrlC[ii + 4] = PA_OFF | BL_ON    | ADC_START
                    durationC[ii + 4] = 125 * noData2 - DC
                    reValC[ii + 4] = RF_OFF   //  collect data for no_Data2 */
                //     hw_ctrl_C[ii+4] = PA_OFF | BL_OFF   | ADC_STOP;  duration_C[ii+4] = 125*(tau-10-no_Data2/2 - 3)-DC;      re_val_C[ii+4]=RF_OFF;   /*  delay after Echo*/
                    hwCtrlC[ii + 5] = PA_OFF | BL_OFF   | ADC_STOP
                    durationC[ii + 5] = 125 * (tau - 10 - noData2 / 2 -  2) - pl - DC
                    reValC[ii + 5] = RF_OFF   //  delay after Echo*/
                    hwCtrlC[ii + 6] = PA_OFF | BL_OFF   | ADC_STOP
                    durationC[ii + 6] = 125 * 1 - DC
                    reValC[ii + 6] = RF_OFF   //  Fill*/
                    hwCtrlC[ii + 7] = PA_OFF | BL_OFF   | ADC_STOP
                    durationC[ii + 7] = 125 * 1 - DC
                    reValC[ii + 7]=RF_OFF   //  Fill*/
                //     hw_ctrl_C[ii+7] = PA_OFF | BL_OFF   | ADC_STOP;  duration_C[ii+7] = 125*1-DC;                          re_val_C[ii+7]=RF_OFF;   /*  Fill*/
                    
                    /*END LOOP*/
                }
                /* FILL CPMG BUFFER*/
                
                for ii in 0..<BLKS / 2 {
                    bufCPMG[2 * ii + 1] = UInt32(((hwCtrlC[ii] & 0xff) << 24) | (durationC[ii] & 0xffffff))
                    bufCPMG[2 * ii + 2] = UInt32((reValC[ii] & 0xffff) | ((imValC[ii] & 0xffff) << 16))
                }
            }
            
            func experimentCPMGY() -> Void {
                /* fill ist buffer with  253 Dummy Delyas 1 us then add 90 pl tau-10 3 Instructions*/
                    /* Cycle second array each has 64 echoes 4 instrcutions each data length tau-10 us*/
                noInstructions = 256;  /* Real number*/
                for ii in 0..<255 {
                    hwCtrl[ii]  = PA_OFF | BL_OFF | ADC_STOP
                    duration[ii]  = 125 * 1 - DC
                    reVal[ii] = RF_OFF   /* Dummy wait 1u*/
                }
                    /* Start of CPMG sequence Make timing adjustments to dealys as JMR v 148 p 372 2001*/
                    
                hwCtrl[252]  = PA_ON  | BL_OFF   | ADC_STOP
                duration[252]  = 125 * 10 - DC
                reVal[252]=RF_OFF   /* wait 10  PA to come on*/
                hwCtrl[253]  = PA_ON  | BL_OFF   | ADC_STOP
                duration[253]  = pl - DC
                reVal[253] = -8100;     /* TX=8100 90 pulse us */
                hwCtrl[254]  = PA_OFF | BL_OFF   | ADC_STOP
                duration[254]  = 125 * 5 - DC
                reVal[254] = RF_OFF     /* TX off wait 5 us */
               /*     hw_ctrl[255]  = PA_OFF | BL_OFF   | ADC_STOP;  duration[255]  = 125*(tau-10)-pl-DC; re_val[255]=RF_OFF;    tau delay 1 ms corr 10 us son*/
               /* Add extra delya in first interval as per reference Journal of Magnetic Resonance 148, 367ñ378 (2001) p372 also sub 5us  */
                var ansis: Double
                var plmod: Int
                ansis = Double(pl) / 3.1415
                plmod = Int(ansis)
                hwCtrl[255]  = PA_OFF | BL_OFF   | ADC_STOP
                duration[255]  = 125 * (tau - 10 - 5) - 2 * plmod - DC
                reVal[255] = RF_OFF
                    /*int no_Loops;  Fix values
                    no_Loops=no_Echoes
                     */
                    
                    /* FiLL ARRAYS*/
                for ii in stride(from: 0, to: BLKS / 2, by: 8) {
                    let noData2 = tau
                    hwCtrlC[ii]   = PA_ON  | BL_OFF   | ADC_STOP
                    durationC[ii]   = 125 * 10 - DC
                    reValC[ii] = RF_OFF     /* wait 10  PA to come on*/
                    hwCtrlC[ii + 1] = PA_ON  | BL_OFF   | ADC_STOP
                    durationC[ii + 1] = pl * 2 - DC
                    reValC[ii + 1] = 0
                    imValC[ii + 1] = 8100 /* 180 90Phase*/
                    hwCtrlC[ii + 2]   = PA_OFF  | BL_OFF   | ADC_STOP
                    durationC[ii + 2]   = 125 * 5 - DC
                    reValC[ii + 2] = RF_OFF     /* wait 5  PA to go off*/
                     //    hw_ctrl_C[ii+2] = PA_OFF | BL_OFF   | ADC_STOP;  duration_C[ii+2] = 125*(tau-no_Data2/2)-pl*2-DC;        re_val_C[ii+2]=RF_OFF;     /* delay before Echo*/
                    hwCtrlC[ii + 3] = PA_OFF | BL_OFF   | ADC_STOP
                    durationC[ii + 3] = 125 * (tau - noData2 / 2 - 5) - pl - DC
                    reValC[ii + 3] = RF_OFF     /* delay before Echo*/
                    hwCtrlC[ii + 4] = PA_OFF | BL_ON    | ADC_START
                    durationC[ii + 4] = 125 * noData2 - DC
                    reValC[ii + 4] = RF_OFF   /*  collect data for no_Data2 */
                    //     hw_ctrl_C[ii+4] = PA_OFF | BL_OFF   | ADC_STOP;  duration_C[ii+4] = 125*(tau-10-no_Data2/2 - 3)-DC;      re_val_C[ii+4]=RF_OFF;   /*  delay after Echo*/
                    hwCtrlC[ii + 5] = PA_OFF | BL_OFF   | ADC_STOP
                    durationC[ii + 5] = 125 * (tau - 10 - noData2 / 2 - 2) - pl - DC
                    reValC[ii + 5] = RF_OFF   /*  delay after Echo*/
                    hwCtrlC[ii + 6] = PA_OFF | BL_OFF   | ADC_STOP
                    durationC[ii + 6] = 125 * 1 - DC
                    reValC[ii + 6] = RF_OFF   /*  Fill*/
                    hwCtrlC[ii + 7] = PA_OFF | BL_OFF   | ADC_STOP
                    durationC[ii + 7] = 125 * 1 - DC
                    reValC[ii + 7] = RF_OFF   /*  Fill*/
                    //     hw_ctrl_C[ii+7] = PA_OFF | BL_OFF   | ADC_STOP;  duration_C[ii+7] = 125*1-DC;                          re_val_C[ii+7]=RF_OFF;   /*  Fill*/
                }
                    /* FILL CPMG BUFFER*/
                    
                for ii in 0..<BLKS/2 {
                        bufCPMG[2 * ii + 1] = UInt32(((hwCtrlC[ii] & 0xff) << 24) | (durationC[ii] & 0xffffff))
                        bufCPMG[2 * ii + 2] = UInt32((reValC[ii] & 0xffff) | ((imValC[ii] & 0xffff) << 16))
                }
            }

            func experimentMATCH() -> Void {
                // Use standard buffer buf_MATCH and repeat this say 20 times each with a new frequecny
                // Frequency (nco_Freq) is stepped in 10 KHZ steps so from 100 KHZ below resosnance to 100 KHZ above set in GUI
                // pulse length (pl)  set in GUI length in us is the same as the no of data points collected
                // Each buffer increments the frequency and has a short say  20 us rf burst during which we collect 20  signal samples
                // Repeat buffer say every 100 ms (or maybe as fast as it will go?
                noInstructions=256;  // Real number
                for ii in 0...253 {
                    hwCtrl[ii]  = PA_OFF | BL_OFF | ADC_STOP; duration[ii]  = 125 * 1 - DC; reVal[ii] = RF_OFF;   // wait 1u
                }
                // Ssequence
                    
                hwCtrl[254]  = PA_ON  | BL_OFF   | ADC_STOP;  duration[253]  = 125 * 10 - DC;  reVal[253] = RF_OFF;  // wait 10  PA to come on
                hwCtrl[255]  = PA_ON  | BL_OFF   | ADC_START; duration[254]  = pl - DC;        reVal[254] = 4000;   // TX=4000 lower power RF pulse
               
                
            }
            
            func experimentT1() -> Void {
                     /* Fix no of steps in delay 49 steps left over*/
                noInstructions = 208;
                    
                hwCtrl[0] = PA_ON | BL_OFF | ADC_STOP; duration[0]  = 125 * 10 - DC; reVal[0] = RF_OFF;     /* wait 10  PA to come on*/
                hwCtrl[1] = PA_ON | BL_OFF | ADC_STOP; duration[1]  = pl * 2 - DC;   reVal[1] = 8100;       /* TX=8100 180 pulse us*/
                    /*TAU LOOP 200 steps+the one above gives min value of 2 ms include 200*tau_Step[0] =5*/
                
                for ii in 2...203 {
                    hwCtrl[ii] = PA_OFF | BL_OFF | ADC_STOP; duration[ii] = 125 * tauD - DC; reVal[ii]=RF_OFF;
                }
                    /*END LOOP*/
                hwCtrl[204] = PA_ON  | BL_OFF | ADC_STOP;  duration[204]  = 125 * 10 - DC; reVal[204] = RF_OFF;     /* wait 10  PA to come on*/
                hwCtrl[205] = PA_ON  | BL_OFF | ADC_STOP;  duration[205]  = pl - DC;       reVal[205] = 8100;       /* TX=8100 180 pulse us*/
                hwCtrl[206] = PA_OFF | BL_ON  | ADC_START; duration[206]  = 125 * noData - DC;
                                                                                           reVal[206] = RF_OFF;    /* wait Signal Aquisition 5 ms*/
                hwCtrl[207] = PA_ON  | BL_OFF | ADC_STOP;  duration[207]  = 125 * 10 - DC; reVal[207] = RF_OFF;     /* wait 10  PA to come on*/
            }

            func experimentSE() -> Void {
                var echoWait: Int
                
                if tau<900 {  /* in us*/
                    echoWait=tau-10
                }
                else {
                    echoWait=900
                }

                noInstructions = 15
                hwCtrl[0]  = PA_OFF | BL_OFF | ADC_STOP;  duration[0]  = 125 * 1 - DC;               reVal[0]=RF_OFF;     /* wait rpt/5*/
                hwCtrl[1]  = PA_OFF | BL_OFF | ADC_STOP;  duration[1]  = 125 * 1 - DC;               reVal[1]=RF_OFF;     /* wait rpt/5*/
                hwCtrl[2]  = PA_OFF | BL_OFF | ADC_STOP;  duration[2]  = 125 * 1 - DC;               reVal[2]=RF_OFF;     /* wait rpt/5*/
                hwCtrl[3]  = PA_OFF | BL_OFF | ADC_STOP;  duration[3]  = 125 * 1 - DC;               reVal[3]=RF_OFF;     /* wait rpt/5*/
                hwCtrl[4]  = PA_OFF | BL_OFF | ADC_STOP;  duration[4]  = 125 * 1 - DC;               reVal[4]=RF_OFF;     /* wait rpt/5*/
                hwCtrl[5]  = PA_ON  | BL_OFF | ADC_STOP;  duration[5]  = 125 * 10 - DC;              reVal[5]=RF_OFF;     /* wait 10  PA to come on*/
                hwCtrl[6]  = PA_ON  | BL_ON  | ADC_STOP;  duration[6]  = pl - DC;                    reVal[6]=8100;       /* TX=8100 90 pulse us*/
                hwCtrl[7]  = PA_OFF | BL_ON  | ADC_STOP;  duration[7]  = 125 * (tau - 10) - pl - DC; reVal[7]=RF_OFF;     /* tau corr for pulse warmup*/
                hwCtrl[8]  = PA_ON  | BL_OFF | ADC_STOP;  duration[8]  = 125 * 10 - DC;              reVal[8]=RF_OFF;     /* wait 10  PA warmup*/
                hwCtrl[9]  = PA_ON  | BL_OFF | ADC_STOP;  duration[9]  = pl * 2 - DC;                reVal[9]=8100;       /* TX=8100 180 pulse us*/
                hwCtrl[10] = PA_OFF | BL_ON  | ADC_STOP;  duration[10] = 125 * (tau-echoWait) - DC;  reVal[10]=RF_OFF;    /* Wait for Echo  5ms width*/
                hwCtrl[11] = PA_OFF | BL_ON  | ADC_START; duration[11] = 125 * noData - DC;
                                                                                                     reVal[11]=RF_OFF;    /* wait Signal Aquisition 5 ms*/
                hwCtrl[12] = PA_OFF | BL_ON  | ADC_STOP;  duration[12] = 125 * 1 - DC;               reVal[12]=RF_OFF;    /* wait rpt/5*/
                hwCtrl[13] = PA_OFF | BL_ON  | ADC_STOP;  duration[13] = 125 * 1 - DC;               reVal[13]=RF_OFF;    /* wait rpt/5*/
                hwCtrl[14] = PA_OFF | BL_ON  | ADC_STOP;  duration[14] = 125 * 1 - DC;               reVal[14]=RF_OFF;    /* wait rpt/5*/
            }
            
            func experimentT2() -> Void {
                noInstructions = 15;
                hwCtrl[0]  = PA_OFF | BL_OFF | ADC_STOP;  duration[0]  = 125 * 1 - DC;               reVal[0]=RF_OFF;   /* wait rpt/5*/
                hwCtrl[1]  = PA_OFF | BL_OFF | ADC_STOP;  duration[1]  = 125 * 1 - DC;               reVal[1]=RF_OFF;   /* wait rpt/5*/
                hwCtrl[2]  = PA_OFF | BL_OFF | ADC_STOP;  duration[2]  = 125 * 1 - DC;               reVal[2]=RF_OFF;   /* wait rpt/5*/
                hwCtrl[3]  = PA_OFF | BL_OFF | ADC_STOP;  duration[3]  = 125 * 1 - DC;               reVal[3]=RF_OFF;   /* wait rpt/5*/
                hwCtrl[4]  = PA_OFF | BL_OFF | ADC_STOP;  duration[4]  = 125 * 1 - DC;               reVal[4]=RF_OFF;   /* wait rpt/5*/
                hwCtrl[5]  = PA_ON  | BL_ON  | ADC_STOP;  duration[5]  = 125 * 10 - DC;              reVal[5]=RF_OFF;   /* wait 10  PA to come on*/
                hwCtrl[6]  = PA_ON  | BL_ON  | ADC_STOP;  duration[6]  = pl - DC;                    reVal[6]=8100;     /* TX=8100 90 pulse us*/
                hwCtrl[7]  = PA_OFF | BL_ON  | ADC_STOP;  duration[7]  = 125 * (tau - 10) - pl - DC; reVal[7]=RF_OFF;   /* tau Delay correct  switch on 10 us*/
                hwCtrl[8]  = PA_ON  | BL_OFF | ADC_STOP;  duration[8]  = 125 * 10 - DC;              reVal[8]=RF_OFF;   /* wait 10  PA to come on*/
                hwCtrl[9]  = PA_ON  | BL_OFF | ADC_STOP;  duration[9]  = pl * 2 - DC;                reVal[9]=8100;     /* TX=8100 180 pulse us*/
                hwCtrl[10] = PA_OFF | BL_ON  | ADC_STOP;  duration[10] = 125 * tau - DC;             reVal[10]=RF_OFF;  /* Wait for Echo   FIDDLE***********/
                hwCtrl[11] = PA_OFF | BL_ON  | ADC_START; duration[11] = 125 * noData - DC;
                                                                                                     reVal[11]=RF_OFF;  /* wait Signal Aquisition 5 ms*/
                hwCtrl[12] = PA_OFF | BL_OFF | ADC_STOP;  duration[12] = 125 * 1 - DC;               reVal[12]=RF_OFF;  /* wait rpt/5*/
                hwCtrl[13] = PA_OFF | BL_OFF | ADC_STOP;  duration[13] = 125 * 1 - DC;               reVal[13]=RF_OFF;  /* wait rpt/5*/
                hwCtrl[14] = PA_OFF | BL_ON  | ADC_STOP;  duration[14] = 125 * 1 - DC;               reVal[14]=RF_OFF;  /* wait rpt/5*/
            }
            
            func experimentPROG_SAT() -> Void {
                var SeqDelay: Int
                delayM = delayM - 6 // Min 6 ms in data aquisition loop  1ms in delay Total 7 ms
                if delayM < 1 { delayM = 1 }
                SeqDelay = delayM * 15625 / 32
                for ii in 0..<BLKS / 2 {
                    bufDelay[2 * ii + 1 ] = UInt32((((PA_OFF | ADC_STOP) & 0xff) << 24) | ((SeqDelay - DC) & 0xffffff))
                    bufDelay[2 * ii + 2] = UInt32((RF_OFF & 0xffff) | ((RF_OFF & 0xffff) << 16))
                }
                
            
                //  Single pulse sequence with min 5k data points and 1 ms dealy including filling buffer
                // Delay buffer called at end of each run of the sequence from trnr
                // Signal aquisiiton set to 5 ms (5000 data points) T1 delay correction 10us switch on 5us off  TOTAL 15 us
                let noData2: Int = 5000
                noInstructions = 6  // Real number
                let acqOffset: Int = 125 * (1000 - 15 - (256 - noInstructions)) - pl  // Includes buffer filing and sequence delays made up to 1ms
                hwCtrl[0]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[0]  = 125 * 10 - DC
                reVal[0] = RF_OFF     /* wait 10  PA to come on*/
                hwCtrl[1]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[1]  = pl - DC
                reVal[1] = 8100       /* TX=8100 90 pulse us*/
                hwCtrl[2]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[2]  = pl - DC
                imVal[2] = 8100       /* TX=8100 90 pulse us*/
                hwCtrl[3]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[3]  = 125 * 5 - DC
                reVal[3] = RF_OFF     /* wait 5 us POWER DOWN NOT ADDED to Data COunter*/
                hwCtrl[4]  = PA_OFF | BL_ON   | ADC_START
                duration[4]  = 125 * noData2 - DC
                reVal[4] = RF_OFF     /* wait Signal Aquisition 5 ms*/
                hwCtrl[5]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[5]  = acqOffset - DC
                reVal[5] = RF_OFF     /* Correct for delays and pl*/
            }
            
            func experimentT2PGSE() -> Void {
                //var eW: Int /* echo wait*/
                //eW=tau/4;
                let delta: Int = 300  /* us*/
                let tau1: Int = 30000 /* us foir the time being as */
                let gAmp: Int = tau
                let pd: Int = 10   /*RF Warm up time*/
                let gs: Int = 1    /*Gradient warm up time*/
                let gd: Int = 5000 /*Gradient pre delay*/
                let s: Int = 15    /*Offset for main sequence 3 dummy pulses*/
                noInstructions = 17 + s  /*  offset now*/
                /* wait rpt/5*/
               // 1st Dummy FGP
                hwCtrl[0] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[0] = 125 * 2 - DC
                reVal[0] = RF_OFF
                imVal[0] = RF_OFF
                hwCtrl[1] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[1] = 125 * delta - DC
                reVal[1] = GA_CTRL
                imVal[1] = gAmp
                hwCtrl[2] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[2] = 125 * gs - DC
                reVal[2] = GA_CTRL
                imVal[2] = G_OFF
                hwCtrl[3] = GA_OFF  | PA_OFF | BL_OFF | ADC_STOP
                duration[3] = 125 * gs - DC
                reVal[3] = RF_OFF
                imVal[3] = RF_OFF
                hwCtrl[4]  = PA_OFF  | BL_OFF | ADC_STOP
                duration[4]  = 125 * (tau1 - 4 * gs - delta) - DC
                reVal[4] = RF_OFF
                imVal[4] = RF_OFF

               // 2nd Dummy FGP
                hwCtrl[5] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[5] = 125 * 2 - DC
                reVal[5] = RF_OFF
                imVal[5] = RF_OFF
                hwCtrl[6] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[6] = 125 * delta - DC
                reVal[6] = GA_CTRL
                imVal[6] = gAmp
                hwCtrl[7] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[7] = 125 * gs - DC
                reVal[7] = GA_CTRL
                imVal[7] = G_OFF
                hwCtrl[8] = GA_OFF  | PA_OFF | BL_OFF | ADC_STOP
                duration[8] = 125 * gs - DC
                reVal[8] = RF_OFF
                imVal[8] = RF_OFF
                hwCtrl[9]  = PA_OFF  | BL_OFF | ADC_STOP
                duration[9]  = 125 * (tau1 - 4 * gs - delta) - DC
                reVal[9] = RF_OFF
                imVal[9] = RF_OFF

               // 3rd Dummy FGP has RF puse in it
                hwCtrl[10] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[10] = 125 * 2 - DC
                reVal[10] = RF_OFF
                imVal[10] = RF_OFF
                hwCtrl[11] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[11] = 125 * delta - DC
                reVal[11] = GA_CTRL
                imVal[11] = gAmp
                hwCtrl[12] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[12] = 125 * gs - DC
                reVal[12] = GA_CTRL
                imVal[12] = G_OFF
                hwCtrl[13] = GA_OFF  | PA_OFF | BL_OFF | ADC_STOP
                duration[13] = 125 * gs - DC
                reVal[13] = RF_OFF
                imVal[13] = RF_OFF
                hwCtrl[14] = PA_OFF  | BL_OFF | ADC_STOP
                duration[14]  = 125 * (tau1 / 2 - pd - 2 * gs - delta / 2 + gd) - pl / 4 - DC
                reVal[14] = RF_OFF
                imVal[14] = RF_OFF
          // Now sequence
                
                hwCtrl[s]   = PA_ON  | BL_OFF  | ADC_STOP
                duration[s]    = 125 * pd - DC
                reVal[s] = RF_OFF
                /* wait 10  PA to come on*/
                hwCtrl[s + 1] = PA_ON  | BL_ON   | ADC_STOP
                duration[s + 1]  = pl-DC
                reVal[s + 1] = 8100       /* TX=8100 90 pulse us*/
                hwCtrl[s + 2] = PA_OFF | BL_ON   | ADC_STOP
                duration[s + 2]  = 125 * (tau1 / 2 - delta / 2 - 2 * gs - gd) - pl / 2 - DC
                reVal[s + 2] = RF_OFF /* tau corr for pulse warmup*/
                //
                hwCtrl[s + 3 ] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[s + 3] = 125 * 2 * gs - DC
                reVal[s + 3] = RF_OFF
                imVal[s + 3] = RF_OFF
                hwCtrl[s + 4] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[s + 4] = 125 * delta - DC
                reVal[s + 4] = GA_CTRL
                imVal[s + 4] = gAmp
                hwCtrl[s + 5] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[s + 5] = 125 * gs - DC
                reVal[s + 5] = GA_CTRL
                imVal[s + 5] = G_OFF
                hwCtrl[s + 6] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[s + 6] = 125 * gs - DC
                reVal[s + 6] = RF_OFF
                imVal[s + 6] = RF_OFF
                // -2 for switch off of PFG
                hwCtrl[s + 7]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[s + 7]  = 125 * (tau1 / 2 - pd - delta / 2 - 2 * gs + gd) - pl - DC
                reVal[s + 7] = RF_OFF     /* wait 10  PA warmup*/
                hwCtrl[s + 8]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[s + 8]  = pl * 2 - DC
                reVal[s + 8] = 8100       /* TX=8100 180 pulse us*/
                hwCtrl[s + 9]  = PA_OFF | BL_ON   | ADC_STOP
                duration[s + 9]  = 125 * (tau1 / 2 - delta / 2 - 2 * gs - gd) - pl - DC
                reVal[s + 9] = RF_OFF    /* Wait for Echo  5ms width*/
                
                hwCtrl[s + 10] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[s + 10] = 125 * 2 * gs - DC
                reVal[s + 10] = RF_OFF
                imVal[s + 10] = RF_OFF
                hwCtrl[s + 11] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[s + 11] = 125 * delta - DC
                reVal[s + 11] = GA_CTRL
                imVal[s + 11] = gAmp
                hwCtrl[s + 12] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[s + 12] = 125 * gs - DC
                reVal[s + 12] = GA_CTRL
                imVal[s + 12] = G_OFF
                // Should give half echo delay -2 for switch off of PFG
                hwCtrl[s + 13] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[s + 13] = 125 * (tau1 / 2 - delta / 2 - 2 * gs + gd) - DC
                reVal[s + 13] = RF_OFF
                imVal[s + 13] = RF_OFF
                hwCtrl[s + 14] = PA_OFF | BL_ON   | ADC_START
                duration[s + 14] = 125 * noData - DC
                reVal[s + 14] = RF_OFF    /* wait Signal Aquisition 5 ms*/
                hwCtrl[s + 15] = PA_OFF | BL_OFF  | ADC_STOP
                duration[s + 15] = 125 * 1 - DC
                reVal[s + 15] = RF_OFF    /* wait rpt/5*/
                hwCtrl[s + 16] = PA_OFF | BL_OFF  | ADC_STOP
                duration[s + 16] = 125 * 1 - DC
                reVal[s + 16] = RF_OFF    /* wait rpt/5*/
                hwCtrl[s + 17] = PA_OFF | BL_OFF  | ADC_STOP
                duration[s + 17] = 125 * 1 - DC
                reVal[s + 17] = RF_OFF    /* wait rpt/5*/
            }
            
            func experimentDiffusionX() -> Void {
                //var eW: Int /* echo wait*/
                let delta = littleDelta /* in us*/
                var Delta = bigDelta /*i us Min 10 ms max 100 ms*/
                let tau: Int = 5000 /* us for the time being as */
                let gAmp = gradient
                let pd: Int = 10 /*RF Warm up time*/
                let gd: Int = 1  /*Gradient warm up time*/
                let s1: Int = 4   // Pre Sequence has 5 pulses numbering from 0
                let s2: Int = 10  // Middle Sequence
                //var s3: Int = 11 // Last Sequence
                var o: Int = 0 // variable offset
                var r: Int = 0 // Sequence Delay steps modified by Delta if >100 ms

                /* wait rpt/5*/
                //var extra: Int = 0
                var extraLoops: Int = 0
                var extraRemainder: Int = 0
                // Create internal; delay loop based on setting of Delta
                noInstructions = 26 //
                if bigDelta > 100000 {
                    Delta = 100000
                    extraLoops = bigDelta / 100000 - 1 //always take first 100 ms out
                    r = extraLoops
                    extraRemainder = bigDelta % 100000
                    if extraRemainder > 0 {
                        r = extraLoops + 1
                    }
                    noInstructions = noInstructions + 2 * r
                    //mexPrintf("  No_Ins %i r =  %i  Overflow Delay  %i  ",no_Instructions,r,extraRemainder);
                    // always one to step on and+extra single line
                    //For dummy FGP delay
                    o = s1 //mexPrintf(" \n o is %i ", o);
                    for ii in 1..<extraLoops + 1 {
                     // each 100 ms
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ ii + o] = 100000 * 125 - DC
                        reVal[ii + o] = RF_OFF                  // KGH possible error 0 -> o ?
                        imVal[ii + o] = RF_OFF
                    }
                    if extraRemainder > 0 {
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ii + o] = extraRemainder * 125 - DC
                        reVal[ii + o] = RF_OFF
                        imVal[ii + o] = RF_OFF
                    }
                    //For Delta FGP del
                    o = s1 + s2 + r //mexPrintf("\n o is %i", o);
                    for ii in 1..<extraLoops + 1 {
                     // each 100 ms
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ii + o] = 100000 * 125 - DC
                        reVal[ii + o] = RF_OFF
                        imVal[ii + o] = RF_OFF
                    }
                    if extraRemainder > 0 {
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ii + o] = extraRemainder * 125 - DC
                        reVal[ii + o] = RF_OFF
                        imVal[ii + o] = RF_OFF
                    }
                }
                //  Now define delyays
                let delay_a = (tau / 2 - 2 * gd - delta / 2) * 125 - pl / 2
                let delay_b = (tau / 2 - 2 * gd - pd - delta / 2) * 125 - pl / 2
                let delay_c = ( Delta - 4 * gd - 2 * pd - gd) * 125 - 2 * pl - delay_b - delay_a // delay_d=delay_a remove delta add extra -gd
                let delay_e = (tau / 2 - delta / 2 - 2 * gd) * 125
                let delay_f = (Delta - delta - 4 * gd - pd) * 125 - delay_a - pl
                   
         // 1st Dummy FGP has RF pulse in it
                o=0
                hwCtrl[0 + o] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[0 + o] = 125 * 2 - DC
                reVal[0 + o] = RF_OFF
                imVal[0 + o] = RF_OFF
                hwCtrl[1 + o] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[1 + o] = 125 * delta - DC
                reVal[1 + o] = GA_CTRL
                imVal[1 + o] = gAmp
                hwCtrl[2 + o] = GA_ON   | PA_OFF | BL_OFF | ADC_STOP
                duration[2 + o] = 125 * gd - DC
                reVal[2 + o] = GA_CTRL
                imVal[2 + o] = G_OFF
                hwCtrl[3 + o] = GA_OFF  | PA_OFF | BL_OFF | ADC_STOP
                duration[3 + o] = 125 * gd - DC
                reVal[3 + o] = RF_OFF
                imVal[3 + o] = RF_OFF
                hwCtrl[4 + o] = PA_OFF  | BL_OFF | ADC_STOP
                duration[4 + o] = delay_f - DC
                reVal[4 + o] = RF_OFF
                imVal[4 + o] = RF_OFF
           // Now sequence  shift s if new delays required
                if r > 0 { o = r } // mexPrintf(" o is %i", o);}
                //mexPrintf("\n o  is %imist delay ",o);
                hwCtrl[5 + o]   = PA_ON  | BL_OFF  | ADC_STOP
                duration[5 + o]    = 125 * pd - DC
                reVal[5 + o] = RF_OFF     /* wait 10  PA to come on*/
                hwCtrl[6 + o] = PA_ON  | BL_ON   | ADC_STOP
                duration[6 + o]  = pl-DC
                reVal[6 + o] = 8100       /* TX=8100 90 pulse us*/
                hwCtrl[7 + o] = PA_OFF | BL_ON   | ADC_STOP
                duration[7 + o]  = delay_a - DC
                reVal[7 + o] = RF_OFF /* tau corr for pulse warmup*/
                // 1st FPG
                hwCtrl[8 + o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[8 + o] = 125 * 2 * gd - DC
                reVal[8 + o] = RF_OFF
                imVal[8 + o] = RF_OFF
                hwCtrl[9 + o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[9 + o] = 125 * delta - DC
                reVal[9 + o] = GA_CTRL
                imVal[9 + o] = gAmp
                hwCtrl[10 + o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[10 + o] = 125 * gd - DC
                reVal[10 + o] = GA_CTRL
                imVal[10 + o] = G_OFF
                hwCtrl[11 + o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[11 + o] = 125 * gd - DC
                reVal[11 + o] = RF_OFF
                imVal[11 + o] = RF_OFF
                // -2 for switch off of PFG
                hwCtrl[12 + o]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[12 + o]  = delay_b - DC
                reVal[12 + o] = RF_OFF     /* wait 10  PA warmup*/
                hwCtrl[13 + o]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[13 + o]  = pl - DC
                reVal[13 + o] = 8100       /* TX=8100 2nd 90 pulse us*/
                // insert homospoil pulse
                hwCtrl[14 + o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[14 + o] = 125 * delta - DC
                reVal[14 + o] = GA_CTRL
                imVal[14 + o] = 200
                hwCtrl[15 + o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[15 + o] = 125 * gd - DC
                reVal[15 + o] = GA_CTRL
                imVal[15 + o] = G_OFF
                //
                o = o + 2
                hwCtrl[14 + o]  = PA_OFF | BL_ON   | ADC_STOP
                duration[14 + o]  = delay_c - DC
                reVal[14 + o] = RF_OFF    /* Wait for Echo  5ms width*/
                // shift sequence by r if necessary for extra delay
                if r>0 { o = 2 * r } // mexPrintf("\n  o is %i second delay", o);}
                //3rd 90 degree pulse
                hwCtrl[15 + o] = PA_ON  | BL_OFF  | ADC_STOP
                duration[15 + o]  = 125 * pd - DC
                reVal[15 + o] = RF_OFF     /* wait 10  PA to come on*/
                hwCtrl[16 + o] = PA_ON  | BL_ON   | ADC_STOP
                duration[16 + o]  = pl - DC
                reVal[16 + o] = 8100       /* TX=8100 90 pulse us*/
                hwCtrl[17 + o] = PA_OFF | BL_ON   | ADC_STOP
                duration[17 + o]  = delay_a - DC
                reVal[17 + o] = RF_OFF /* tau corr for pulse warmup*/
                // 2nd PFG
                hwCtrl[18 + o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[18 + o] = 125 * 2 * gd - DC
                reVal[18 + o] = RF_OFF
                imVal[18 + o] = RF_OFF
                hwCtrl[19 + o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[19 + o] = 125 * delta - DC
                reVal[19 + o] = GA_CTRL
                imVal[19 + o] = gAmp
                hwCtrl[20 + o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[20 + o] = 125 * 2 * gd - DC
                reVal[20 + o] = GA_CTRL
                imVal[20 + o] = G_OFF
                hwCtrl[21 + o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[21 + o] = delay_e - DC
                reVal[21 + o] = RF_OFF
                imVal[21 + o] = RF_OFF
                hwCtrl[22 + o] = PA_OFF | BL_ON   | ADC_START
                duration[22 + o] = 125 * noData - DC
                reVal[22 + o] = RF_OFF    /* wait Signal Aquisition 5 ms*/
                hwCtrl[23 + o] = PA_OFF | BL_OFF  | ADC_STOP
                duration[23 + o] = 125 * 1 - DC
                reVal[23 + o] = RF_OFF    /* wait rpt/5*/
                hwCtrl[24 + o] = PA_OFF | BL_OFF  | ADC_STOP
                duration[24 + o] = 125 * 1 - DC
                reVal[24 + o] = RF_OFF    /* wait rpt/5*/
                hwCtrl[25 + o] = PA_OFF | BL_OFF  | ADC_STOP
                duration[25 + o] = 125 * 1 - DC
                reVal[25 + o] = RF_OFF    /* wait rpt/5*/
            }
            
            func experimentDiffusionXX() -> Void {
                //var eW: Int /* echo wait*/
                let delta = littleDelta /* in us*/
                var Delta = bigDelta /*i us Min 10 ms max 100 ms*/
                let tau: Int = 5000 /* us for the time being as */
                let gAmp = gradient;
                let pd: Int = 10 /*RF Warm up time*/
                let gd: Int = 100  /*Gradient wait after pi  pulse*/
                let s1: Int = 4   // Pre Sequence has 5 pulses numbering from 0
                let s2: Int = 13  // Middle Sequence
                //var s3: Int = 11 // Last Sequence
                var o: Int = 0 // variable offset
                var r: Int = 0 // Sequence Delay steps modified by Delta if >100 ms
                //var o1: Int = 0  // shofft for dummy loop
                //var o2: Int = 0 //shift for delay loop
                /* wait rpt/5*/
                //var extra: Int = 0
                var extraLoops: Int = 0
                var extraRemainder: Int = 0
                let baseNoInstructions: Int = 32
                // Create internal; delay loop based on setting of Delta
                noInstructions = 30 //
                //mexPrintf(" ***** DIFFUSION ***** ");
                if bigDelta > 100000 {
                    Delta=100000
                    extraLoops = bigDelta / 100000 - 1 //always take first 100 ms out
                    extraRemainder = bigDelta % 100000
                    r = extraLoops
                    if extraRemainder > 0 {
                        r = r + 1
                    }
                    noInstructions = baseNoInstructions + 2 * r //for dummy and real delays
                    //mexPrintf(" \n No_Instructions  %i r  %i  extraR  %i \n ",no_Instructions,r,extraRemainder);
                    // ?riginal sequence has one delay max 100ms over 100 <200 add extraRemainder
                    // over 200 add 100ms and extraRemainder if >200
                    //For dummy FGP delay add extra instructions r=0 >100K <200K
                    o = s1 - 1
                    //mexPrintf(" \n Dummy Value  o is %i ", o);
                    for ii in 1..<extraLoops // each 100 ms no loops if extraLoops=0
                    {
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ii + o] = 100000 * 125 - DC
                        reVal[ii + o] = RF_OFF
                        imVal[ii + o] = RF_OFF
                    }
                    if extraRemainder > 0 {
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ii + o] = extraRemainder * 125 - DC
                        reVal[ii + o] = RF_OFF
                        imVal[ii + o]=RF_OFF
                    }
              //For Delta FGP del;
                    o = s1 + s2 + r - 1 //mexPrintf("\n Delta Value  o is %i ", o);
                    for ii in 1..<extraLoops + 1 { // each 100 ms
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ii + o] = 100000 * 125 - DC
                        reVal[ii + o] = RF_OFF
                        imVal[ii + o] = RF_OFF
                    }
                    if extraRemainder > 0 {
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ii + o] = extraRemainder * 125 - DC
                        reVal[ii + o] = RF_OFF
                        imVal[ii + o]=RF_OFF
                    }
                }
                //  Now define delyays
                let   delay_a = (tau / 2 - delta / 2 - gd) * 125 - 3 * pl / 2
                let   delay_b = delay_a - pd * 125
                let   delay_c = (Delta - 2 * gd - 2 * pd - delta) * 125 - 4 * pl - delay_b - delay_a // remove delta and sub -gd
                let   delay_e = (tau / 2 - delta / 2 - gd) * 125 - pl
                let   delay_f = (Delta - delta - gd - pd) * 125 - pl * 2 - delay_a

              // 1st Dummy FGP has RF pulse in it also now removed gradient on delay and gating pulse
                o = 1 //
                hwCtrl[0]    = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[0]   = 125 * gd - DC
                reVal[0]  = RF_OFF
                imVal[0]  = RF_OFF
                hwCtrl[0 + o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[0 + o] = 125 * delta - DC
                reVal[0 + o] = RF_OFF
                imVal[0 + o] = RF_OFF
                hwCtrl[1 + o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[1 + o] = 125 * gd - DC
                reVal[1 + o] = RF_OFF
                imVal[1 + o] = RF_OFF
                hwCtrl[2 + o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[2 + o] = delay_f - gd * 125 - DC
                reVal[2 + o] = RF_OFF
                imVal[2 + o] = RF_OFF
              // Now sequence  adds r (or r+1) new  instructions for long delays  ie Delta > 100 ms and if neede remaindery
                if r > 0 { o = r + 1 }// mexPrintf("\n ***Dummy Delay  o is %i ", o);}
                // 900 RF Pulse Switch Gradient gate on after 90 last 5 ms Line 572
                hwCtrl[3 + o]  = GA_OFF | PA_ON  | BL_OFF | ADC_STOP
                duration[3 + o]  = 125 * pd - DC
                reVal[3 + o] = RF_OFF
                imVal[3 + o] = RF_OFF /* wait 10us PA*/
                hwCtrl[4 + o]  = GA_OFF | PA_ON  | BL_ON  | ADC_STOP
                duration[4 + o]  = pl - DC
                reVal[4 + o] = 8100
                imVal[4 + o] = RF_OFF /* TX=8100 90 pulseus*/
                hwCtrl[5 + o]  = GA_OFF | PA_OFF | BL_ON  | ADC_STOP
                duration[5 + o]  = delay_a - DC
                reVal[5 + o] = RF_OFF
                imVal[5 + o] = RF_OFF /* pre Gradient pulse*/
                // 1st FPG first half delta
                hwCtrl[6 + o]  = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[6 + o]  = 125 * delta / 2 - DC
                reVal[6 + o] = GA_CTRL
                imVal[6 + o] = gAmp
                hwCtrl[7 + o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[7 + o]  = 125 * (gd - pd) - DC
                reVal[7 + o] = GA_CTRL
                imVal[7 + o] = GA_OFF
                hwCtrl[8 + o]  = GA_OFF | PA_ON  | BL_OFF | ADC_STOP
                duration[8 + o]  = 125 * pd - DC
                reVal[8 + o] = RF_OFF
                imVal[8 + o] = RF_OFF /* wait 10  PA*/
                // 180 RF Pulse  Phase??
                hwCtrl[9 + o]  = GA_OFF | PA_ON  | BL_OFF | ADC_STOP
                duration[9 + o]  = 2 * pl - DC
                reVal[9 + o] = 0
                imVal[9 + o] = 8100  /* 1800 y*/
                hwCtrl[10 + o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[10 + o] = 125 * gd - DC
                reVal[10 + o] = RF_OFF
                imVal[10 + o] = RF_OFF
                // 1st FPG second half delta
                hwCtrl[11 + o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[11 + o] = 125 * delta / 2 - DC
                reVal[11 + o] = GA_CTRL
                imVal[11 + o] = -gAmp
                hwCtrl[12 + o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[12 + o] = delay_b - DC
                reVal[12 + o] = GA_CTRL
                imVal[12 + o] = GA_OFF

              // 3rd RF pulse  2nd 90
                hwCtrl[13 + o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP
                duration[13 + o] = 125 * pd - DC
                reVal[13 + o] = RF_OFF
                imVal[13 + o] = RF_OFF
                hwCtrl[14 + o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP
                duration[14 + o] = pl - DC
                reVal[14 + o] = 8100
                imVal[14 + o] = RF_OFF  /* TX=8100 2nd 90us*/
                hwCtrl[15 + o] = PA_OFF | BL_ON  | ADC_STOP
                duration[15 + o] = delay_c - DC
                reVal[15 + o] = RF_OFF
                imVal[15 + o] = RF_OFF /* Delta period*/
                // shift sequence by 2r if necessary for extra delay for Delat >100 ms
                if r > 0 { o = 2 * r + 1 }// mexPrintf("\n Real Delay  o is %i second delay ", o);}
                //4th rf pulse 3rd 90  degree pulse sitch gradient gating on after 3rd 90 line 587
                hwCtrl[16 + o] = PA_ON  | BL_OFF  | ADC_STOP
                duration[16 + o] = 125 * pd - DC
                reVal[16 + o] = RF_OFF
                imVal[16 + o] = RF_OFF /* wait 10 us*/
                hwCtrl[17 + o] = PA_ON  | BL_ON   | ADC_STOP
                duration[17 + o] = pl - DC
                reVal[17 + o] = 8100
                imVal[17 + o] = RF_OFF /* TX=8100 90us*/
                hwCtrl[18 + o] = GA_OFF | BL_ON   | ADC_STOP
                duration[18 + o] = delay_a - DC
                reVal[18 + o] = RF_OFF
                imVal[18 + o] = RF_OFF /* pre PFG p*/
                // 2nd PFG first half delta
                hwCtrl[19 + o] = GA_ON  | PA_OFF  | BL_OFF | ADC_STOP
                duration[19 + o] = 125 * delta / 2 - DC
                reVal[19 + o] = GA_CTRL
                imVal[19 + o] = gAmp
                hwCtrl[20 + o] = GA_OFF | PA_OFF  | BL_OFF | ADC_STOP
                duration[20 + o] = 125 * (gd - pd) - DC
                reVal[20 + o] = GA_CTRL
                imVal[20 + o] = GA_OFF
                hwCtrl[21 + o] = GA_OFF | PA_ON   | BL_OFF | ADC_STOP
                duration[21 + o] = 125 * pd - DC
                reVal[21 + o] = RF_OFF
                imVal[21 + o] = RF_OFF /* wait 10  PA*/
                // 180 RF Pulse
                hwCtrl[22 + o] = GA_OFF | PA_ON   | BL_OFF | ADC_STOP
                duration[22 + o] = 2 * pl - DC
                reVal[22 + o] = RF_OFF
                imVal[22 + o] = 8100; /* TX=8100 180 Y*/
                hwCtrl[23 + o] = GA_OFF | PA_OFF  | BL_OFF | ADC_STOP
                duration[23 + o] = 125 * gd - DC
                reVal[23 + o] = RF_OFF
                imVal[23 + o] = RF_OFF
                // 2nd FPG second half delta
                hwCtrl[24 + o] = GA_ON  | PA_OFF  | BL_OFF | ADC_STOP
                duration[24 + o] = 125 * delta / 2 - DC
                reVal[24 + o] = GA_CTRL
                imVal[24 + o] = -gAmp
                //Rotate at echo centre to z with extra 90
                hwCtrl[25 + o] = GA_OFF | PA_OFF  | BL_OFF | ADC_STOP
                duration[25 + o] = delay_e - DC
                reVal[25 + o] = GA_CTRL
                imVal[25 + o] = GA_OFF
                // Collect data
                hwCtrl[26 + o] = PA_OFF | BL_ON   | ADC_START
                duration[26 + o] = 125 * noData - DC
                reVal[26 + o] = RF_OFF
                imVal[26 + o] = RF_OFF
                hwCtrl[27 + o] = PA_OFF | BL_OFF  | ADC_STOP
                duration[27 + o] = 125 * 1 - DC
                reVal[27 + o] = RF_OFF
                imVal[27 + o] = RF_OFF  /* wait rpt/5*/
                hwCtrl[28 + o] = PA_OFF | BL_OFF  | ADC_STOP
                duration[28 + o] = 125 * 1 - DC
                reVal[28 + o] = RF_OFF
                imVal[28 + o] = RF_OFF /* wait rpt/5*/
            }

            func experimentDiffusion() -> Void {
                //var eW: Int /* echo wait*/
                let delta = littleDelta /* in us*/
                var Delta = bigDelta /*i us Min 10 ms max 100 ms*/
                let tau: Int = 5000 /* us for the time being as */
                let gAmp = gradient
                let pd: Int = 10 /*RF Warm up time*/
                let gd: Int = 100  /*Gradient wait after pi  pulse*/
                let s1: Int = 4   // Pre Sequence has 5 pulses numbering from 0
                let s2: Int = 13  // Middle Sequence
                //var s3: Int = 11 // Last Sequence
                var o: Int = 0 // variable offset
                var r: Int = 0 // Sequence Delay steps modified by Delta if >100 ms
                //var o1: Int = 0  // shofft for dummy loop
                //var o2: Int = 0 //shift for delay loop
                /* wait rpt/5*/
                //var extra: Int = 0
                var extraLoops: Int = 0
                var extraRemainder: Int = 0
                let baseNoInstructions: Int = 36
                // Create internal; delay loop based on setting of Delta
                noInstructions = 34 //
                //mexPrintf(" ***** DIFFUSION ***** ");
                if bigDelta > 100000 {
                    Delta = 100000
                    extraLoops = bigDelta / 100000 - 1 //always take first 100 ms out
                    extraRemainder = bigDelta % 100000
                    r = extraLoops
                    if extraRemainder > 0 {
                        r = r + 1
                    }
                    noInstructions = baseNoInstructions + 2 * r //for dummy and real delays
                    //mexPrintf(" \n No_Instructions  %i r  %i  extraR  %i \n ",no_Instructions,r,extraRemainder);
                    // ?riginal sequence has one delay max 100ms over 100 <200 add extraRemainder
                    // over 200 add 100ms and extraRemainder if >200
                    //For dummy FGP delay add extra instructions r=0 >100K <200K
                    o = s1 - 1 ;
                    //mexPrintf(" \n Dummy Value  o is %i ", o);
                    for ii in 1..<extraLoops + 1 { // each 100 ms no loops if extraLoops=0
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ii + o] = 100000 * 125 - DC
                        reVal[ii + o] = RF_OFF
                        imVal[ii + o] = RF_OFF
                    }
                    if extraRemainder > 0 {
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ii + o] = extraRemainder * 125 - DC
                        reVal[ii + o] = RF_OFF
                        imVal[ii + o] = RF_OFF
                    }
              //For Delta FGP del;
                    o = s1 + s2 + r - 1 //mexPrintf("\n Delta Value  o is %i ", o);
                    for ii in 1..<extraLoops + 1 { // each 100 ms
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ii + o] = 100000 * 125 - DC
                        reVal[ii + o] = RF_OFF
                        imVal[ii + o] = RF_OFF
                    }
                    if extraRemainder > 0 {
                        hwCtrl[ii + o] = PA_OFF  | BL_OFF | ADC_STOP
                        duration[ii + o] = extraRemainder * 125 - DC
                        reVal[ii + o] = RF_OFF
                        imVal[ii + o] = RF_OFF
                    }
                }
                //  Now define delyays
                let   delay_a = (tau / 2 - delta / 2 - gd) * 125 - 3 * pl / 2
                let   delay_b = delay_a - pd * 125
                let   delay_c = (Delta - 2 * gd - 2 * pd - delta) * 125 - 4 * pl - delay_b - delay_a // remove delta and sub -gd
                let   delay_e = (tau / 2 - delta / 2 - gd) * 125 - pl
                let   delay_f = (Delta - delta - gd - pd) * 125 - pl * 2 - delay_a

              // 1st Dummy FGP has RF pulse in it also now removed gradient on delay and gating pulse
                o = 1 //
                hwCtrl[0]    = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[0]   = 125 * gd - DC
                reVal[0]  = RF_OFF
                imVal[0]  = RF_OFF
                hwCtrl[0 + o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[0 + o] = 125 * delta - DC
                reVal[0 + o] = RF_OFF
                imVal[0 + o] = RF_OFF
                hwCtrl[1 + o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[1 + o] = 125 * gd - DC
                reVal[1 + o] = RF_OFF
                imVal[1 + o] = RF_OFF
                hwCtrl[2 + o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[2 + o] = delay_f - gd * 125 - DC
                reVal[2 + o] = RF_OFF
                imVal[2 + o] = RF_OFF
              // Now sequence  adds r (or r+1) new  instructions for long delays  ie Delta > 100 ms and if neede remaindery
                if r>0 { o = r + 1 }// mexPrintf("\n ***Dummy Delay  o is %i ", o);}
                // 900 RF Pulse Switch Gradient gate on after 90 last 5 ms Line 572
                hwCtrl[3 + o]  = GA_OFF | PA_ON  | BL_OFF | ADC_STOP
                duration[3 + o]  = 125 * pd - DC
                reVal[3 + o] = RF_OFF
                imVal[3 + o] = RF_OFF  /* wait 10us PA*/
                hwCtrl[4 + o]  = GA_OFF | PA_ON  | BL_ON  | ADC_STOP
                duration[4 + o]  = pl - DC
                reVal[4 + o] = 8100
                imVal[4 + o] = RF_OFF/* TX=8100 90 pulseus*/
                hwCtrl[5 + o]  = GA_OFF | PA_OFF | BL_ON  | ADC_STOP
                duration[5 + o]  = delay_a - DC
                reVal[5 + o] = RF_OFF
                imVal[5 + o] = RF_OFF /* pre Gradient pulse*/
                // 1st FPG first half delta 10us delay
                o = o + 1
                hwCtrl[5 + o]  = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[5 + o]  = 125 * 10 - DC
                reVal[5 + o] = GA_CTRL
                imVal[5 + o] = GA_OFF
                hwCtrl[6 + o]  = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[6 + o]  = 125 * delta / 2 - DC
                reVal[6 + o] = GA_CTRL
                imVal[6 + o] = gAmp
                hwCtrl[7 + o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[7 + o]  = 125 * (gd - pd) - DC
                reVal[7 + o] = GA_CTRL
                imVal[7 + o] = GA_OFF
                hwCtrl[8 + o]  = GA_OFF | PA_ON  | BL_OFF | ADC_STOP
                duration[8 + o]  = 125 * pd - DC
                reVal[8 + o] = RF_OFF
                imVal[8 + o] = RF_OFF /* wait 10  PA*/
                // 180 RF Pulse  Phase??
                hwCtrl[9 + o]  = GA_OFF | PA_ON  | BL_OFF | ADC_STOP
                duration[9 + o]  = 2 * pl - DC
                reVal[9 + o] = 0
                imVal[9 + o] = 8100  /* 1800 y*/
                hwCtrl[10 + o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[10 + o] = 125 * gd - DC
                reVal[10 + o] = RF_OFF
                imVal[10 + o] = RF_OFF
                // 1st FPG second half delta  10us delay
                o = o + 1
                hwCtrl[10 + o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[10 + o] = 125 * 10 - DC
                reVal[10 + o] = GA_CTRL
                imVal[10 + o] = GA_OFF
                hwCtrl[11 + o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP
                duration[11 + o] = 125 * delta / 2 - DC
                reVal[11 + o] = GA_CTRL
                imVal[11 + o] = -gAmp
                hwCtrl[12 + o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP
                duration[12 + o] = delay_b - DC
                reVal[12 + o] = GA_CTRL
                imVal[12 + o] = GA_OFF

              // 3rd RF pulse  2nd 90
                hwCtrl[13 + o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP
                duration[13 + o] = 125 * pd - DC
                reVal[13 + o] = RF_OFF
                imVal[13 + o] = RF_OFF
                hwCtrl[14 + o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP
                duration[14 + o] = pl - DC
                reVal[14 + o] = 8100
                imVal[14+o] = RF_OFF /* TX=8100 2nd 90us*/
                hwCtrl[15 + o] = PA_OFF | BL_ON  | ADC_STOP
                duration[15 + o] = delay_c - DC
                reVal[15 + o] = RF_OFF
                imVal[15 + o] = RF_OFF /* Delta period*/
                // shift sequence by 2r if necessary for extra delay for Delat >100 ms
                if r > 0 { o = 2 * r + 1 }// mexPrintf("\n Real Delay  o is %i second delay ", o);}
                //4th rf pulse 3rd 90  degree pulse sitch gradient gating on after 3rd 90 line 587
                hwCtrl[16 + o] = PA_ON  | BL_OFF  | ADC_STOP
                duration[16 + o] = 125 * pd - DC
                reVal[16 + o] = RF_OFF
                imVal[16 + o] = RF_OFF /* wait 10 us*/
                hwCtrl[17 + o] = PA_ON  | BL_ON   | ADC_STOP
                duration[17 + o] = pl - DC
                reVal[17 + o] = 8100
                imVal[17 + o] = RF_OFF /* TX=8100 90us*/
                hwCtrl[18 + o] = GA_OFF | BL_ON   | ADC_STOP
                duration[18 + o] = delay_a - DC
                reVal[18 + o] = RF_OFF
                imVal[18 + o] = RF_OFF /* pre PFG p*/
                // 2nd PFG first half delta 10us delay
                o = o + 1
                hwCtrl[18 + o] = GA_ON  | PA_OFF  | BL_OFF | ADC_STOP
                duration[18 + o] = 125 * 10 - DC
                reVal[18 + o] = GA_CTRL
                imVal[18 + o] = 0
                hwCtrl[19 + o] = GA_ON  | PA_OFF  | BL_OFF | ADC_STOP
                duration[19 + o] = 125 * delta / 2 - DC
                reVal[19 + o] = GA_CTRL
                imVal[19 + o] = gAmp
                hwCtrl[20 + o] = GA_OFF | PA_OFF  | BL_OFF | ADC_STOP
                duration[20 + o] = 125 * (gd - pd) - DC
                reVal[20 + o] = GA_CTRL
                imVal[20 + o] = GA_OFF
                hwCtrl[21 + o] = GA_OFF | PA_ON   | BL_OFF | ADC_STOP
                duration[21 + o] = 125 * pd - DC
                reVal[21 + o] = RF_OFF
                imVal[21 + o] = RF_OFF /* wait 10  PA*/
                // 180 RF Pulse
                hwCtrl[22 + o] = GA_OFF | PA_ON   | BL_OFF | ADC_STOP
                duration[22 + o] = 2 * pl - DC
                reVal[22 + o] = RF_OFF
                imVal[22 + o] = 8100 /* TX=8100 180 Y*/
                hwCtrl[23 + o] = GA_OFF | PA_OFF  | BL_OFF | ADC_STOP
                duration[23 + o] = 125 * gd - DC
                reVal[23 + o] = RF_OFF
                imVal[23 + o] = RF_OFF
                // 2nd FPG second half delta and 10us delay
                o = o + 1
                hwCtrl[23 + o] = GA_ON  | PA_OFF  | BL_OFF | ADC_STOP
                duration[23 + o] = 125 * 10 - DC
                reVal[23 + o] = GA_CTRL
                imVal[23 + o] = 0
                hwCtrl[24 + o] = GA_ON  | PA_OFF  | BL_OFF | ADC_STOP
                duration[24 + o] = 125 * delta / 2 - DC
                reVal[24 + o] = GA_CTRL
                imVal[24 + o] = -gAmp
                //Rotate at echo centre to z with extra 90
                hwCtrl[25 + o] = GA_OFF | PA_OFF  | BL_OFF | ADC_STOP
                duration[25 + o] = delay_e - DC
                reVal[25 + o] = GA_CTRL
                imVal[25 + o] = GA_OFF
                // Collect data
                hwCtrl[26 + o] = PA_OFF | BL_ON   | ADC_START
                duration[26 + o] = 125 * noData - DC
                reVal[26 + o] = RF_OFF
                imVal[26 + o] = RF_OFF
                hwCtrl[27 + o] = PA_OFF | BL_OFF  | ADC_STOP
                duration[27 + o] = 125 * 1 - DC
                reVal[27 + o] = RF_OFF
                imVal[27 + o] = RF_OFF  /* wait rpt/5*/
                hwCtrl[28 + o] = PA_OFF | BL_OFF  | ADC_STOP
                duration[28 + o] = 125 * 1 - DC
                reVal[28 + o] = RF_OFF
                imVal[28 + o] = RF_OFF  /* wait rpt/5*/
            }

            func experimentDiffusion_LED() -> Void {
                //var eW: Int /* echo wait*/
                let delta = littleDelta /* in us*/
                let Delta = bigDelta /*i us Min 10 ms max 100 ms*/
                let tau: Int = 5000 /* us for the time being as */
                let gAmp = gradient
                let pd: Int = 10 /*RF Warm up time*/
                let gd: Int = 100  /*Gradient wait after pi  pulse*/
                let t1: Int = 10000 /* Extra z deacvy for LED sequence*/
                //var s1: Int = 4   // Pre Sequence has 5 pulses numbering from 0
                //var s2: Int = 13  // Middle Sequence
                //var s3: Int = 11 // Last Sequence
                var o: Int = 0 // variable offset
                //var r: Int = 0 // Sequence Delay steps modified by Delta if >100 ms
                //var o1: Int = 0  // shofft for dummy loop
                //var o2: Int = 0 //shift for delay loop
                /* wait rpt/5*/
                //var extra: Int = 0
                //var extraLoops: Int = 0
                //var extraRemainder: Int = 0
                //var baseNoInstructions: Int = 44
                // Create internal; delay loop based on setting of Delta
                noInstructions = 46
                //mexPrintf(" ***** DIFFUSION ***** ");
                /*
                 * if(bigDelta > 100000)
                {
                    Delta=100000;
                    extraLoops=bigDelta/100000-1; //always take first 100 ms out
                    extraRemainder=bigDelta%100000;
                    r= extraLoops;
                    if(extraRemainder>0)
                    {
                        r=r+1;
                    }
                    no_Instructions =base_no_Instructions+2*r; //for dummy and real delays
                    //mexPrintf(" \n No_Instructions  %i r  %i  extraR  %i \n ",no_Instructions,r,extraRemainder);
                    // ?riginal sequence has one delay max 100ms over 100 <200 add extraRemainder
                    // over 200 add 100ms and extraRemainder if >200
                    //For dummy FGP delay add extra instructions r=0 >100K <200K
                    o=s1-1;
                    //mexPrintf(" \n Dummy Value  o is %i ", o);
                    for (ii = 1; ii < extraLoops+1; ii++) // each 100 ms no loops if extraLoops=0
                    {
                      hw_ctrl[ii+o] = PA_OFF  | BL_OFF | ADC_STOP; duration[ii+o] = 100000*125-DC;    re_val[ii+0]=RF_OFF;  im_val[ii+o]=RF_OFF;
                    }
                    if(extraRemainder >0 )
                    {hw_ctrl[ii+o] = PA_OFF  | BL_OFF | ADC_STOP; duration[ii+o] = extraRemainder*125-DC;    re_val[ii+o]=RF_OFF;  im_val[ii+o]=RF_OFF;}
                    //For Delta FGP del;
                    o=s1+s2+r-1; //mexPrintf("\n Delta Value  o is %i ", o);
                    for (ii = 1; ii < extraLoops+1; ii++) // each 100 ms
                    {
                     hw_ctrl[ii+o] = PA_OFF  | BL_OFF | ADC_STOP; duration[ii+o] = 100000*125-DC;    re_val[ii+o]=RF_OFF;  im_val[ii+o]=RF_OFF;
                    }
                    if(extraRemainder >0 )
                    {hw_ctrl[ii+o] = PA_OFF  | BL_OFF | ADC_STOP; duration[ii+o] = extraRemainder*125-DC;    re_val[ii+o]=RF_OFF;  im_val[ii+o]=RF_OFF;}
                }
                */
                
                //  Now define delyays
                let   delay_a = (tau / 2 - delta / 2 - gd) * 125 - 3 * pl / 2
                let   delay_b = delay_a - pd * 125
                let   delay_c = (Delta - 3 * gd - 2 * pd - 2 * delta) * 125 - 4 * pl - delay_b - delay_a //
                //var   delay_e = (tau / 2 - delta / 2 - gd) * 125 - pl
                let   delay_f = (Delta - delta - 2 * gd) * 125 - 2 * pl
                let   delay_g = (Delta - pd - delta - 2 * gd) * 125 - 3 * pl - delay_a
                let   delay_h = (t1 - gd - delta - pd) * 125
               // mexPrintf("\n Delay a  is %i ", delay_a);
               // mexPrintf("\n Delay b  is %i ", delay_b);
               // mexPrintf("\n Delay c  is %i ", delay_c);
               // mexPrintf("\n Delay f  is %i ", delay_f);
               // mexPrintf("\n Delay g  is %i ", delay_g);
               // mexPrintf("\n Delay h  is %i ", delay_h);
              // 2  bipolar pulses  with separation Delta still need to add extra delays for Delta>100000
                o=1; //
                hwCtrl[0]    = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[0]    = 125*5000-DC;          reVal[0]=RF_OFF;     imVal[0]    = RF_OFF;
                hwCtrl[0+o]  = GA_ON  | PA_OFF | BL_OFF | ADC_STOP; duration[0+o]  = 125*delta/2-DC;     reVal[0+o]=GA_CTRL;  imVal[0+o]  = gAmp;
                hwCtrl[1+o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[1+o]  = 125*(2*gd)+2*pl-DC; reVal[1+o]=GA_CTRL;  imVal[1+o]  = G_OFF;
                hwCtrl[2+o]  = GA_ON  | PA_OFF | BL_OFF | ADC_STOP; duration[2+o]  = 125*delta/2-DC;     reVal[2+o]=GA_CTRL;  imVal[2+o]  = -gAmp;
                hwCtrl[3+o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[3+o]  = delay_f-DC;         reVal[3+o]=GA_CTRL;  imVal[3+o]  = G_OFF;
              // 2nd Biplar pulses finishes with delya before first 90X pulse
                hwCtrl[4+o]  = GA_ON  | PA_OFF | BL_OFF | ADC_STOP; duration[4+o]  = 125*delta/2-DC;     reVal[4+o]=GA_CTRL;  imVal[4+o]  = gAmp;
                hwCtrl[5+o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[5+o]  = 125*(2*gd)+2*pl-DC; reVal[5+o]=GA_CTRL;  imVal[5+o]  = G_OFF;
                hwCtrl[6+o]  = GA_ON  | PA_OFF | BL_OFF | ADC_STOP; duration[6+o]  = 125*delta/2-DC;     reVal[6+o]=GA_CTRL;  imVal[6+o]  = -gAmp;
                hwCtrl[7+o]  = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[7+o]  = delay_g-DC;         reVal[7+o]=GA_CTRL;  imVal[7+o]  = G_OFF;

              // Now sequence  adds r (or r+1) new  instructions for long delays  ie Delta > 100 ms and if neede remaindery
                //if(r>0){o=r+1;}// mexPrintf("\n ***Dummy Delay  o is %i ", o);}
                // 900 RF Pulse
                hwCtrl[8+o]  = GA_OFF | PA_ON  | BL_OFF | ADC_STOP; duration[8+o]  = 125*pd-DC;         reVal[8+o]=RF_OFF;    imVal[8+o]=RF_OFF; /* wait 10us PA*/
                hwCtrl[9+o]  = GA_OFF | PA_ON  | BL_ON  | ADC_STOP; duration[9+o]  = pl-DC;             reVal[9+o]=8100;      imVal[9+o]=RF_OFF;/* TX=8100 90 pulseus*/
                hwCtrl[10+o] = GA_OFF | PA_OFF | BL_ON  | ADC_STOP; duration[10+o] = delay_a-DC;        reVal[10+o]=RF_OFF;   imVal[10+o]=RF_OFF;/* pre Gradient pulse*/
                // 1st FPG first half delta
                hwCtrl[11+o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP; duration[11+o] = 125*delta/2-DC;    reVal[11+o]=GA_CTRL;  imVal[11+o]=gAmp;
                hwCtrl[12+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[12+o] = 125*(gd-pd)-DC;    reVal[12+o]=GA_CTRL;  imVal[12+o]=G_OFF;
                hwCtrl[13+o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP; duration[13+o] = 125*pd - DC;        reVal[13+o]=RF_OFF;   imVal[13+o]=RF_OFF;/* wait 10  PA*/
                // 180 RF Pulse  Phase??
                hwCtrl[14+o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP; duration[14+o] = 2*pl-DC;           reVal[14+o]=RF_OFF;   imVal[14+o]=8100;  /* 1800 y*/
                hwCtrl[15+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[15+o] = 125*gd-DC;         reVal[15+o]=RF_OFF;   imVal[15+o]=RF_OFF;
                // 1st FPG second half delta
                hwCtrl[16+o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP; duration[16+o] = 125*delta/2-DC;    reVal[16+o]=GA_CTRL;  imVal[16+o] = -gAmp;
                hwCtrl[17+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[17+o] = delay_b - DC;       reVal[17+o]=GA_CTRL;  imVal[17+o]=G_OFF;
              // 2nd RF pulse  2nd 90
                hwCtrl[18+o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP; duration[18+o] = 125*pd - DC;        reVal[18+o]=RF_OFF;   imVal[18+o]=RF_OFF;
                hwCtrl[19+o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP; duration[19+o] = pl-DC;             reVal[19+o]=8100;     imVal[19+o]=RF_OFF; /* TX=8100 2nd 90us*/
              // add homospoil
                hwCtrl[20+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[20+o] = 125*gd-DC;         reVal[20+o]=RF_OFF;   imVal[20+o]=RF_OFF;
                o=o+1;
                hwCtrl[20+o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP; duration[20+o] = 125*delta-DC;      reVal[20+o]=GA_CTRL;  imVal[20+o]=gAmp;
                hwCtrl[21+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[21+o] = delay_c-DC;        reVal[21+o]=GA_CTRL;  imVal[21+o]=G_OFF;/* Delta period*/
              // shift sequence by 2r if necessary for extra delay for Delat >100 ms
                //if(r>0){o=2*r+1;}// mexPrintf("\n Real Delay  o is %i second delay ", o);
                //4th rf pulse 3rd 90  degree pulse
                hwCtrl[22+o] = GA_OFF | PA_ON  | BL_OFF  | ADC_STOP; duration[22+o] = 125*pd-DC;        reVal[22+o]=RF_OFF;    imVal[22+o]=RF_OFF;/* wait 10 us*/
                hwCtrl[23+o] = GA_OFF | PA_ON  | BL_ON   | ADC_STOP; duration[23+o] = pl-DC;            reVal[23+o]=8100;      imVal[23+o]=RF_OFF;/* TX=8100 90us*/
                hwCtrl[24+o] = GA_OFF | PA_OFF | BL_ON   | ADC_STOP; duration[24+o] = delay_a-DC;       reVal[24+o]=RF_OFF;    imVal[24+o]=RF_OFF;/* pre PFG p*/
                // 2nd PFG first half delta
                hwCtrl[25+o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP; duration[25+o] = 125*delta/2-DC;   reVal[25+o]=GA_CTRL;   imVal[25+o]=gAmp;
                hwCtrl[26+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[26+o] = 125*(gd-pd)-DC;   reVal[26+o]=GA_CTRL;   imVal[26+o]=G_OFF;
                hwCtrl[27+o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP; duration[27+o] = 125*pd - DC;       reVal[27+o]=RF_OFF;    imVal[27+o]=RF_OFF;/* wait 10  PA*/
                // 180 RF Pulse
                hwCtrl[28+o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP; duration[28+o] = 2*pl-DC;          reVal[28+o]=RF_OFF;    imVal[28+o]=8100; /* TX=8100 180 Y*/
                hwCtrl[29+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[29+o] = 125*gd-DC;        reVal[29+o]=RF_OFF;    imVal[29+o]=RF_OFF;
                // 2nd FPG second half delta
                hwCtrl[30+o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP; duration[30+o] = 125*delta/2-DC;   reVal[30+o]=GA_CTRL;   imVal[30+o] = -gAmp;
                //Rotate at echo centre to z with extra 90
                hwCtrl[31+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[31+o] = delay_b-DC;       reVal[31+o]=GA_CTRL;   imVal[31+o]=G_OFF;
                // Try extra eddy current LED with  z decay during t1 rotate back to z
                hwCtrl[32+o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP; duration[32+o] = 125*pd-DC;        reVal[32+o]=RF_OFF;    imVal[32+o]=RF_OFF;/* wait 10 us*/
                hwCtrl[33+o] = GA_OFF | PA_ON  | BL_ON  | ADC_STOP; duration[33+o] = pl-DC;            reVal[33+o]=8100;      imVal[33+o]=RF_OFF; /* TX=8100 90us*/
                //Extra T1  delay for eddy current delay length t1 say 10 ms ms and  2nd homospoil
                hwCtrl[34+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[34+o] = 125*gd-DC;        reVal[34+o]=RF_OFF;    imVal[34+o]=RF_OFF;
                hwCtrl[35+o] = GA_ON  | PA_OFF | BL_OFF | ADC_STOP; duration[35+o] = 125*delta-DC;     reVal[35+o]=GA_CTRL;   imVal[35+o] = -gAmp;
                hwCtrl[36+o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP; duration[36+o] = 125*delay_h-DC;   reVal[36+o]=GA_CTRL;   imVal[36+o]=G_OFF;/* wait 10 us*/
                 //Get FID with another 90x pulse the collect data
                hwCtrl[37+o] = GA_OFF | PA_ON  | BL_OFF | ADC_STOP; duration[37+o] = 125*pd-DC;        reVal[37+o]=RF_OFF;    imVal[37+o]=RF_OFF;/* wait 10 us*/
                hwCtrl[38+o] = GA_OFF | PA_ON  | BL_ON  | ADC_STOP; duration[38+o] = pl-DC;            reVal[38+o]=8100;      imVal[38+o]=RF_OFF;/* TX=8100 90us*/
                hwCtrl[39+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[39+o] = 125*10-DC;        reVal[39+o]=RF_OFF;    imVal[39+o]=RF_OFF;   /* wait 10 us POWER DOWN NOT ADDED to Data COunter*/
                // Collect data
                hwCtrl[40+o] = GA_OFF | PA_OFF | BL_ON  | ADC_START;duration[40+o] = 125*noData-DC;   reVal[40+o]=RF_OFF;    imVal[40+o]=RF_OFF;
                hwCtrl[41+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[41+o] = 125*1-DC;         reVal[41+o]=RF_OFF;    imVal[41+o]=RF_OFF;  /* wait rpt/5*/
                hwCtrl[42+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[42+o] = 125*1-DC;         reVal[42+o]=RF_OFF;    imVal[42+o]=RF_OFF; /* wait rpt/5*/
                hwCtrl[43+o] = GA_OFF | PA_OFF | BL_OFF | ADC_STOP; duration[43+o] = 125*1-DC;         reVal[43+o]=RF_OFF;    imVal[43+o]=RF_OFF; /* wait rpt/5*/
            }

            func experimentSolidEcho() -> Void {
                if tau < 10 {/* in us  set minimum tau*/
                    tau = 10  /* Assume pl<<10*/
                }
                
                noInstructions = 15
                hwCtrl[0]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[0]  = 125 * 1 - DC
                reVal[0] = RF_OFF     /* wait rpt/5*/
                hwCtrl[1]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[1]  = 125 * 1 - DC
                reVal[1] = RF_OFF     /* wait rpt/5*/
                hwCtrl[2]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[2]  = 125 * 1 - DC
                reVal[2] = RF_OFF     /* wait rpt/5*/
                hwCtrl[3]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[3]  = 125 * 1 - DC
                reVal[3] = RF_OFF     /* wait rpt/5*/
                hwCtrl[4]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[4]  = 125 * 1 - DC
                reVal[4] = RF_OFF     /* wait rpt/5*/
                hwCtrl[5]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[5]  = 125 * 10 - DC
                reVal[5] = RF_OFF     /* wait 10  PA to come on*/
                hwCtrl[6]  = PA_ON  | BL_ON   | ADC_STOP
                duration[6]  = pl - DC
                reVal[6] = 8100       /* TX=8100 90 pulse us*/
                hwCtrl[7]  = PA_OFF | BL_ON   | ADC_STOP
                duration[7]  = 125 * tau - pl - DC
                reVal[7] = RF_OFF     /* tau corr for pulse warmup*/
                hwCtrl[8]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[8]  = 125 * 10 - DC
                reVal[8] = RF_OFF     /* wait 10  PA warmup*/
                hwCtrl[9]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[9]  = pl - DC
                imVal[9] = 8100       /* TX=8100 90 pulse us*/
                hwCtrl[10] = PA_OFF | BL_ON   | ADC_STOP
                duration[10] = 125 * tau - pl - DC
                reVal[10] = RF_OFF    /*Echo Center*/
                hwCtrl[11] = PA_OFF | BL_ON   | ADC_START
                duration[11] = 125 * noData - DC
                reVal[11] = RF_OFF    /* wait Signal Aquisition 5 ms*/
                hwCtrl[12] = PA_OFF | BL_ON   | ADC_STOP
                duration[12] = 125 * 1 - DC
                reVal[12] = RF_OFF    /* wait rpt/5*/
                hwCtrl[13] = PA_OFF | BL_ON   | ADC_STOP
                duration[13] = 125 * 1 - DC
                reVal[13] = RF_OFF    /* wait rpt/5*/
                hwCtrl[14] = PA_OFF | BL_ON   | ADC_STOP
                duration[14] = 125 * 1 - DC
                reVal[14] = RF_OFF    /* wait rpt/5*/
            }

            func experimentLiquidEcho() -> Void {
                if tau < 20 {   /* in us  set minimum tau*/
                   tau = 20      /* Assume pl<<10*/
                }
                var delay: Int = 10
               
                if tau  > 2500 { /* in us  set dleay fro ech max at 2.5 ms tau*/
                    delay = tau - 2500;  /* Assume pl<<10*/
          
                }
       // Use tau as gamp for the moment
                let gAmp = tau
                noInstructions = 18
                let gradientL: Int = 2500 * 125 /*(no_Data/2)*125; 2500 */
                let tauNs: Int = 8000 * 125
                let d1 = tauNs / 2 - pl / 2 - gradientL / 2 - DC
                let d2 = tauNs / 2 - gradientL / 2 - 10 * 125 - pl - DC
                let d3 = tauNs - pl - gradientL - DC
                hwCtrl[0]  =  GA_OFF | PA_OFF | BL_OFF  | ADC_STOP
                duration[0]  = 125 * 1 - DC
                reVal[0] = RF_OFF
                imVal[0] = RF_OFF  /* wait rpt/5*/
                hwCtrl[1]  =  GA_OFF | PA_OFF | BL_OFF  | ADC_STOP
                duration[1]  = 125 * 1 - DC
                reVal[1] = RF_OFF
                imVal[1] = RF_OFF  /* wait rpt/5*/
                hwCtrl[2]  =  GA_OFF | PA_OFF | BL_OFF  | ADC_STOP
                duration[2]  = 125 * 1 - DC
                reVal[2] = RF_OFF
                imVal[2] = RF_OFF /* wait rpt/5*/
                hwCtrl[3]  =  GA_OFF | PA_OFF | BL_OFF  | ADC_STOP
                duration[3]  = 125 * 1 - DC
                reVal[3] = RF_OFF
                imVal[3] = RF_OFF  /* wait rpt/5*/
                hwCtrl[4]  =  GA_OFF | PA_OFF | BL_OFF  | ADC_STOP
                duration[4]  = 125 * 1 - DC
                reVal[4] = RF_OFF
                imVal[4] = RF_OFF /* wait rpt/5*/
                hwCtrl[5]  =  GA_OFF | PA_ON  | BL_OFF  | ADC_STOP
                duration[5]  = 125 * 10 - DC
                reVal[5] = RF_OFF
                imVal[5] = RF_OFF /* wait 10  PA to come on*/
                hwCtrl[6]  =  GA_OFF | PA_ON  | BL_ON   | ADC_STOP
                duration[6]  = pl - DC
                reVal[6] = 8100
                imVal[6] = RF_OFF /* TX=8100 90 pulse us*/
                hwCtrl[7]  =  GA_OFF | PA_OFF | BL_ON   | ADC_STOP
                duration[7]  = d1
                reVal[7] = RF_OFF
                imVal[7] = RF_OFF /* tau corr for pulse warmup*/
                hwCtrl[8]  =  GA_OFF | PA_OFF | BL_OFF  | ADC_STOP
                duration[8]  = gradientL - DC
                reVal[8] = RF_OFF
                imVal[8] = RF_OFF
                hwCtrl[9]  =  GA_OFF | PA_OFF | BL_OFF  | ADC_STOP
                duration[9]  = d2
                reVal[9] = RF_OFF
                imVal[9] = RF_OFF /* tau corr for pulse warmup*/
                hwCtrl[10] =  GA_OFF | PA_ON  | BL_OFF  | ADC_STOP;
                duration[10] = 125 * 10 - DC
                reVal[10] = RF_OFF
                imVal[10] = RF_OFF  /* wait 10  PA warmup*/
                hwCtrl[11] =  GA_OFF | PA_ON  | BL_OFF  | ADC_STOP
                duration[11] = pl * 2 - DC
                reVal[11] = RF_OFF
                imVal[11] = 8100       /* TX=8100 90 pulse us*/
                hwCtrl[12] =  GA_ON  | PA_OFF | BL_OFF  | ADC_STOP
                duration[12] = d3 - 125 * 1000 - DC
                reVal[12] = RF_OFF
                imVal[12] = RF_OFF  /* tau corr for pulse warmup*/
                hwCtrl[13] =  GA_ON  | PA_OFF | BL_OFF  | ADC_STOP
                duration[13] = 125 * 1000 - DC
                reVal[13] = RF_OFF
                imVal[13] = RF_OFF  /* tau corr for pulse warmup*/
                hwCtrl[14] =  GA_ON  | PA_OFF | BL_OFF  | ADC_START
                duration[14] = 2 * gradientL - DC
                reVal[14] = GA_CTRL
                imVal[14] = -gAmp
                hwCtrl[15] =  GA_ON  | PA_OFF | BL_OFF  | ADC_STOP
                duration[15] = 125 * 1000 - DC
                reVal[15] = GA_CTRL
                imVal[15] = RF_OFF /* wait rpt/5*/
                hwCtrl[16] =  GA_OFF | PA_OFF | BL_OFF  | ADC_STOP
                duration[16] = 125 * 1000 - DC
                reVal[16] = RF_OFF
                imVal[16] = RF_OFF /* wait rpt/5*/
                hwCtrl[17] =  GA_OFF | PA_OFF | BL_OFF  | ADC_STOP
                duration[17] = 125 * 1 - DC
                reVal[17] = GA_CTRL
                imVal[17] = RF_OFF  /* wait rpt/5*/
            }

            func experimentSolidLiquidRatio() -> Void {
                var echoWait: Int
                if tau<900 {  /* in us*/
                    echoWait = tau - 10
                } else {
                    echoWait = 100
                }

                noInstructions = 18
                hwCtrl[0]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[0]  = 125 * 1 - DC
                reVal[0] = RF_OFF     /* wait rpt/5*/
                hwCtrl[1]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[1]  = 125 * 1 - DC
                reVal[1] = RF_OFF     /* wait rpt/5*/
                hwCtrl[2]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[2]  = 125 * 1 - DC
                reVal[2] = RF_OFF      /* wait rpt/5*/
                hwCtrl[3]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[3]  = 125 * 1 - DC
                reVal[3] = RF_OFF      /* wait rpt/5*/
                hwCtrl[4]  = PA_OFF | BL_OFF  | ADC_STOP
                duration[4]  = 125 * 1 - DC
                reVal[4] = RF_OFF     /* wait rpt/5*/
                hwCtrl[5]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[5]  = 125 * 10 - DC
                reVal[5] = RF_OFF     /* wait 10  PA to come on*/
                hwCtrl[6]  = PA_ON  | BL_ON   | ADC_STOP
                duration[6]  = pl - DC
                reVal[6] = 8100       /* TX=8100 90 pulse us*/
                hwCtrl[7]  = PA_OFF | BL_ON   | ADC_STOP
                duration[7]  = 125 * (tau - 10) - pl - DC
                reVal[7] = RF_OFF     /* tau corr for pulse warmup*/
                hwCtrl[8]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[8]  = 125 * 10 - DC
                reVal[8] = RF_OFF      /* wait 10  PA warmup*/
                hwCtrl[9]  = PA_ON  | BL_OFF  | ADC_STOP
                duration[9]  = pl - DC
                imVal[9] = 8100        /* TX=8100 90 pulse us*/
                hwCtrl[10] = PA_OFF | BL_ON   | ADC_STOP
                duration[10]  = 125 * (2 * tau - 10) - pl - DC
                reVal[10] = RF_OFF      /* 2*tau corr for pulse warmup*/
                hwCtrl[11] = PA_ON  | BL_OFF  | ADC_STOP
                duration[11]  = 125 * 10 - DC
                reVal[11] = RF_OFF      /* wait 10  PA warmup*/
                hwCtrl[12] = PA_ON  | BL_OFF  | ADC_STOP
                duration[12]  = pl * 2 - DC
                reVal[12] = 8100        /* TX=8100 180 pulse us*/
                hwCtrl[13] = PA_OFF | BL_ON   | ADC_STOP
                duration[13] = 125 * (tau - echoWait) - DC
                reVal[13] = RF_OFF     /* Wait for Echo  5ms width*/
                hwCtrl[14] = PA_OFF | BL_ON   | ADC_START
                duration[14] = 125 * noData - DC
                reVal[14] = RF_OFF     /* wait Signal Aquisition 5 ms*/
                hwCtrl[15] = PA_OFF | BL_ON   | ADC_STOP
                duration[15] = 125 * 1 - DC
                reVal[15] = RF_OFF     /* wait rpt/5*/
                hwCtrl[16] = PA_OFF | BL_ON   | ADC_STOP
                duration[16] = 125 * 1 - DC
                reVal[16] = RF_OFF    /* wait rpt/5*/
                hwCtrl[17] = PA_OFF | BL_ON   | ADC_STOP
                duration[17] = 125 * 1 - DC
                reVal[17] = RF_OFF     /* wait rpt/5*/
            }

            switch exptSelect {
            case "FID":
                experimentFID()
            case "SE":
                experimentSE()
            case "T2":
                experimentT2()
            case "T1":
                experimentT1()
            case "CPMG":
                experimentCPMG()
            case "CPMGX":
                experimentCPMGX()
            case "CPMGY":
                experimentCPMGY()
            case "MATCH":
                experimentMATCH()
            case "Prog_SAT":
                experimentPROG_SAT()
            case "ProgT2PGSE":
                experimentPROG_SAT()
            case "DiffusionX":
                experimentDiffusionX()
            case "DiffusionXX":
                experimentDiffusionXX()
            case "Diffusion":
                experimentDiffusion()
            case "Diffusion_LED":
                experimentDiffusion_LED()
            case "Solid Echo":
                experimentSolidEcho()
            case "Liquid Echo":
                experimentLiquidEcho()
            case "SolidLiquid Ratio":
                experimentSolidEcho()
            default:
                    break
            }
        
            ii = 0
            while ii < noInstructions {
                bufTrnr[2 * ii + 1] = UInt32(((hwCtrl[ii] & 0xff) << 24) | (duration[ii] & 0xffffff))
                bufTrnr[2 * ii + 2] = UInt32((reVal[ii] & 0xffff) | (imVal[ii] << 16))
                ii += 1
            }
            ii = noInstructions
            while ii < (BLKS / 2) {
                bufTrnr[2 * ii + 1] = UInt32((((PA_OFF | ADC_STOP) & 0xff) << 24) | ((125 * 1 - DC) & 0xffffff))
                bufTrnr[2 * ii + 2] = UInt32((RF_OFF & 0xffff) | ((RF_OFF & 0xffff) << 16))
                ii += 1
            }

        }
        
        func trnr() -> Bool {
            
            func canSend() -> Void {
                var nextStep = 0
                if trnrFailed || cancelled { return }
                switch sendStep {
                case 0 :
                    let cmd: [UInt32] = [1]
                    let data = convertData(input: cmd)
                    xmtSocket!.send(data: data)
                    nextStep = 1
                    iii = 0
                case 1:
                    _ = rcvr()                      // start receiver
                    if exptSelect == "PROG_SAT" {
                        delayM = progSatDelay[iii]
                        if delayM > 0 {
                            scanCounter = iii
                            updateBuf2(scanCounter)
                            let data = convertData(input: bufTrnr)
                            xmtSocket!.send(data: data)
                            nextStep = 2
                            iii += 1
                        } else {
                            nextStep = 4
                        }
                    } else {
                        updateBuf2(scanCounter)
                        let data = convertData(input: bufTrnr)
                        xmtSocket!.send(data: data)
                        if ["CPMGX", "CPMGY"].contains(exptSelect) {
                            jjj = 0
                            noFrames = noEchoes / 32
                            nextStep = 5
                        } else {
                            nextStep = 3
                        }
                    }
                case 2:
                    let data = convertData(input: bufDelay)
                    xmtSocket!.send(data: data)
                    nextStep = 1
                case 3:
                    let data = convertData(input: bufDelay)
                    xmtSocket!.send(data: data)
                    nextStep = 4
                case 4:
                    signalXmt()
                    xmtSocket!.stop()
                    nextStep = 4        // canSend should not be called again
                case 5:
                    if jjj >= noFrames {
                        nextStep = 3
                    } else {
                        let data = convertData(input: bufCPMG)
                        xmtSocket!.send(data: data)
                        jjj += 1
                        nextStep = 5
                    }
                default:
                    break
                }
                sendStep = nextStep
            }
            
            
            func didReceive(_ data: Data, _ isComplete: Bool) -> Void {
            // do nothing
            }
            
            func didFail() -> Void {
                xmtSocket!.stop()
                trnrFailed = sendStep != 4
                signalXmt()
                retResult = false
                retError = xmtSocket!.retError
            }

            sendStep = 0
            iii = 0
            xmtSocket = TcpSocket(hostName: hostName,
                                  hostPort: portNo,
                                  canSend: canSend,
                                  didReceive: didReceive,
                                  didFail: didFail)
            xmtSocket!.queue = DispatchQueue(label: "Transmit Queue", qos: .userInitiated)
            xmtSocket!.tag = "xmt"
            xmtSocket!.start()
            return true
        }
        
        func rcvr() -> Bool {
            let Cmd: [UInt32] = [0]
            
            var rcvcount = 0
            var sendStep = 0
            
            var rcvba: [UInt8]? = []
            var rcvData: [Int16] = []
            
            var byteIndex = 0
            var currentInt: UInt16 = 0
            
            var data: Data!
            
            func canSend() -> Void {
                if trnrFailed || cancelled {
                    rcvSocket!.stop()
                    signalRcv()
                } else {
                    if sendStep == 0 {
                        sendStep = 1
                        data = convertData(input: Cmd)
                        rcvSocket!.send(data: data)
                    } else {
                        rcvSocket!.receive()
                    }
                }
            }
            
            func didFail() -> Void {
                retResult = false
                retError = rcvSocket!.retError
                signalRcv()
            }
            
            func didReceive(data: Data, isComplete: Bool) {
                rcvba = [UInt8](data)
                buildIntegers()
                rcvcount += rcvba!.count
                if trnrFailed || cancelled {
                    rcvSocket!.stop()
                    signalRcv()
                } else {
                    if newResult.datapoints.count >= expectedNodeCount ||
                        ((endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / UInt64(1e9)) > UInt64(delayInSeconds * 1000000000) {
                        rcvSocket!.stop()
                        signalRcv()
                    } else {
                        if isComplete {
                            rcvSocket!.stop()
                            signalRcv()
                        } else {
                            rcvSocket!.receive()
                        }
                    }
                }
            }
            
            rcvIx = 0
            newResult.datapoints.removeAll(keepingCapacity: true)

            let expectedNodeCount = (noData + (BUFSIZE - 1)) / BUFSIZE
            let startTime = DispatchTime.now()
            var endTime = startTime
            
            func buildIntegers() -> Void {
                var arrayIndex = 0
                while arrayIndex < rcvba!.count {
                    switch byteIndex {
                    case 0:
                        currentInt  = UInt16(rcvba![arrayIndex])
                        byteIndex = 1
                    case 1:
                        currentInt |= UInt16(rcvba![arrayIndex]) << 8
                        rcvData.append(Int16(bitPattern: currentInt))
                        byteIndex = 0
                        rcvIx += 1
                        if rcvIx >= BUFSIZE {
                            newResult.datapoints.append(rcvData)
                            endTime = DispatchTime.now()
                            rcvData.removeAll(keepingCapacity: true)
                            rcvIx = 0
                        }
                        currentInt = 0
                        byteIndex = 0
                    default:
                        break
                    }
                    arrayIndex += 1
                }
            }

//            let deadline = Date().advanced(by: 0.1) // requires IOS 13
//            let deadline = Date() + 2.0
//            Thread.sleep(until: deadline)
            
            
            if trnrFailed || cancelled {
                return false
            }
            rcvSocket = TcpSocket(hostName: hostName,
                                  hostPort: portNo,
                                  canSend: canSend, didReceive: didReceive, didFail: didFail)
            rcvSocket!.queue = DispatchQueue(label: "Receive Queue", qos: .default)
            rcvSocket!.tag = "rcv"
            rcvSocket!.start()
            return rcvcount > 0
        }
        
        while rcvSCount > 0 {
            waitRcv()
        }
        while xmtSCount > 0 {
            waitXmt()
        }

        trnrFailed = false

        if !trnr() {
            retval = false
        }
    
        waitXmt()
        if cancelled {
            retval = false
            return retval
        }
        if !trnrFailed { waitRcv() }
        
        return retval
    }
    
    func experiment(_ parameters: NewParameters) -> [[Int16]]
    {
        newResult.params = parameters
        if RPInterface(params: parameters) {
            retResult = true
            return newResult.datapoints
        } else {
            if retError == "" {
                retError = "RPInterface failed"
            }
            retResult = false
            return []
        }
    }
    
    func experiment(_ paramString: String) -> [[Int16]] {
        let paramData = String(paramString).data(using: .utf8)!
        do {
            let param = try JSONDecoder().decode(NewParameters.self, from: paramData)
            return experiment(param)
        }
        catch {
            newResult.params = nil
            newResult.datapoints = []
            retError = "Malformed JSON string"
            retResult = false
            return []
        }
    }
    
}

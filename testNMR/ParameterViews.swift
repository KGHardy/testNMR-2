//
//  ParameterViews.swift
//  testNMR
//
//  Created by Ken Hardy on 17/05/2023.
//

import SwiftUI

struct ViewHeights {
    var picker: CGFloat = oniPad ? 36 : 24
    var slider: CGFloat = oniPad ? 40 : 30
    var stepper: CGFloat = oniPad ? 28 : 20
}

var vH = ViewHeights()

func sliderChanged (_ value: Float, _ index: Int) -> Void {
    switch index {
        case 2:
            gData.frequency = Int(value)
        case 3:
            gData.pulseLength = Int(value)
      //case 4:
      //    gData.pulseStep = Int(value)
        case 5:
            gData.littleDelta = Int(value)
        case 6:
            gData.bigDelta = Int(value)
        case 7:
            gData.gradient = Int(value)
        case 8:
            gData.rptTime = Int(value)
        case 9:
            gData.tauTime = Int(value)
        case 10:
            gData.tauInc = Int(value)
        case 11:
            gData.noData = Int(value)
        case 13:
            gData.delayInSeconds = Double(value)
        case 14:
            gData.tauD = Int(value)
        case 17:
            gData.noOfRuns = Int(value)
        case 18:
            gData.noOfExperiments = Int(value)
        case 19:
            gData.noOfScans = Int(value)
        default: break
    }
}

struct SliderParameter: View {
    var prompt: String
    var index : Int
    @Binding var value: Float
    var minimum : Float
    var maximum : Float
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(prompt + " " + String(format: "%3.0f", value))
                    .frame(height:16)
                Spacer()
            }
            HStack {
                Text(String(format: "%3.0f", minimum))
                    .padding(.leading, oniPad ? 50 : 5)
                Slider(value: $value, in: minimum...maximum,
                       onEditingChanged: {
                    editing in
                    if !editing {sliderChanged(value,0)}
                })
                {
                    Text(prompt)
                }
                Text(String(format: "%3.0f", maximum))
                    .padding(.trailing, oniPad ? 50 : 5)
            }
            .padding(.top, oniPad ? -10 : -20)
        }
    }
}

func pickerChanged(_ value: String, _ index: Int) -> Void
{
    switch index {
    case 0:
        gData.experiment = value
    case 1:
        gData.sample = value
    default:
        break
    }
    
}

struct PickerParameter: View {
    var prompt: String
    var index: Int
    @Binding var value: String
    var values: [String]
    
    var body: some View {
        HStack {
            Text(prompt)
                .padding(.leading, 20)
            Picker(prompt, selection: $value) {
                ForEach(values, id: \.self) { v in
                    Text(v)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: value, perform: {val in pickerChanged(value, index)})
        }
    }
}

struct IntegerParameter: View {
    @EnvironmentObject var vC: ViewControl
    var prompt: String
    var index: Int
    @Binding var value: String
    var minimum: Int
    var maximum: Int
    
    func storeValue() {
        switch index {
        case 2:
            gData.frequency = Int(value) ?? 0
        case 3:
            gData.pulseLength = Int(value) ?? 0
        case 4:
            gData.pulseStep = Int(value) ?? 0
        case 5:
            gData.littleDelta = Int(value) ?? 0
        case 6:
            gData.bigDelta = Int(value) ?? 0
        case 7:
            gData.gradient = Int(value) ?? 0
        case 8:
            gData.rptTime = Int(value) ?? 0
        case 9:
            gData.tauTime = Int(value) ?? 0
        case 10:
            gData.tauInc = Int(value) ?? 0
        case 11:
            gData.noData = Int(value) ?? 0
        case 13:
            gData.delayInSeconds = Double(value) ?? 0
        case 14:
            gData.tauD = Int(value) ?? 0
        case 17:
            gData.noOfRuns = Int(value) ?? 0
        case 18:
            gData.noOfExperiments = Int(value) ?? 0
        case 19:
            gData.noOfScans = Int(value) ?? 0
        default: break
        }
   }
   
    var body: some View {
        var ovalue = value
        HStack {
            Text("\(prompt): ")
                .padding(.leading, oniPad ? 50 : 5)
            Spacer()
            TextField("", text: $value)
                .frame(width: 120)
                .foregroundColor(.black)
                .background(Color(red:240/255, green:240/255, blue:240/255))
                .keyboardType(oniPad ? .asciiCapableNumberPad : .asciiCapable)
                .submitLabel(.done)
                .onChange(of: value, perform: {entry in
                    if entry == "" {
                        value = entry
                        ovalue = entry
                    } else {
                        let nvalue = entry.filter{$0.isNumber}
                        if let nv = Int(nvalue) {
                            if nv >= minimum && (nv <= maximum || maximum == 0) {
                                value = "\(nv)"
                                ovalue = value
                                storeValue()
                            } else {
                                value = ovalue
                            }
                        } else {
                            value = ovalue
                        }
                    }
                })
        }
        .padding(.trailing, oniPad ? 50 : 5)
    }
}

struct DoubleParameter: View {
    @EnvironmentObject var vC: ViewControl
    var prompt: String
    var index: Int
    @Binding var value: String
    var minimum: Double
    var maximum: Double
    
    func storeValue() {
        switch index {
        case 2:
            gData.frequency = Int(value) ?? 0
        case 3:
            gData.pulseLength = Int(value) ?? 0
      //case 4:
          //,17gData.pulseStep = Int(value) ?? 0
        case 5:
            gData.littleDelta = Int(value) ?? 0
        case 6:
            gData.bigDelta = Int(value) ?? 0
        case 7:
            gData.gradient = Int(value) ?? 0
        case 8:
            gData.rptTime = Int(value) ?? 0
        case 9:
            gData.tauTime = Int(value) ?? 0
        case 10:
            gData.tauInc = Int(value) ?? 0
        case 11:
            gData.noData = Int(value) ?? 0
        case 13:
            gData.delayInSeconds = Double(value) ?? 0
        case 14:
            gData.tauD = Int(value) ?? 0
        case 17:
            gData.noOfRuns = Int(value) ?? 0
        case 18:
            gData.noOfExperiments = Int(value) ?? 0
        case 19:
            gData.noOfScans = Int(value) ?? 0
        default: break
        }
   }
   
    var body: some View {
        var ovalue = value
        HStack {
            Text("\(prompt): ")
                .padding(.leading, oniPad ? 50 : 5)
            Spacer()
            TextField("", text: $value)
                .frame(width: 120)
                .foregroundColor(.black)
                .background(Color(red:240/255, green:240/255, blue:240/255))
                .keyboardType(oniPad ? .asciiCapableNumberPad : .asciiCapable)
                .submitLabel(.done)
                .onChange(of: value, perform: {entry in
                    if entry == "" {
                        value = entry
                        ovalue = entry
                    } else {
                        if let dv = Double(entry) {
                            if dv >= minimum && ( dv <= maximum && maximum > 0) {
                                value = entry
                                ovalue = entry
                            }
                            else {
                                value = ovalue
                            }
                        } else {
                            value = ovalue
                        }
                    }
                })
        }
        .padding(.trailing, oniPad ? 50 : 5)
    }
}

func stepperChanged(_ value: Int, _ index: Int) -> Void {
    switch index {
    case 2:
        gData.frequency = Int(value)
    case 3:
        gData.pulseLength = Int(value)
  //case 4:
      //gData.pulseStep = Int(value)
    case 5:
        gData.littleDelta = Int(value)
    case 6:
        gData.bigDelta = Int(value)
    case 7:
        gData.gradient = Int(value)
    case 8:
        gData.rptTime = Int(value)
    case 9:
        gData.tauTime = Int(value)
    case 10:
        gData.tauInc = Int(value)
    case 11:
        gData.noData = Int(value)
    case 13:
        gData.delayInSeconds = Double(value)
    case 14:
        gData.tauD = Int(value)
    case 17:
        gData.noOfRuns = Int(value)
    case 18:
        gData.noOfExperiments = Int(value)
    case 19:
        gData.noOfScans = Int(value)
    default:
        break
    }
}

struct StepperParameter: View {
    var prompt: String
    var index: Int
    @Binding var value: Int
    var minimum : Int
    var maximum : Int
    
    var body: some View {
        HStack {
            Stepper(prompt + " \(value)", value: $value, in: minimum...maximum)
                .onChange(of: value, perform: {val in stepperChanged(value, index)})
                .padding(.leading, oniPad ? 50 : 5)
                .padding(.trailing, oniPad ? 50 : 5)
                .frame(height: vH.stepper)
        }
        
    }
}

struct ActionButton: View {
    @EnvironmentObject var vC: ViewControl
    
    func buttonText() -> String {
        switch vC.viewName {
        case .parameters:
            return "Start"
        case .running:
            return "Running \(runData.run + 1)/\(runData.experiment + 1)/\(runData.scan + 1)"
        case .results:
            if runData.running {
                return "Running \(runData.run + 1)/\(runData.experiment + 1)/\(runData.scan + 1)"
            } else {
                return "Done"
            }
        default:
            return "Error"
        }
    }
    
    var body: some View {
        Text(buttonText())
            .foregroundColor(vC.viewName == .running ? .red : .black)
            .padding(5)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green, lineWidth: 3))
            .onTapGesture {
                switch vC.viewName {
                case .parameters:
                    vC.viewName = .running
                    doExperiment()
                case .running:
                    nmr.cancel()
                    runData.errorMsg = "Cancelled by user"
                    runData.running = false
                    vC.viewName = .parameters
                case .results:
                    if runData.running {
                        nmr.cancel()
                        runData.errorMsg = "Cancelled by user"
                        runData.running = false
                    }
                    vC.viewName = .parameters
                default:
                    vC.viewName = .parameters
                }
            }
    }
}

struct ResultButton: View {
    @EnvironmentObject var vC: ViewControl
    
    func buttonText() -> String {
        switch vC.viewResult {
        case .raw:
            return "FT"
        case .ft:
            return "Fit"
        case .fit:
            return "Raw"
        }
    }
    
    var body: some View {
        Text(buttonText())
            .foregroundColor(.black)
            .padding(5)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green, lineWidth: 3))
            .onTapGesture {
                switch vC.viewResult {
                case .raw:
                    vC.viewResult = .ft
                case .ft:
                    vC.viewResult = .fit
                case .fit:
                    vC.viewResult = .raw
                }
            }
    }
}

struct ActionButtons: View {
    @EnvironmentObject var vC: ViewControl

    var body: some View {
        if vC.viewName == .results {
            HStack {
                Spacer()
                ActionButton()
                    .padding(20)
                ResultButton()
                Spacer()
            }
        } else {
            ActionButton()
        }
    }
}

struct ExperimentView: View {
    @State var experiment: String = gData.experiment
    var body: some View {
        PickerParameter(prompt: "\(allSettings.paramMap.prompts[0])", index: 0, value: $experiment, values: gData.experiments)
            .frame(height: vH.picker)
    }
}

struct SampleView: View {
    @State var sample: String = gData.sample
    var body: some View {
        PickerParameter(prompt: "\(allSettings.paramMap.prompts[1])", index: 1, value: $sample, values: gData.samples)
            .frame(height: vH.picker)
    }
}

struct BigDeltaView: View {
    @State var bigDelta = "\(gData.bigDelta)"

    var body: some View {
        IntegerParameter(prompt: "\(allSettings.paramMap.prompts[6])", index: 6, value: $bigDelta, minimum: 0, maximum: 0)
            .frame(height: vH.slider)
    }
}

struct GradientView: View {
    @State var gradient = "\(gData.bigDelta)"

    var body: some View {
        IntegerParameter(prompt: "\(allSettings.paramMap.prompts[7])", index: 7, value: $gradient, minimum: 0, maximum: 0)
            .frame(height: vH.slider)
    }
}

struct RepeatTimeView: View {
    @State var rptTime = "\(gData.rptTime)"
    var body: some View {
        IntegerParameter(prompt: "\(allSettings.paramMap.prompts[8])", index: 8, value: $rptTime, minimum: 1, maximum: 20)
    }
}

struct NumberOfRunsView: View {
    @State var noOfRuns = gData.noOfRuns
    var body: some View {
        StepperParameter(prompt: "\(allSettings.paramMap.prompts[17])", index: 17, value: $noOfRuns, minimum: 1, maximum: 100)
    }
}

struct NumberOfExperimentsView: View {
    @State var noOfExperiments = gData.noOfExperiments
    var body: some View {
        StepperParameter(prompt: "\(allSettings.paramMap.prompts[18])", index: 18, value: $noOfExperiments, minimum: 1, maximum: 100)
    }
}

struct NumberOfScansView: View {
    @State var noOfScans = gData.noOfScans
    var body: some View {
        StepperParameter(prompt: "\(allSettings.paramMap.prompts[19])", index: 19, value: $noOfScans, minimum: 1, maximum: 100)
    }
}

struct TauTimeView: View {
    @State var tauTime = "\(gData.tauTime)"

    var body: some View {
        IntegerParameter(prompt: "\(allSettings.paramMap.prompts[9])", index: 9, value: $tauTime, minimum: 0, maximum: 0)
            .frame(height: vH.slider)
    }
}

struct TauIncView: View {
    @State var tauInc = "\(gData.tauInc)"

    var body: some View {
        IntegerParameter(prompt: "\(allSettings.paramMap.prompts[10])", index: 10, value: $tauInc, minimum: 0, maximum: 0)
            .frame(height: vH.slider)
    }
}

struct TauDView: View {
    @State var tauD = "\(gData.tauD)"

    var body: some View {
        IntegerParameter(prompt: "\(allSettings.paramMap.prompts[14])", index: 14, value: $tauD, minimum: 0, maximum: 0)
            .frame(height: vH.slider)
    }
}

struct NoDataView: View {
    @State var noData = "\(gData.noData)"

    var body: some View {
        IntegerParameter(prompt: "\(allSettings.paramMap.prompts[11])", index: 11, value: $noData, minimum: 0, maximum: 0)
            .frame(height: vH.slider)
    }
}

struct DelayInSecondsView: View {
    @State var delayInSeconds = "\(gData.delayInSeconds)"

    var body: some View {
        DoubleParameter(prompt: "\(allSettings.paramMap.prompts[13])", index: 13, value: $delayInSeconds, minimum: 0, maximum: 0)
            .frame(height: vH.slider)
    }
}


struct FrequencyView: View {
    @EnvironmentObject var vC: ViewControl
    @State var frequency = "\(viewControl.frequency)"
    var body: some View {
        IntegerParameter(prompt: "\(allSettings.paramMap.prompts[2])", index: 2, value: $vC.frequency, minimum: 0, maximum: 0)
            .frame(height: vH.slider)
            .disabled(vC.disableFrequency)
    }
}

struct PulseLengthView: View {
    @State var pulseLength = "\(gData.pulseLength)"
    var body: some View {
        IntegerParameter(prompt: "\(allSettings.paramMap.prompts[3])", index: 3, value: $pulseLength, minimum: 0, maximum: 20000)
            .frame(height: vH.slider)
    }
}

struct LittleDeltaView: View {
    @State var littleDelta = "\(gData.littleDelta)"
    var body: some View {
        IntegerParameter(prompt: "\(allSettings.paramMap.prompts[5])", index: 5, value: $littleDelta, minimum: 0, maximum: 10000000)
            .frame(height: vH.slider)
    }
}

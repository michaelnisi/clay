//===----------------------------------------------------------------------===//
//
// This source file is part of the Clay open source project
//
// Copyright (c) 2021 Michael Nisi and collaborators
// Licensed under MIT License
//
// See https://github.com/michaelnisi/clay/blob/main/LICENSE for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

private extension Double {
  func convert(fromRange: (Double, Double), toRange: (Double, Double)) -> Double {
    var value = self
    value -= fromRange.0
    value /= Double(fromRange.1 - fromRange.0)
    value *= toRange.1 - toRange.0
    value += toRange.0
    
    return value
  }
}

public struct CustomSliderComponents {
  public let barLeft: CustomSliderModifier
  public let barRight: CustomSliderModifier
  public let knob: CustomSliderModifier
}

public struct CustomSliderModifier: ViewModifier {
  enum Name {
    case barLeft
    case barRight
    case knob
  }
  
  let name: Name
  let size: CGSize
  let offset: CGFloat
  
  public func body(content: Content) -> some View {
    content
      .frame(width: size.width)
      .position(x: size.width * 0.5, y: size.height * 0.5)
      .offset(x: offset)
  }
}

public struct Slider<Component: View>: View {
  @Binding var value: Double
  var onDragChange: ((Double) -> Void)?
  var range: (Double, Double)
  var knobWidth: CGFloat?
  let viewBuilder: (CustomSliderComponents, Double) -> Component
  
  public init(
    value: Binding<Double>,
    range: (Double, Double),
    knobWidth: CGFloat? = nil,
    onDragChange: ((Double) -> Void)? = nil,
    _ viewBuilder: @escaping (CustomSliderComponents, Double) -> Component
  ) {
    _value = value
    self.range = range
    self.viewBuilder = viewBuilder
    self.knobWidth = knobWidth
    self.onDragChange = onDragChange
  }
  
  public var body: some View {
    GeometryReader { geometry in
      self.view(geometry: geometry)
    }
  }
}

private extension Slider {
  func view(geometry: GeometryProxy) -> some View {
    let frame = geometry.frame(in: .global)
    let drag = DragGesture(minimumDistance: 0).onChanged { drag in
      self.onDragChange(drag, frame)
    }
    let offsetX = self.getOffsetX(frame: frame)
    
    let knobSize = CGSize(width: knobWidth ?? frame.height, height: frame.height)
    let barLeftSize = CGSize(width: max(0, CGFloat(offsetX + knobSize.width * 0.5)), height: frame.height)
    let barRightSize = CGSize(width: max(0, frame.width - barLeftSize.width), height: frame.height)
    
    let modifiers = CustomSliderComponents(
      barLeft: CustomSliderModifier(name: .barLeft, size: barLeftSize, offset: 0),
      barRight: CustomSliderModifier(name: .barRight, size: barRightSize, offset: barLeftSize.width),
      knob: CustomSliderModifier(name: .knob, size: knobSize, offset: offsetX)
    )
    
    return ZStack { viewBuilder(modifiers, value).gesture(drag) }
  }
  
  func onDragChange(_ drag: DragGesture.Value, _ frame: CGRect) {
    let width = (knob: Double(knobWidth ?? frame.size.height), view: Double(frame.size.width))
    let xrange = (min: Double(0), max: Double(width.view - width.knob))
    var value = Double(drag.startLocation.x + drag.translation.width) // knob center x
    value -= 0.5 * width.knob // offset from center to leading edge of knob
    value = value > xrange.max ? xrange.max : value // limit to leading edge
    value = value < xrange.min ? xrange.min : value // limit to trailing edge
    value = value.convert(fromRange: (xrange.min, xrange.max), toRange: range)
    let animated = abs(self.value - value) > 0.3
    
    withAnimation(animated ? .easeOut(duration: 0.15) : .none) {
      self.value = value
      self.onDragChange?(value)
    }
  }
  
  func getOffsetX(frame: CGRect) -> CGFloat {
    let width = (knob: knobWidth ?? frame.size.height, view: frame.size.width)
    let xrange: (Double, Double) = (0, Double(width.view - width.knob))
    let result = self.value.convert(fromRange: range, toRange: xrange)
    
    return CGFloat(result)
  }
}

// MARK: - Preview

struct Preview: View {
  @State var value: Double = 30
  
  var background: Color {
    Color(red: 0.07, green: 0.07, blue: 0.12)
  }
  
  var simple: some View {
    Slider(value: $value,  range: (0, 100)) { modifiers, value in
      ZStack {
        Color.blue.cornerRadius(3).frame(height: 6).modifier(modifiers.barLeft)
        Color.blue.opacity(0.2).cornerRadius(3).frame(height: 6).modifier(modifiers.barRight)
        ZStack {
          Circle().fill(Color.white)
          Circle().stroke(Color.black.opacity(0.2), lineWidth: 2)
        }.modifier(modifiers.knob)
      }
    }.frame(height: 25)
  }
  
  var track: some View {
    Slider(value: $value, range: (0, 100), knobWidth: 0) { modifiers, value in
      ZStack {
        ZStack {
          Color.purple.modifier(modifiers.barLeft)
          Color.gray.modifier(modifiers.barRight)
          HStack {
            Text(("\(Int(self.value))")).font(.body).padding(.leading)
            Spacer()
            Text(("100")).font(.body).padding(.trailing)
          }.foregroundColor(.white)
        }.cornerRadius(.zero)
      }.cornerRadius(15)
    }.frame(height: 30)
  }
  
  var textOverlay: some View {
    Slider(value: $value, range: (0, 100), knobWidth: 0) { modifiers, value in
      ZStack {
        background
        LinearGradient(gradient: .init(colors: [background, Color.black.opacity(0.6) ]), startPoint: .bottom, endPoint: .top)
        
        Group {
          LinearGradient(gradient: .init(colors: [Color.blue, Color.purple, Color.pink ]), startPoint: .leading, endPoint: .trailing)
          LinearGradient(gradient: .init(colors: [Color.clear, background ]), startPoint: .top, endPoint: .bottom).opacity(0.15)
        }.modifier(modifiers.barLeft)
        
        Text("Custom Slider").foregroundColor(.white)
      }
      .cornerRadius(8)
    }
    .frame(height: 40)
    .padding(2)
    .background(
      // adds shadow border around entire slider (to make it appear inset)
      LinearGradient(gradient: .init(colors: [Color.gray, Color.black ]), startPoint: .bottom, endPoint: .top)
        .opacity(0.2)
        .cornerRadius(9)
    )
  }
  
  var apple: some View {
    SwiftUI.Slider(value: $value)
  }
  
  var button: some View {
    Button("Random Change") {
      withAnimation {
        value = .random(in: 0...100)
      }
    }
  }
  
  var body: some View {
    return ZStack {
      background.edgesIgnoringSafeArea(.all)
      VStack(spacing: 30) {
        Group {
          simple
          track
          textOverlay
          apple
        }
        button
        .frame(width:320)
      }
    }
  }
}

struct TrackSlider_Previews: PreviewProvider {
  static var previews: some View {
    Preview()
  }
}

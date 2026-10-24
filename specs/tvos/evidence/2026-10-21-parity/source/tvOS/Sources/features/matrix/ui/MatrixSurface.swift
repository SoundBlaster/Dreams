import MetalKit
import SwiftUI

struct MatrixSurface: UIViewRepresentable {
    let tuning: RainTuning
    let isActive: Bool
    let onFailure: () -> Void

    final class Coordinator {
        var renderer: MatrixRenderer?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero)
        view.isUserInteractionEnabled = false
        do {
            context.coordinator.renderer = try MatrixRenderer(view: view) {
                Task { @MainActor in onFailure() }
            }
            context.coordinator.renderer?.tuning = tuning
            view.isPaused = !isActive
        } catch {
            Task { @MainActor in onFailure() }
        }
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.tuning = tuning
        if view.isPaused == isActive {
            context.coordinator.renderer?.resume()
            view.isPaused = !isActive
        }
    }

    static func dismantleUIView(_ view: MTKView, coordinator: Coordinator) {
        view.isPaused = true
        view.delegate = nil
        coordinator.renderer = nil
    }
}

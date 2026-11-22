import SwiftUI

/// The "My Tree" tab: a tree drawn in code that grows a little with every reflection.
struct TreeView: View {

    @State private var viewModel: TreeViewModel

    /// App navigation, which holds the tree flow's path.
    @Environment(AppRouter.self) private var router

    @State private var camera = TreeCamera()

    /// The pinch amount at the last gesture update, so each update only applies the change since then.
    @State private var lastMagnification: CGFloat = 1

    /// The drag distance at the last gesture update, for the same reason.
    @State private var lastDragTranslation: CGSize = .zero

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: dependencies.makeTreeViewModel())
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 0) {
            header
            GeometryReader { proxy in
                TreeCanvasView(layout: viewModel.layout, camera: camera) { reflection in
                    router.treePath.append(TreeRoute.insightDetail(reflection.savedInsight, highlightedReflectionID: reflection.id))
                }
                // Only the tree blurs while loading; the stats and zoom buttons stay sharp.
                .blur(radius: viewModel.isLoading ? 12 : 0)
                .contentShape(Rectangle())
                .gesture(dragGesture(in: proxy.size))
                .simultaneousGesture(pinchGesture(in: proxy.size))
                .onTapGesture(count: 2) { location in
                    let oldScale = camera.scale
                    withAnimation(.spring(duration: 0.4)) {
                        camera.zoom(by: 2, around: location, in: proxy.size)
                    }
                    playZoomHaptic(from: oldScale, to: camera.scale)
                }
                .overlay(alignment: .bottomTrailing) {
                    TreeZoomControls(
                        onZoomIn: { zoomFromCenter(by: 1.6, in: proxy.size) },
                        onZoomOut: { zoomFromCenter(by: 1 / 1.6, in: proxy.size) },
                        onRecenter: {
                            withAnimation(.spring(duration: 0.5)) {
                                camera = TreeCamera()
                            }
                        }
                    )
                    .padding(.trailing, 16)
                    .padding(.bottom, 90)
                }
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        reflectionCount
                        waterPointsTotal
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }
            // Block touches until reflections finish loading, then fade the tree into focus.
            .allowsHitTesting(!viewModel.isLoading)
            .animation(.easeOut(duration: 0.4), value: viewModel.isLoading)
            .clipped()
        }
        .background(.appBackground)
        // Start zoomed out on the whole tree every time the tab is opened or the user comes back from a reflection.
        .onAppear {
            camera = TreeCamera()
        }
        .task {
            await viewModel.loadReflections()
        }
        .appAlert(alert: $viewModel.activeAlert)
    }

    private var header: some View {
        Text("Pocketful")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 32))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.bottom, 8)
    }

    private var reflectionCount: some View {
        let count = viewModel.reflections.count
        return HStack(spacing: 6) {
            Image(systemName: "leaf")
                .foregroundStyle(.leafShade)
            Text(count == 0 ? "Record a reflection to grow your tree" : "\(count) \(count == 1 ? "Reflection" : "Reflections")")
                .foregroundStyle(.textPrimary.opacity(0.7))
        }
        .font(.system(size: 14, weight: .medium))
        .allowsHitTesting(false)
    }

    private var waterPointsTotal: some View {
        HStack(spacing: 6) {
            Image(systemName: "drop.fill")
                .foregroundStyle(.waterBlue)
            Text("\(viewModel.waterPoints) Water Points")
                .foregroundStyle(.textPrimary.opacity(0.7))
                .contentTransition(.numericText())
                .animation(.default, value: viewModel.waterPoints)
        }
        .font(.system(size: 14, weight: .medium))
        .allowsHitTesting(false)
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                camera.pan(by: CGSize(
                    width: value.translation.width - lastDragTranslation.width,
                    height: value.translation.height - lastDragTranslation.height
                ))
                lastDragTranslation = value.translation
            }
            .onEnded { _ in
                lastDragTranslation = .zero
                settleCamera(in: size)
            }
    }

    private func pinchGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let oldScale = camera.scale
                camera.zoom(by: value.magnification / lastMagnification, around: value.startLocation, in: size)
                lastMagnification = value.magnification
                playZoomHaptic(from: oldScale, to: camera.scale)
            }
            .onEnded { _ in
                lastMagnification = 1
                settleCamera(in: size)
            }
    }

    private func zoomFromCenter(by factor: CGFloat, in size: CGSize) {
        withAnimation(.spring(duration: 0.4)) {
            camera.zoom(by: factor, around: CGPoint(x: size.width / 2, y: size.height / 2), in: size)
            camera.keepTreeInView(bounds: viewModel.layout.bounds, size: size)
        }
    }

    /// A light tick each time the zoom grows or shrinks by about 40%, and a firmer tap when it reaches the closest or farthest zoom.
    private func playZoomHaptic(from oldScale: CGFloat, to newScale: CGFloat) {
        guard oldScale != newScale else { return }
        if newScale == TreeCamera.maxScale || newScale == TreeCamera.minScale {
            HapticManager.shared.triggerImpact(style: .medium)
        } else if Self.zoomStep(for: oldScale) != Self.zoomStep(for: newScale) {
            HapticManager.shared.triggerSelection()
        }
    }

    /// Steps are evenly spaced in how zoomed-in it feels (1x, 1.4x, 2x, 2.8x, 4x...), not in raw numbers.
    private static func zoomStep(for scale: CGFloat) -> Int {
        Int((log2(scale) * 2).rounded(.down))
    }

    /// After a gesture, eases the tree back if it was dragged too far away.
    private func settleCamera(in size: CGSize) {
        withAnimation(.spring(duration: 0.4)) {
            camera.keepTreeInView(bounds: viewModel.layout.bounds, size: size)
        }
    }
}

#Preview {
    let dependencies = AppDependencies(authService: PreviewAuthService(), userService: PreviewUserService())
    TreeView(dependencies: dependencies)
        .environment(dependencies.router)
}

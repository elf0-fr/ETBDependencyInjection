import SwiftUI

/// A container view that runs a one-time bootstrapping action before displaying its content.
///
/// On first appearance, a `ProgressView` is shown while the provided `action` closure executes.
/// Once the action completes, the view transitions to displaying the wrapped `content`.
/// This is primarily intended for SwiftUI previews where dependency injection
/// or other setup must happen before the preview content can render.
struct PreviewBootstrappingView<Content: View>: View {

    @State private var hasLoaded = false

    @ViewBuilder let content: Content
    let action: () -> Void

    init(action: @escaping () -> Void, content: () -> Content) {
        self.content = content()
        self.action = action
    }

    var body: some View {
        if hasLoaded {
            content
        } else {
            ProgressView()
                .onAppear {
                    action()
                    hasLoaded = true
                }
        }
    }

}

/// A view modifier that wraps the modified view inside a ``PreviewBootstrappingView``.
///
/// This allows any view to be decorated with a bootstrapping step by using
/// the ``View/bootstrap(action:)`` modifier. The provided `action` runs once
/// before the view is displayed.
struct PreviewBootstrappingViewModifier: ViewModifier {

    let action: () -> Void

    func body(content: Content) -> some View {
        PreviewBootstrappingView {
            action()
        } content: {
            content
        }
    }

}

extension View {
    
    /// Applies a one-time bootstrapping action that runs before this view is displayed.
    ///
    /// Use this modifier in SwiftUI previews to register dependencies or perform
    /// any required setup before the preview content renders.
    ///
    /// - Parameter action: A closure executed once before the view appears.
    /// - Returns: A view that shows a loading indicator until `action` completes,
    ///   then displays the original view.
    public func bootstrap(action: @escaping () -> Void) -> some View {
        self.modifier(PreviewBootstrappingViewModifier(action: action))
    }
    
}

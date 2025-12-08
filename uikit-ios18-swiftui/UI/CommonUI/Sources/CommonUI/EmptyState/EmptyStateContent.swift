import SwiftUI

import DesignSystem

public struct EmptyStateContent: View {
    private let message: String
    private let actionTitle: String?
    private let onAction: (() -> Void)?

    public init(
        message: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.message = message
        self.actionTitle = actionTitle
        self.onAction = onAction
    }

    public var body: some View {
        VStack(spacing: DSSpacing.m) {
            Text(self.message)
                .font(.subheadline)
                .foregroundStyle(Color.dsSubtleInk)
                .multilineTextAlignment(.center)

            if let actionTitle = self.actionTitle {
                Button(actionTitle) {
                    self.onAction?()
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dsBackground)
    }
}

public struct StaleBanner: View {
    private let message: String
    private let retryTitle: String
    private let onRetry: (() -> Void)?

    public init(
        message: String,
        retryTitle: String = "다시 시도",
        onRetry: (() -> Void)? = nil
    ) {
        self.message = message
        self.retryTitle = retryTitle
        self.onRetry = onRetry
    }

    public var body: some View {
        HStack(spacing: DSSpacing.m) {
            Text(self.message)
                .font(.footnote)
                .foregroundStyle(Color.dsSubtleInk)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(self.retryTitle) {
                self.onRetry?()
            }
            .font(.footnote)
            .fixedSize()
        }
        .padding(.vertical, DSSpacing.s)
        .padding(.horizontal, DSSpacing.l)
        .background(Color.dsSurface)
        .onAppear {
            AccessibilityNotification.Announcement(self.message).post()
        }
    }
}

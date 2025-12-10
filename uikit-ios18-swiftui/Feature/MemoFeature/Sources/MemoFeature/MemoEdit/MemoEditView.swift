import SwiftUI

import DesignSystem

struct MemoEditView: View {
    let store: MemoEditStore

    @State private var draft = ""
    @State private var didFillSavedText = false
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.s) {
            Text(self.store.state.book.title)
                .dsFont(.heading)
                .foregroundStyle(Color.dsInk)
                .lineLimit(2)

            Text("내용을 모두 지우고 저장하면 메모가 삭제됩니다")
                .font(.caption)
                .foregroundStyle(Color.dsSubtleInk)

            TextEditor(text: self.$draft)
                .dsFont(.body)
                .foregroundStyle(Color.dsInk)
                .scrollContentBackground(.hidden)
                .padding(.vertical, DSSpacing.s)
                .padding(.horizontal, DSSpacing.xs)
                .background(Color.dsSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .focused(self.$isEditorFocused)
                .autocorrectionDisabled()
                .disabled(!self.store.state.isLoaded)
        }
        .padding(.top, DSSpacing.l)
        .padding(.horizontal, 20)
        .padding(.bottom, DSSpacing.l)
        .background(Color.dsBackground)
        .navigationTitle(self.store.state.isNew ? "메모 작성" : "메모 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("저장") {
                    self.save()
                }
                .disabled(!self.store.state.isLoaded || self.store.state.isSaving)
            }
        }
        .onAppear {
            self.store.send(.start)
            self.fillSavedTextIfLoaded()
        }
        .onChange(of: self.store.state.isLoaded) {
            self.fillSavedTextIfLoaded()
        }
        .alert(
            "메모를 불러오지 못했습니다",
            isPresented: self.loadFailureBinding
        ) {
            Button("다시 시도") {
                self.store.send(.retryLoad)
            }
            Button("닫기", role: .cancel) {
                self.store.send(.didDismissLoadFailure)
            }
        } message: {
            Text("저장된 메모가 있는지 확인할 수 없어 저장 버튼을 잠시 잠갔습니다. 다시 시도해 주세요.")
        }
        .alert(
            "저장하지 못했습니다",
            isPresented: self.saveFailureBinding
        ) {
            Button("다시 시도") {
                self.store.send(.didDismissSaveFailure)
                self.save()
            }
            Button("닫기", role: .cancel) {
                self.store.send(.didDismissSaveFailure)
            }
        } message: {
            Text("작성한 내용은 그대로 있습니다. 다시 시도해 주세요.")
        }
    }

    private func fillSavedTextIfLoaded() {
        guard self.store.state.isLoaded, !self.didFillSavedText else { return }
        self.didFillSavedText = true
        self.draft = self.store.state.savedText
        self.isEditorFocused = true
    }

    private func save() {
        self.isEditorFocused = false
        self.store.send(.save(self.draft))
    }

    private var loadFailureBinding: Binding<Bool> {
        Binding(
            get: { self.store.state.hasLoadFailure },
            set: { isPresented in
                if !isPresented { self.store.send(.didDismissLoadFailure) }
            }
        )
    }

    private var saveFailureBinding: Binding<Bool> {
        Binding(
            get: { self.store.state.hasSaveFailure },
            set: { isPresented in
                if !isPresented { self.store.send(.didDismissSaveFailure) }
            }
        )
    }
}

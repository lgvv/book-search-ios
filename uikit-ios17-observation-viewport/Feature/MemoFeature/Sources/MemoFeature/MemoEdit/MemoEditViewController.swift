import UIKit

import CommonUI
import DesignSystem

final class MemoEditViewController: UIViewController {

    private let store: MemoEditStore

    private var didFillSavedText = false
    private var isViewVisible = false

    private func observe() {
        store.subscribe({ $0 }) { [weak self] _, state in
            self?.updateMemo(state)
        }
        store.subscribe(\.hasSaveFailure) { [weak self] _, hasFailure in
            guard hasFailure else { return }
            self?.presentSaveFailureAlert()
        }
        store.subscribe(\.hasLoadFailure) { [weak self] _, hasFailure in
            guard hasFailure else { return }
            self?.presentLoadFailureAlert()
        }
    }

    init(store: MemoEditStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        configureContent()

        observe()

        store.send(.viewDidLoad)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        isViewVisible = true
        focusEditorIfReady()
    }

    private lazy var bookLabel: UILabel = {
        let label = UILabel()
        label.font = DSTypography.heading()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .dsInk
        label.numberOfLines = 2
        return label
    }()

    private lazy var memoTextView: UITextView = {
        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = .dsInk
        textView.backgroundColor = .dsSurface
        textView.layer.cornerRadius = 10
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.isEditable = false
        return textView
    }()

    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.text = "내용을 모두 지우고 저장하면 메모가 삭제됩니다"
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .dsSubtleInk
        label.numberOfLines = 0
        return label
    }()

    private lazy var saveBarButton = UIBarButtonItem(
        title: "저장",
        primaryAction: UIAction { [weak self] _ in
            self?.saveMemo()
        }
    )

    private func configureUI() {
        view.backgroundColor = .dsBackground
        navigationItem.rightBarButtonItem = saveBarButton

        view.addSubview(bookLabel)
        bookLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bookLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            bookLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bookLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        view.addSubview(hintLabel)
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(equalTo: bookLabel.bottomAnchor, constant: 8),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        view.addSubview(memoTextView)
        memoTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            memoTextView.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 12),
            memoTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            memoTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            memoTextView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -16)
        ])
    }
}

extension MemoEditViewController {
    private func configureContent() {
        title = "메모 작성"
        bookLabel.text = store.state.book.title
    }

    private func updateMemo(_ state: MemoEditReducer.State) {
        title = state.isNew ? "메모 작성" : "메모 수정"
        saveBarButton.isEnabled = state.isLoaded && !state.isSaving

        guard state.isLoaded, !didFillSavedText else { return }
        didFillSavedText = true
        memoTextView.text = state.savedText
        memoTextView.isEditable = true
        focusEditorIfReady()
    }

    private func focusEditorIfReady() {
        guard isViewVisible, memoTextView.isEditable else { return }
        memoTextView.becomeFirstResponder()
    }

    private func saveMemo() {
        memoTextView.resignFirstResponder()
        store.send(.save(memoTextView.text))
    }

    private func presentLoadFailureAlert() {
        presentAlert(
            Alert(
                title: "메모를 불러오지 못했습니다",
                message: "저장된 메모가 있는지 확인할 수 없어 저장 버튼을 잠시 잠갔습니다. 다시 시도해 주세요.",
                actions: [
                    AlertAction(title: "다시 시도") { [weak self] in
                        self?.store.send(.retryLoad)
                    },
                    .cancel(title: "닫기") { [weak self] in
                        self?.store.send(.didDismissLoadFailure)
                    }
                ]
            )
        )
    }

    private func presentSaveFailureAlert() {
        presentAlert(
            Alert(
                title: "저장하지 못했습니다",
                message: "작성한 내용은 그대로 있습니다. 다시 시도해 주세요.",
                actions: [
                    AlertAction(title: "다시 시도") { [weak self] in
                        guard let self else { return }
                        store.send(.didDismissSaveFailure)
                        saveMemo()
                    },
                    .cancel(title: "닫기") { [weak self] in
                        self?.store.send(.didDismissSaveFailure)
                    }
                ]
            )
        )
    }
}

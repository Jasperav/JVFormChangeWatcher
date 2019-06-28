import UIKit

// We use a class rather than a struct because structs do not support objc methods.
/// Using the composite design pattern, you can add this class as a property to your viewcontroller.
/// This class will do the following:
/// 1. detect changes in your form. If you form has changed, it will replace the top left and right
///    navigationitems to different buttons (cancel & update)
/// 2. If the user pressed the cancel button, it resets the form
/// 3. If the user presses the update button, it calles the update closure.
public class FormChangeWatcher<T: ChangeableForm, U: UIViewController> {
    
    private unowned let changeableForm: T
    private unowned let viewController: U
    
    @objc private let tappedTopRightButton: (() -> ())
    
    private let topLeftButtonTextWhenFormIsChanged: String?
    private let startedTopLeftButton: UIBarButtonItem?
    private let startedTopRightButton: UIBarButtonItem?
    private let topRightButtonState: FormChangeWatcherTopRightButtonState
    private var topLeftBarButtonItem: UIBarButtonItem!
    private var topRightBarButtonItem: UIBarButtonItem!
    
    public init(changeableForm: T,
                viewController: U,
                topRightButtonText: String = FormChangeWatcherDefaultValues.defaultTopRightButtonText,
                topLeftButtonTextWhenFormIsChanged: String? = FormChangeWatcherDefaultValues.defaultTopLeftButtonText,
                tappedTopRightButton: @escaping (() -> ())) {
        self.changeableForm = changeableForm
        self.viewController = viewController
        self.tappedTopRightButton = tappedTopRightButton
        self.topLeftButtonTextWhenFormIsChanged = topLeftButtonTextWhenFormIsChanged
        self.startedTopLeftButton = viewController.navigationItem.leftBarButtonItem
        self.startedTopRightButton = viewController.navigationItem.rightBarButtonItem
        self.topRightButtonState = topLeftButtonTextWhenFormIsChanged == nil ? .disabledWhenFormIsInvalid : .hiddenWhenFormIsNotChanged
        
        assert(changeableForm.isValid())
        
        topLeftBarButtonItem = UIBarButtonItem(title: topLeftButtonTextWhenFormIsChanged, style: .plain, target: self, action: #selector(resetValues))
        topRightBarButtonItem = UIBarButtonItem(title: topRightButtonText, style: .plain, target: self, action: #selector(_tappedTopRightButton))
        
        switch topRightButtonState {
        case .disabledWhenFormIsInvalid:
            assert(viewController.navigationItem.rightBarButtonItem == nil, "There is already a right bar button item.")
            
            showTopRightButton()
            updateTopRightButtonState()
        case .hiddenWhenFormIsNotChanged:
            break
        }
        
        changeableForm.formHasChanged = { [unowned self] (hasNewValues) in
            self.handleFormChange(hasNewValues: hasNewValues)
        }
    }
    
    public func handleFormChange(hasNewValues: Bool) {
        switch topRightButtonState {
        case .disabledWhenFormIsInvalid:
            updateTopRightButtonState()
        case .hiddenWhenFormIsNotChanged:
            if hasNewValues {
                showTopRightButton()
                showTopLeftButton()
            } else {
                hideTopLeftButton()
                hideTopRightButton()
            }
        }
    }
    
    // We can't directly call the closure in the selector, because it just doesn't work.
    @objc private func _tappedTopRightButton() {
        tappedTopRightButton()
    }
    
    @objc private func resetValues() {
        hideTopLeftButton()
        hideTopRightButton()
        
        changeableForm.resetForm()
    }
    
    private func showTopRightButton() {
        viewController.navigationItem.rightBarButtonItem = topRightBarButtonItem
    }
    
    private func showTopLeftButton() {
        viewController.navigationItem.leftBarButtonItem = topLeftBarButtonItem
    }
    
    private func hideTopRightButton() {
        viewController.navigationItem.rightBarButtonItem = startedTopRightButton
    }
    
    private func hideTopLeftButton() {
        viewController.navigationItem.leftBarButtonItem = startedTopLeftButton
    }
    
    private func updateTopRightButtonState() {
        assert(viewController.navigationItem.rightBarButtonItem != nil)
        
        topRightBarButtonItem.isEnabled = changeableForm.isValid()
    }
    
}

public enum FormChangeWatcherTopRightButtonState {
    case disabledWhenFormIsInvalid, hiddenWhenFormIsNotChanged
}

public struct FormChangeWatcherDefaultValues {
    public static var defaultTopLeftButtonText = ""
    public static var defaultTopRightButtonText = ""
}

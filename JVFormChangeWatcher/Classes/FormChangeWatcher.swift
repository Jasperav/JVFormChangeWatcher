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
    
    /// Should be [unowned self]
    @objc private let update: (() -> ())
    
    public init(changeableForm: T, viewController: U, update: @escaping (() -> ())) {
        self.changeableForm = changeableForm
        self.viewController = viewController
        self.update = update
        
        changeableForm.formHasChanged = { [unowned self] (hasNewValues) in
            self.handleFormChange(hasNewValues: hasNewValues)
        }
    }
    
    public func handleFormChange(hasNewValues: Bool) {
        if hasNewValues && viewController.navigationItem.rightBarButtonItem == nil {
            viewController.navigationItem.leftBarButtonItem = UIBarButtonItem.determineCancelButton(target: self, selector: #selector(resetValues))
            
            viewController.navigationItem.rightBarButtonItem = UIBarButtonItem.determineUpdateButton(target: self, selector: #selector(_update))
        } else if !hasNewValues {
            resetValues(keepState: true)
        }
    }
    
    // We can't directly call the closure in the selector, because it just doesn't work.
    @objc private func _update() {
        update()
    }
    
    /// Has a default value of true.
    /// When the user clicks on 'Cancel', we don't want to remain the current state.
    /// However, when the user e.g. adds a new character to his username and
    /// Later on removes that same character, the original value is equal to the new value
    /// We than want to reset everything.
    @objc private func resetValues(keepState: Bool = true) {
        viewController.navigationItem.leftBarButtonItem = nil
        viewController.navigationItem.rightBarButtonItem = nil
        
        guard !keepState else { return }
        
       changeableForm.resetForm()
    }
}

extension UIBarButtonItem {
    static func determineCancelButton(target: Any, selector: Selector) -> UIBarButtonItem {
        return UIBarButtonItem(
            title: NSLocalizedString("Cancel", comment: ""),
            style: UIBarButtonItem.Style.plain,
            target: target,
            action: selector)
    }
    
    static func determineUpdateButton(target: Any, selector: Selector) -> UIBarButtonItem {
        return UIBarButtonItem(
            title: NSLocalizedString("Update", comment: ""),
            style: UIBarButtonItem.Style.done,
            target: target,
            action: selector)
    }
}

public protocol ChangeableForm: class {
    var formHasChanged: ((_ hasNewValues: Bool) -> ())? { get set }
    func resetForm()
}

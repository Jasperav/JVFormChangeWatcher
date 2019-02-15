public protocol ChangeableForm: class {
    var formHasChanged: ((_ hasNewValues: Bool) -> ())? { get set }
    
    func resetForm()
    func isValid() -> Bool
}

public extension ChangeableForm {
    func isValid() -> Bool {
        return true
    }
}

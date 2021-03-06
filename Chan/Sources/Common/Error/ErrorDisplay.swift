//
//  ErrorDisplay.swift
//  Chan
//
//  Created by Mikhail Malyshev on 25/09/2018.
//  Copyright © 2018 Mikhail Malyshev. All rights reserved.
//

import UIKit
import RxSwift
import Moya

protocol ErrorDisplayProtocol {
    init(error: Error)
    init(error: Error, buttons: [ErrorButton])
    func show()
    func show(on vc: UIViewController?)
    var actions: PublishSubject<ErrorButton> { get }
}

enum ErrorButton: Equatable {
    case ok
    case cancel
    case retry
    
    case input(result: String?)
  case custom(title: String, style: UIAlertAction.Style)
    
    public static func == (lhs: ErrorButton, rhs: ErrorButton) -> Bool {
        return String(reflecting: lhs) == String(reflecting: rhs)
    }

}

class ErrorDisplay: ErrorDisplayProtocol {
    
    private static let disposeBag = DisposeBag()
    
    let actions: PublishSubject<ErrorButton> = PublishSubject()
    private let error: Error
    private var buttons: [ErrorButton] = []
    
    private var currentTextField: UITextField?
    
    required init(error: Error) {
        self.error = error
        if buttons.count == 0 {
            self.buttons = [.ok]
        }
    }
    
    required convenience init(error: Error, buttons: [ErrorButton]) {
        self.init(error: error)
        self.buttons = buttons
    }
    
    func show() {
        self.show(on: nil)
    }
    
    func show(on vc: UIViewController?) {
        let error = ErrorHelper(error: self.error).makeError()
        if let err = error as? ChanError {
            if err == .none {
                return
            }
            self.chanErrorDisplay(err, vc: vc)
        } else {
            let message = self.error.localizedDescription
            self.showAlertView(with: nil, message: message, vc: vc)

        }
    }
    
    func chanErrorDisplay(_ error: ChanError, vc: UIViewController? = nil) {
        
        var title = ""
        var message = ""
        
        switch error {
        case .offline:
            title = "network_error".localized
            message = "you_offline".localized
        case .notFound:
            title = "not_found_title".localized
            message = "not_found_message".localized
        case .somethingWrong(let description):
            title = "unknown_error".localized
            if let descr = description {
                message = descr
            }
        case .badProxy:
            title = "proxy_error_title".localized
            message = "proxy_error_message".localized
        case .error(let t, let description):
            title = t
            message = description
        default: break
        }
        
        self.showAlertView(with: title, message: message, vc: vc)
    }
    
    private func showAlertView(with title: String?, message: String, vc viewController: UIViewController? = nil) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        for button in self.buttons {
            switch button {
            case .ok:
                vc.addAction(UIAlertAction(title: "ОК".localized, style: .default, handler: { _ in
                    self.actions.on(.next(.ok))
                }))
            case .cancel:
                vc.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { _ in
                    self.actions.on(.next(.cancel))
                }))
            case .retry:
                vc.addAction(UIAlertAction(title: "try_again".localized, style: .default, handler: { _ in
                    self.actions.on(.next(.retry))
                }))
                
//            default: break
                
            case .input(let placeholder):
                vc.addTextField { [weak self] textFiled in
                    self?.currentTextField = textFiled
                    textFiled.placeholder = placeholder
                }
                
                vc.addAction(UIAlertAction(title: "ОК".localized, style: .default, handler: { _ in
                    self.actions.on(.next(.input(result: self.currentTextField?.text)))
                }))
              
            case .custom(let title, let style):
              vc.addAction(UIAlertAction(title: title, style: style, handler: { _ in
                self.actions.on(.next(.custom(title: title, style: style)))
              }))


            }
        }
        
        Helper.performOnMainThread {
            (viewController ?? ErrorDisplay.topViewController)?.present(vc, animated: true, completion: nil)
        }
    }
    
    @discardableResult
    static func presentAlert(with title: String?, message: String, styles: [ErrorButton] = []) -> UIViewController {
        let vc = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        for button in styles {
            switch button {
            case .ok:
                vc.addAction(UIAlertAction(title: "ОК".localized, style: .default, handler: { _ in
                }))
            case .cancel:
                vc.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { _ in
                }))
            case .retry:
                vc.addAction(UIAlertAction(title: "try_again".localized, style: .default, handler: { _ in
                }))
            default: break
                
            }
        }
        
        Helper.performOnMainThread {
            ErrorDisplay.topViewController?.present(vc, animated: true, completion: nil)
        }
        
        return vc

    }
    
    static func presentAlert(with title: String?, message: String, dismiss after: TimeInterval) {
        let vc = ErrorDisplay.presentAlert(with: title, message: message, styles: [])
        
        Single<UIViewController>
            .just(vc)
            .delay(after, scheduler: Helper.rxMainThread)
            .subscribe(onSuccess: { vc in
                vc.dismiss(animated: true, completion: nil)
            }).disposed(by: ErrorDisplay.disposeBag)
    }

    
    private static var topViewController: UIViewController? {
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            return topController
        }
        
        return nil

    }
    
    
    deinit {
        print("deinit error display")
    }
    
}

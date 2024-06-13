/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit
import WebKit

var ToolbarHandle: UInt8 = 0

extension WKWebView {
    public func addInputAccessoryView(toolbar: UIView?) {
        guard let toolbar else { return }
        objc_setAssociatedObject(self, &ToolbarHandle, toolbar, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        var candidateView: UIView?
        for view in scrollView.subviews {
            let description = String(describing: type(of: view))
            if description.hasPrefix("WKContent") {
                candidateView = view
                break
            }
        }
        guard let targetView = candidateView else { return }
        let newClass: AnyClass? = classWithCustomAccessoryView(targetView: targetView)

        guard let targetNewClass = newClass else { return }

        object_setClass(targetView, targetNewClass)
    }

    func classWithCustomAccessoryView(targetView: UIView) -> AnyClass? {
        guard targetView.superclass != nil else { return nil }
        let customInputAccesoryViewClassName = "_CustomInputAccessoryView"

        var newClass: AnyClass? = NSClassFromString(customInputAccesoryViewClassName)
        if newClass == nil {
            newClass = objc_allocateClassPair(object_getClass(targetView), customInputAccesoryViewClassName, 0)
        } else {
            return newClass
        }

        let newMethod = class_getInstanceMethod(WKWebView.self, #selector(WKWebView.getCustomInputAccessoryView))
        class_addMethod(
            newClass.self,
            #selector(getter: WKWebView.inputAccessoryView),
            method_getImplementation(newMethod!),
            method_getTypeEncoding(newMethod!)
        )

        objc_registerClassPair(newClass!)

        return newClass
    }

    @objc func getCustomInputAccessoryView() -> UIView? {
        var superWebView: UIView? = self
        while (superWebView != nil) && !(superWebView is WKWebView) {
            superWebView = superWebView?.superview
        }

        guard let webView = superWebView else { return nil }

        let customInputAccessory = objc_getAssociatedObject(webView, &ToolbarHandle)
        return customInputAccessory as? UIView
    }
}

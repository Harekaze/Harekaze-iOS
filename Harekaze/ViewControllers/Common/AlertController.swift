/**
*
* AlertViewController.swift
* Harekaze
* Created by Yuki MIZUNO on 2018/01/21.
*
* Copyright (c) 2016-2018, Yuki MIZUNO
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice,
*    this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice,
*    this list of conditions and the following disclaimer in the documentation
*     and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors
*    may be used to endorse or promote products derived from this software
*    without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
* LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
* INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
* THE POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import KOAlertController

class AlertController: KOAlertController {
	override init(_ title: String?, _ message: String?) {
		super.init(title, message)
		self.style.cornerRadius = 10
	}

	override init(_ title: String?) {
		super.init(title)
		self.style.cornerRadius = 10
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func show() {
		if let delegate = UIApplication.shared.delegate as? AppDelegate {
			delegate.window?.rootViewController?.present(self, animated: false, completion: nil)
		}
	}
}

class AlertButton: KOAlertButton {
	override init(_ type: KOTypeButton, title: String) {
		super.init(type, title: title)
		self.cornerRadius = 10
		self.backgroundColor = self.backgroundColor == .black ? UIColor(named: "main") : .white
		self.titleColor = self.titleColor == .black ? UIColor(named: "main") : .white
		self.borderColor = UIColor(named: "main")
	}
}

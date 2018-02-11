/**
*
* TimeItemGridViewCell.swift
* Harekaze
* Created by Yuki MIZUNO on 2018/01/04.
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
import G3GridView

class TimeItemGridViewCell: GridViewCell {
	@IBOutlet weak var hourLabel: UILabel!

	func setCellEntities(_ hour: Int) {
		hourLabel.text = "\(hour)"
		switch hour {
		case 0...3, 22, 23:
			hourLabel.backgroundColor = #colorLiteral(red: 0.40, green: 0.20, blue: 0.80, alpha: 1.0)
		case 4, 5, 18...23:
			hourLabel.backgroundColor = #colorLiteral(red: 0.00, green: 0.40, blue: 1.00, alpha: 1.0)
		case 6...10:
			hourLabel.backgroundColor = #colorLiteral(red: 0.00, green: 0.80, blue: 1.00, alpha: 1.0)
		case 11...14:
			hourLabel.backgroundColor = #colorLiteral(red: 1.00, green: 0.60, blue: 0.00, alpha: 1.0)
		case 15...17:
			hourLabel.backgroundColor = #colorLiteral(red: 1.00, green: 0.20, blue: 0.00, alpha: 1.0)
		default:
			hourLabel.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		}
	}
}

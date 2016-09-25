/**
 *
 * ShowDetailTransition.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/21.
 * 
 * Copyright (c) 2016, Yuki MIZUNO
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
import ARNTransitionAnimator
import Material

// MARK: - Interface

@objc protocol ShowDetailTransitionInterface {

	// MARK: - Transition view generation
	func cloneHeaderView() -> UIImageView

	// MARK: - Presentation actions
	@objc optional func presentationBeforeAction()
	@objc optional func presentationAnimationAction(_ percentComplete: CGFloat)
	@objc optional func presentationCompletionAction(_ completeTransition: Bool)

	// MARK: - Dismissal actions
	@objc optional func dismissalBeforeAction()
	@objc optional func dismissalAnimationAction(_ percentComplete: CGFloat)
	@objc optional func dismissalCompletionAction(_ completeTransition: Bool)
}

// MARK: - Animation cleation class

class ShowDetailTransition {

	class func createAnimator(_ operationType: ARNTransitionAnimatorOperation, fromVC: UIViewController, toVC: UIViewController) -> ARNTransitionAnimator {
		let animator = ARNTransitionAnimator(operationType: operationType, fromVC: fromVC, toVC: toVC)

		let sourceTransition = fromVC as? ShowDetailTransitionInterface
		let destinationTransition = toVC as? ShowDetailTransitionInterface

		// MARK: - Presentation transition
		animator.presentationBeforeHandler = { [weak fromVC, weak toVC] (containerView: UIView, transitionContext: UIViewControllerContextTransitioning) in

			// Animation initialization
			containerView.addSubview(fromVC!.view)
			containerView.addSubview(toVC!.view)

			toVC!.view.layoutSubviews()
			toVC!.view.layoutIfNeeded()


			let circleView = UIView()

			// Create transitional header image view
			let headerImageView = destinationTransition?.cloneHeaderView()

			if let headerImageView = headerImageView {
				containerView.addSubview(headerImageView)
				containerView.bringSubviewToFront(toVC!.view)
				headerImageView.image = nil

				let headerSize = headerImageView.frame.size
				let diameter = max(headerSize.width, headerSize.height)

				// Create circle view
				circleView.clipsToBounds = true
				circleView.backgroundColor = MaterialColor.grey.lighten2
				circleView.frame.size = CGSize(width: diameter, height: diameter)
				circleView.layer.cornerRadius = diameter / 2
				circleView.transform = CGAffineTransformMakeScale(0.01, 0.01)

				let size = circleView.frame.size
				circleView.frame.origin = CGPointMake((headerSize.width - size.width) / 2, (headerSize.height - size.height) / 2)
				headerImageView.addSubview(circleView)
				headerImageView.frame = toVC!.view.frame // Size change to fit to destination view
			}

			sourceTransition?.presentationBeforeAction?()
			destinationTransition?.presentationBeforeAction?()

			toVC!.view.frame.origin.y = fromVC!.view.frame.height


			// Presentation animation
			animator.presentationAnimationHandler = { (containerView: UIView, percentComplete: CGFloat) in
				circleView.transform = CGAffineTransformMakeScale(1.2, 1.2)
				toVC!.view.frame.origin.y = 0

				sourceTransition?.presentationAnimationAction?(percentComplete)
				if let destinationTransition = toVC as? ShowDetailTransitionInterface {
					destinationTransition.presentationAnimationAction?(percentComplete)
				}
			}

			// Presentation completion
			animator.presentationCompletionHandler = { (containerView: UIView, completeTransition: Bool) in
				circleView.removeFromSuperview()
				headerImageView?.removeFromSuperview()
				sourceTransition?.presentationCompletionAction?(completeTransition)
				destinationTransition?.presentationCompletionAction?(completeTransition)
			}
		}


		// MARK: - Dismissal transition

		animator.dismissalBeforeHandler = { [weak fromVC, weak toVC] (containerView: UIView, transitionContext: UIViewControllerContextTransitioning) in
			containerView.addSubview(toVC!.view)

			let headerImageView = sourceTransition?.cloneHeaderView()
			if let headerImageView = headerImageView {
				containerView.addSubview(headerImageView)
			}

			containerView.bringSubviewToFront(fromVC!.view)

			// Reset view size
			toVC!.view.frame = transitionContext.finalFrameForViewController(toVC!)

			sourceTransition?.dismissalBeforeAction?()
			destinationTransition?.dismissalBeforeAction?()

			// Dismissal animation
			animator.dismissalAnimationHandler = { (containerView: UIView, percentComplete: CGFloat) in
				if let headerImageView = headerImageView {
					// Go up
					headerImageView.frame.origin.y -= headerImageView.frame.size.height
					headerImageView.alpha = 0
				}
				sourceTransition?.dismissalAnimationAction?(percentComplete)
				destinationTransition?.dismissalAnimationAction?(percentComplete)
			}

			// Dismissal completion
			animator.dismissalCompletionHandler = { (containerView: UIView, completeTransition: Bool) in
				headerImageView?.removeFromSuperview()
				sourceTransition?.dismissalCompletionAction?(completeTransition)
				destinationTransition?.dismissalCompletionAction?(completeTransition)
			}
		}

		return animator

	}
}

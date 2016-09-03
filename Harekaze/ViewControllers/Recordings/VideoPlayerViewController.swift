/**
 *
 * VideoPlayerViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/14.
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
import Material
import MediaPlayer
import Crashlytics
import RealmSwift

class VideoPlayerViewController: UIViewController, VLCMediaPlayerDelegate {

	// MARK: - Instance fileds

	let mediaPlayer = VLCMediaPlayer()
	var program: Program!

	var externalWindow: UIWindow! = nil
	var savedViewConstraints: [NSLayoutConstraint] = []
	var seekTimeTimer: NSTimer!


	// MARK: - Interface Builder outlets

	@IBOutlet var mainVideoView: UIView!
	@IBOutlet weak var mediaToolNavigationBar: UINavigationBar!
	@IBOutlet weak var mediaControlView: UIView!
	@IBOutlet weak var videoProgressSlider: UISlider!
	@IBOutlet weak var videoTimeLabel: UILabel!
	@IBOutlet weak var volumeSliderPlaceView: MPVolumeView!
	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var backwardButton: IconButton!
	@IBOutlet weak var forwardButton: IconButton!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var seekTimeLabel: UILabel!

	// MARK: - Interface Builder actions

	@IBAction func closeButtonTapped(sender: UIButton) {
		mediaPlayer.delegate = nil
		mediaPlayer.stop()

		self.dismissViewControllerAnimated(true, completion: nil)
	}


	@IBAction func playPauseButtonTapped(sender: UIButton) {
		if mediaPlayer.playing {
			mediaPlayer.pause()
			sender.setImage(UIImage(named: "ic_play_arrow_white"), forState: .Normal)
		} else {
			mediaPlayer.play()
			sender.setImage(UIImage(named: "ic_pause_white"), forState: .Normal)
		}
	}

	@IBAction func backward10ButtonTapped() {
		changePlaybackPositionRelative(-10)
	}

	@IBAction func backwardButtonTapped() {
		changePlaybackPositionRelative(-30)
	}

	@IBAction func forward10ButtonTapped() {
		changePlaybackPositionRelative(10)
	}

	@IBAction func forwardButtonTapped() {
		changePlaybackPositionRelative(30)
	}

	@IBAction func videoProgressSliderValueChanged(sender: UISlider) {
		let time = Int(NSTimeInterval(sender.value) * program.duration)
		videoTimeLabel.text = NSString(format: "%02d:%02d", time / 60, time % 60) as String
	}

	@IBAction func videoProgressSliderTouchUpInside(sender: UISlider) {
		mediaPlayer.position = sender.value
	}


	// MARK: - View initialization

	override func viewDidLoad() {
		// Media player settings
		do {
			// Path for local media
			let documentURL = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
			let saveDirectoryPath = documentURL.URLByAppendingPathComponent(program.id)
			let localMediaPath = saveDirectoryPath.URLByAppendingPathComponent("file.m2ts")

			// Realm configuration
			var config = Realm.Configuration()
			config.fileURL = config.fileURL!.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("downloads.realm")
			config.schemaVersion = 1
			config.migrationBlock = {migration, oldSchemeVersion in
				if oldSchemeVersion < 1 {
					Answers.logCustomEventWithName("Local realm store migration", customAttributes: ["migration": migration, "old version": Int(oldSchemeVersion), "new version": 1])
				}
				return
			}

			// Find downloaded program from realm
			let predicate = NSPredicate(format: "id == %@", program.id)
			let realm = try Realm(configuration: config)

			let url: NSURL
			if realm.objects(Download).filter(predicate).first != nil && NSFileManager.defaultManager().fileExistsAtPath(localMediaPath.path!) {
				url = localMediaPath
			} else {
				let request = ChinachuAPI.StreamingMediaRequest(id: program.id)
				let urlRequest = try request.buildURLRequest()

				let components = NSURLComponents(URL: urlRequest.URL!, resolvingAgainstBaseURL: false)
				components?.user = ChinachuAPI.username
				components?.password = ChinachuAPI.password

				url = components!.URL!
			}

			let media = VLCMedia(URL: url)
			media.addOptions(["network-caching": 3333])
			mediaPlayer.drawable = self.mainVideoView
			mediaPlayer.media = media
			mediaPlayer.setDeinterlaceFilter("blend")
			mediaPlayer.delegate = self
			mediaPlayer.play()
		} catch let error as NSError {
			Answers.logCustomEventWithName("Video playback error", customAttributes: ["error": error, "file": #file, "function": #function, "line": #line])
		}

		titleLabel.text = program.fullTitle

		// Generate slider thumb image
		let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 2, height: 8))
		UIGraphicsBeginImageContextWithOptions(path.bounds.size, false, 0)
		UIColor.whiteColor().setFill()
		path.fill()
		let thumbImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		// Set slider thumb image
		videoProgressSlider.setThumbImage(thumbImage, forState: .Normal)
		volumeSliderPlaceView.hidden = true

		// Set navigation bar transparent background
		let emptyImage = UIImage()
		mediaToolNavigationBar.translucent = true
		mediaToolNavigationBar.shadowImage = emptyImage
		mediaToolNavigationBar.backgroundColor = UIColor.clearColor()
		mediaToolNavigationBar.setBackgroundImage(emptyImage, forBarMetrics: .Default)
		mediaToolNavigationBar.setBackgroundImage(emptyImage, forBarMetrics: .Compact)

		// Change volume slider z-index
		mediaToolNavigationBar.sendSubviewToBack(volumeSliderPlaceView)
		
		// Add long press gesture to forward/backward button
		backwardButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(seekBackward120)))
		forwardButton.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(seekForward3x)))

	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		// Set slider thumb image
		let thumbImage = videoProgressSlider.currentThumbImage
		for subview:AnyObject in volumeSliderPlaceView.subviews {
			if NSStringFromClass(subview.classForCoder) == "MPVolumeSlider" {
				let volumeSlider = subview as! UISlider
				volumeSlider.setThumbImage(thumbImage, forState: .Normal)
				volumeSliderPlaceView.hidden = false
				break
			}
		}

		// Save current constraints
		savedViewConstraints = self.view.constraints

		// Set external display events
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VideoPlayerViewController.screenDidConnect(_:)), name: UIScreenDidConnectNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VideoPlayerViewController.screenDidDisconnect(_:)), name: UIScreenDidDisconnectNotification, object: nil)

		// Start remote control events
		UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
		self.becomeFirstResponder()
	}


	// MARK: - View deinitialization

	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)

		// Media player settings
		mediaPlayer.delegate = nil
		mediaPlayer.stop()

		// Unset external display events
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIScreenDidConnectNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIScreenDidDisconnectNotification, object: nil)

		// End remote control events
		UIApplication.sharedApplication().endReceivingRemoteControlEvents()
		self.resignFirstResponder()
	}


	// MARK: - Device orientation configurations

	override func shouldAutorotate() -> Bool {
		return externalWindow == nil
	}

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return .All
	}


	// MARK: - First responder configuration

	override func canBecomeFirstResponder() -> Bool {
		return true
	}


	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


	// MARK: - Remote control

	override func remoteControlReceivedWithEvent(event: UIEvent?) {
		if event!.type == .RemoteControl {
			switch event!.subtype {
			case .RemoteControlPlay, .RemoteControlPause, .RemoteControlTogglePlayPause:
				self.playPauseButtonTapped(playPauseButton)
				break
			default:
				break
			}
		}
	}

	// MARK: - Media player control methods

	func changePlaybackPositionRelative(seconds: Int32) {
		if mediaPlayer.time.intValue + (seconds * 1000) < 0 || mediaPlayer.time.intValue + (seconds * 1000) > Int32(program.duration * 1000) {
			return
		}
		
		let step = Float(seconds) / Float(program.duration)
		let text: String

		if seconds < 0 {
			text = "\(seconds)"
			//mediaPlayer.jumpBackward(-seconds)
		} else {
			text = "+\(seconds)"
			//mediaPlayer.jumpForward(seconds)
		}
		// NOTE: Because of VLC implementation, jumpForward/jumpBackward are available only with offline media.
		//       (not available with streaming media). Instead, use alternative method.
		mediaPlayer.position = mediaPlayer.position + step
		
		seekTimeLabel.text = text
		seekTimeLabel.hidden = false
		seekTimeTimer?.invalidate()
		seekTimeTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(hideSeekTimerLabel), userInfo: nil, repeats: false)
		
		videoProgressSlider.value = mediaPlayer.position
		
		let time = mediaPlayer.time
		videoTimeLabel.text = time.stringValue!
	}
	
	
	func seekBackward120(gestureRecognizer: UILongPressGestureRecognizer) {
		switch gestureRecognizer.state {
		case .Began:
			changePlaybackPositionRelative(-120)
		default: break
		}
	}

	func seekForward3x(gestureRecognizer: UILongPressGestureRecognizer) {
		switch gestureRecognizer.state {
		case .Began:
			mediaPlayer.rate = 3
		case .Ended:
			mediaPlayer.rate = 1
		default: break
		}
	}
	
	func hideSeekTimerLabel() {
		self.seekTimeLabel.hidden = true
	}

	// MARK: - Media player delegate methods

	var onceToken : dispatch_once_t = 0
	func mediaPlayerTimeChanged(aNotification: NSNotification!) {
		// Only when slider is not under control
		if !videoProgressSlider.touchInside {
			let mediaPlayer = aNotification.object as! VLCMediaPlayer
			let time = mediaPlayer.time
			videoProgressSlider.value = mediaPlayer.position
			videoTimeLabel.text = time.stringValue!
		}

		// First time of video playback
		dispatch_once(&onceToken) {
			let notification = NSNotification(name: UIScreenDidConnectNotification, object: nil)
			self.screenDidConnect(notification)
		}
	}

	func mediaPlayerStateChanged(aNotification: NSNotification!) {
		updateMetadata()
	}


	// MARK: - Media metadata settings

	func updateMetadata() {
		let time = Int(NSTimeInterval(mediaPlayer.position) * program.duration)
		let videoInfo = [MPMediaItemPropertyTitle: program.title,
		                 MPMediaItemPropertyMediaType: MPMediaType.TVShow.rawValue,
		                 MPMediaItemPropertyPlaybackDuration: program.duration,
		                 MPNowPlayingInfoPropertyElapsedPlaybackTime: time,
		                 MPNowPlayingInfoPropertyPlaybackRate: mediaPlayer.rate
		]
				MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = videoInfo as? [String : AnyObject]
	}


	// MARK: - Touch events

	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		super.touchesEnded(touches, withEvent: event)

		for touch: AnyObject in touches {
			let t = touch as! UITouch

			if NSStringFromClass(t.view!.classForCoder) == "VLCOpenGLES2VideoView" {
				if self.mediaControlView.hidden || self.mediaToolNavigationBar.hidden {
					self.mediaControlView.hidden = false
					self.mediaToolNavigationBar.hidden = false
					self.statusBarHidden = false

					UIView.animateWithDuration(0.4, animations: {
						self.setNeedsStatusBarAppearanceUpdate()
						self.mediaControlView.alpha = 1.0
						self.mediaToolNavigationBar.alpha = 1.0
					})
				} else {
					self.statusBarHidden = true

					UIView.animateWithDuration(0.4, animations: {
						self.setNeedsStatusBarAppearanceUpdate()
						self.mediaControlView.alpha = 0.0
						self.mediaToolNavigationBar.alpha = 0.0
						},  completion: { finished in
							self.mediaControlView.hidden = true
							self.mediaToolNavigationBar.hidden = true
					})
				}
			}
		}
	}


	// MARK: - Status bar

	var statusBarHidden: Bool = false
	override func prefersStatusBarHidden() -> Bool {
		return statusBarHidden
	}


	override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
		return .Fade
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}


	// MARK: - External display

	func screenDidConnect(aNotification: NSNotification) {
		let screens = UIScreen.screens()
		if screens.count > 1 {
			let externalScreen = screens[1]
			let availableModes = externalScreen.availableModes

			// Set up external screen
			externalScreen.currentMode = availableModes.last
			externalScreen.overscanCompensation = .None

			// Change device orientation to portrait
			let portraitOrientation = UIInterfaceOrientation.Portrait.rawValue
			UIDevice.currentDevice().setValue(portraitOrientation, forKey: "orientation")

			if self.externalWindow == nil {
				self.externalWindow = UIWindow(frame: externalScreen.bounds)
			}

			// Set up external window
			self.externalWindow.screen = externalScreen
			self.externalWindow.hidden = false
			self.externalWindow.layer.contentsGravity = kCAGravityResizeAspect

			// Move mainVideoView to external window
			mainVideoView.removeFromSuperview()
			let externalViewController = UIViewController()
			externalViewController.view = mainVideoView
			self.externalWindow.rootViewController = externalViewController

			// Show media controls
			self.mediaControlView.hidden = false
			self.mediaToolNavigationBar.hidden = false

			UIView.animateWithDuration(0.4, animations: {
				self.mediaControlView.alpha = 1.0
				self.mediaToolNavigationBar.alpha = 1.0
			})

		}
	}

	func screenDidDisconnect(aNotification: NSNotification) {
		if self.externalWindow != nil {
			// Restore mainVideoView
			mainVideoView.removeFromSuperview()
			self.view.addSubview(mainVideoView)
			self.view.sendSubviewToBack(mainVideoView)

			// Restore view constraints
			self.view.removeConstraints(self.view.constraints)
			self.view.addConstraints(savedViewConstraints)
			
			self.externalWindow = nil
		}
	}
	
}

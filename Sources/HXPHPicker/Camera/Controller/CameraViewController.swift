//
//  CameraViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit
import CoreLocation
import AVFoundation

/// 需要有导航栏
open class CameraViewController: BaseViewController {
    
    // MARK: - Properties
    
    public weak var delegate: CameraViewControllerDelegate?
    
    /// 相机配置
    public let config: CameraConfiguration
    
    /// 相机类型
    public let type: CameraController.CaptureType
    
    /// 内部自动dismiss
    public var autoDismiss: Bool = true
    
    /// takePhotoMode = .click 拍照类型
    public var takeType: CameraBottomViewTakeType {
        bottomView.takeType
    }
    
    /// 闪光灯模式
    public var flashMode: AVCaptureDevice.FlashMode {
        cameraManager.flashMode
    }
    
    /// 设置闪光灯模式
    @discardableResult
    public func setFlashMode(_ flashMode: AVCaptureDevice.FlashMode) -> Bool {
        cameraManager.setFlashMode(flashMode)
    }
    
    public init(
        config: CameraConfiguration,
        type: CameraController.CaptureType,
        delegate: CameraViewControllerDelegate? = nil
    ) {
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        self.config = config
        self.type = type
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    lazy var previewView: CameraPreviewView = {
        let view = CameraPreviewView(
            config: config
        )
        view.delegate = self
        return view
    }()
    
    lazy var cameraManager: CameraManager = {
        let manager = CameraManager(config: config)
        manager.flashModeDidChanged = { [weak self] in
            guard let self = self else { return }
            self.delegate?.cameraViewController(self, flashModeDidChanged: $0)
        }
        return manager
    }()
    
    lazy var bottomView: CameraBottomView = {
        let view = CameraBottomView(
            tintColor: config.tintColor,
            takePhotoMode: config.takePhotoMode
        )
        view.delegate = self
        return view
    }()
    
    lazy var topMaskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(true)
        return layer
    }()
    
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.requestWhenInUseAuthorization()
        return manager
    }()
    
    var didLocation: Bool = false
    
    var currentLocation: CLLocation?
    
    var currentZoomFacto: CGFloat = 1
    
    private var requestCameraSuccess = false
    
    // MARK: - UI Components
    
    lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage("hx_camera_close".image, for: .normal)
        button.addTarget(self, action: #selector(closeButtonDidTap(_:)), for: .touchUpInside)
        button.size = button.currentImage?.size ?? .zero
        button.tintColor = .white
        button.imageView?.tintColor = .white
        return button
    }()
    
    lazy var topRightItemStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .zero
        return stackView
    }()
    
    // MARK: - Life Cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        extendedLayoutIncludesOpaqueBars = true
        
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        DeviceOrientationHelper.shared.startDeviceOrientationNotifier()
        
        if config.cameraType == .normal {
            view.addSubview(previewView)
        }
        view.addSubview(closeButton)
        view.addSubview(topRightItemStackView)
        view.addSubview(bottomView)
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            PhotoTools.showConfirm(
                viewController: self,
                title: "相机不可用!".localized,
                message: nil,
                actionTitle: "确定".localized
            ) { _ in
                self.dismiss(animated: true)
            }
            return
        }
        
        AssetManager.requestCameraAccess { isGranted in
            if isGranted {
                self.setupCamera()
            } else {
                PhotoTools.showNotCameraAuthorizedAlert(viewController: self)
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc
    func willEnterForeground() {
        if requestCameraSuccess {
            if config.cameraType == .normal {
                try? cameraManager.addMovieOutput()
            }
        }
    }
    
    // MARK: - Public
    
    func switchCameraFailed() {
        ProgressHUD.showWarning(
            addedTo: view,
            text: "摄像头切换失败!".localized,
            animated: true,
            delayHide: 1.5
        )
    }
    
    func resetZoom() {
        if config.cameraType == .normal {
            cameraManager.zoomFacto = 1
            previewView.effectiveScale = 1
        }
    }
    
    func setupCamera() {
        DispatchQueue.global().async {
            do {
                self.cameraManager.session.beginConfiguration()
                try self.cameraManager.startSession()
                var needAddAudio = false
                switch self.type {
                case .photo:
                    try self.cameraManager.addPhotoOutput()
                    self.cameraManager.addVideoOutput()
                case .video:
                    try self.cameraManager.addMovieOutput()
                    needAddAudio = true
                case .all:
                    try self.cameraManager.addPhotoOutput()
                    try self.cameraManager.addMovieOutput()
                    needAddAudio = true
                }
                if !needAddAudio {
                    self.addOutputCompletion()
                } else {
                    self.addAudioInput()
                }
            } catch {
                print(error)
                self.cameraManager.session.commitConfiguration()
                DispatchQueue.main.async {
                    PhotoTools.showConfirm(
                        viewController: self,
                        title: "相机初始化失败!".localized,
                        message: nil,
                        actionTitle: "确定".localized
                    ) { _ in
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    func addAudioInput() {
        AVCaptureDevice.requestAccess(for: .audio) { isGranted in
            DispatchQueue.global().async {
                if isGranted {
                    do {
                        try self.cameraManager.addAudioInput()
                    } catch {
                        DispatchQueue.main.async {
                            self.addAudioInputFailed()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        PhotoTools.showAlert(
                            viewController: self,
                            title: "无法使用麦克风".localized,
                            message: "请在设置-隐私-相机中允许访问麦克风".localized,
                            leftActionTitle: "取消".localized,
                            leftHandler: { alertAction in
                                self.addAudioInputFailed()
                            },
                            rightActionTitle: "设置".localized
                        ) { alertAction in
                            PhotoTools.openSettingsURL()
                        }
                    }
                }
                self.addOutputCompletion()
            }
        }
    }
    
    func addAudioInputFailed() {
        ProgressHUD.showWarning(
            addedTo: self.view,
            text: "麦克风添加失败，录制视频会没有声音哦!".localized,
            animated: true,
            delayHide: 1.5
        )
    }
    
    func addOutputCompletion() {
        if config.cameraType == .normal {
            self.cameraManager.session.commitConfiguration()
            self.cameraManager.startRunning()
            self.previewView.setSession(self.cameraManager.session)
        }
        self.requestCameraSuccess = true
        DispatchQueue.main.async {
            self.sessionCompletion()
        }
    }
    
    func sessionCompletion() {
        if config.cameraType == .normal {
            previewView.setupGestureRecognizer()
        }
        bottomView.addGesture(for: type)
        startLocation()
        
        if #available(iOS 13.0, *) {
        } else {
            previewView.removeMask()
            bottomView.hiddenTip()
            bottomView.isGestureEnable = true
        }
    }
    
    func addTopRightItems(_ items: [UIView]) {
        items.forEach {
            topRightItemStackView.addArrangedSubview($0)
        }
    }
    
    func addBottomLeftItems(_ items: [UIView]) {
        bottomView.addLeftItems(items)
    }
    
    func addBottomRightItems(_ items: [UIView]) {
        bottomView.addRightItems(items)
    }
    
    @objc open override func deviceOrientationDidChanged(notify: Notification) {
        previewView.resetOrientation()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutSubviews()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if requestCameraSuccess {
            if config.cameraType == .normal {
                cameraManager.startRunning()
            }
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        PhotoManager.shared.saveCameraPreview()
        if config.cameraType == .normal {
            cameraManager.stopRunning()
        }
    }
    
    func layoutSubviews() {
        let previewRect: CGRect
        let previewTopPadding = UIDevice.previewTopPadding
        if UIDevice.isPad || !UIDevice.isPortrait {
            if UIDevice.isPad {
                previewRect = view.bounds
            } else {
                let size = CGSize(width: view.height * 16 / 9, height: view.height)
                previewRect = CGRect(
                    x: (view.width - size.width) * 0.5,
                    y: (view.height - size.height) * 0.5 + previewTopPadding,
                    width: size.width, height: size.height
                )
            }
        } else {
            let size = CGSize(width: view.width, height: view.width / 9 * 16)
            previewRect = CGRect(
                x: (view.width - size.width) * 0.5,
                y: (view.height - size.height) * 0.5 + previewTopPadding,
                width: size.width, height: size.height
            )
        }
        if config.cameraType == .normal {
            previewView.frame = previewRect
        }
        
        let bottomHeight: CGFloat = 130
        let bottomY: CGFloat
        if UIDevice.isPortrait && !UIDevice.isPad {
            if UIDevice.isAllIPhoneX {
                bottomY = view.height - 110 - previewRect.minY
            } else {
                bottomY = view.height - bottomHeight
            }
        } else {
            bottomY = view.height - bottomHeight
        }
        bottomView.frame = CGRect(
            x: 0,
            y: bottomY,
            width: view.width,
            height: bottomHeight
        )
        closeButton.frame = CGRect(x: 30, y: UIDevice.videoTopPadding, width: 24, height: 24)
        
        let navRightStackViewWidth = view.width / 2.0
        topRightItemStackView.frame = CGRect(
            x: view.width - navRightStackViewWidth,
            y: UIDevice.videoTopPadding,
            width: navRightStackViewWidth,
            height: 24
        )
        
        if let nav = navigationController {
            topMaskLayer.frame = CGRect(
                x: 0,
                y: 0,
                width: view.width,
                height: nav.navigationBar.frame.maxY + 10
            )
        }
    }
    
    open override var prefersStatusBarHidden: Bool {
        config.prefersStatusBarHidden
    }
    open override var shouldAutorotate: Bool {
        config.shouldAutorotate
    }
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        config.supportedInterfaceOrientations
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if allowLocation && didLocation {
            locationManager.stopUpdatingLocation()
        }
        DeviceOrientationHelper.shared.stopDeviceOrientationNotifier()
    }
    
    // MARK: - Actions
    
    @objc
    private func closeButtonDidTap(_ button: UIButton) {
        delegate?.cameraViewController(didCancel: self)
        
        if autoDismiss {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc
    public func didTapFlip() {
        if config.cameraType == .normal {
            do {
                try cameraManager.switchCameras()
            } catch {
                print(error)
                switchCameraFailed()
            }
            delegate?.cameraViewController(
                self,
                didSwitchCameraCompletion: cameraManager.activeCamera?.position ?? .unspecified
            )
            if !cameraManager.setFlashMode(config.flashMode) {
                cameraManager.setFlashMode(.off)
            }
        }
        resetZoom()
    }
    
    @objc
    public func didTapUpload() {
        let config: PickerConfiguration = PhotoTools.getBRPickerConfig()
        config.languageType = .english
        
        let pickerController = PhotoPickerController(picker: config)
        pickerController.pickerDelegate = self
        pickerController.autoDismiss = false
        pickerController.modalPresentationStyle = .overFullScreen
        present(pickerController, animated: true)
    }
}

// MARK: - PhotoPickerControllerDelegate

extension CameraViewController: PhotoPickerControllerDelegate {
    
    public func pickerController(_ pickerController: PhotoPickerController, didFinishSelection result: PickerResult) {
        result.getVideoURL { [weak self] urls in
            guard let self = self, let url = urls.first else { return }
            self.openVideoEditor(with: pickerController, videoURL: url)
        }
    }
    
    public func pickerController(didCancel pickerController: PhotoPickerController) {
        pickerController.dismiss(animated: true)
    }
}

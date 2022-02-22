//
//  CameraViewController+Editor.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/31.
//

import UIKit

#if HXPICKER_ENABLE_EDITOR
extension CameraViewController: PhotoEditorViewControllerDelegate {
    func openPhotoEditor(_ image: UIImage) {
        let vc = PhotoEditorViewController(
            image: image,
            config: config.photoEditor
        )
        vc.autoBack = autoDismiss
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: false)
    }
    public func photoEditorViewController(
        _ photoEditorViewController: PhotoEditorViewController,
        didFinish result: PhotoEditResult
    ) {
        if let image = UIImage(contentsOfFile: result.editedImageURL.path) {
            didFinish(withImage: image)
        }
    }
    public func photoEditorViewController(didFinishWithUnedited photoEditorViewController: PhotoEditorViewController) {
        didFinish(withImage: photoEditorViewController.image)
    }
}
extension CameraViewController: VideoEditorViewControllerDelegate {
    
    func openVideoEditor(with nav: UINavigationController?, videoURL: URL) {
        let videoEditorViewController = VideoEditorViewController(videoURL: videoURL, config: config.videoEditor)
        videoEditorViewController.autoBack = autoDismiss
        videoEditorViewController.delegate = self
        nav?.pushViewController(videoEditorViewController, animated: true)
    }
    
    public func videoEditorViewController(
        _ videoEditorViewController: VideoEditorViewController,
        didFinish result: VideoEditResult
    ) {
        didFinish(withVideo: result.editedURL)
    }
    public func videoEditorViewController(didFinishWithUnedited videoEditorViewController: VideoEditorViewController) {
        if let videoURL = videoEditorViewController.videoURL {
            didFinish(withVideo: videoURL)
        }
    }
}
#endif

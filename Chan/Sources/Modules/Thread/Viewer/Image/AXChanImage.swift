//
//  AXChanImage.swift
//  Chan
//
//  Created by Mikhail Malyshev on 13/06/2019.
//  Copyright © 2019 Mikhail Malyshev. All rights reserved.
//

import UIKit
import RxSwift
import Alamofire

class AXChanImage: NSObject, AXPhotoProtocol {
    var imageData: Data? = nil
    weak var request: DataRequest? = nil
    private let disposeBag = DisposeBag()
    let media: MediaModel
    
    
    var image: UIImage? {
        get {
            if self.needBlur {
                return self.blurredImage
            } else {
                return self.originalImage
            }
        }
        
        set {
            
        }
    }
    
    var url: URL? {
        get {
            return self._url
        }
    }
    private(set) var _url: URL
    
    var needBlur: Bool = true
    
    var path: String {
        return self._url.absoluteString
    }
    private(set) var originalImage: UIImage?
    private(set) var blurredImage: UIImage?
    
    init(media: MediaModel, url: URL) {
        self.media = media
        self._url = url
        super.init()
        self.setupRx()
    }
    
    func update(original: UIImage) {
        self.originalImage = original
    }
    
    func update(blurred: UIImage) {
        self.blurredImage = blurred
    }
    
    private func setupRx() {
        
        if Values.shared.safeMode {
            self.needBlur = true
        } else {
            if let result = CensorManager.shared.cache[self.path] {
                self.needBlur = result
            } else {
                Helper.performOnQueue(q: QueueManager.shared.fullImageCensorAddingQueue) {
                    CensorManager
                        .shared
                        .censor(url: self.path)
                        .subscribe(onNext: { [weak self] needCensor in
                            self?.needBlur = needCensor
                        })
                        .disposed(by: self.disposeBag)
                }
            }
        }
    }
    
    
}

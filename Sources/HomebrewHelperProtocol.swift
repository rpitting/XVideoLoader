//
//  HomebrewHelperProtocol.swift
//  XVideoLoader
//  
//  Created by Reiner Pittinger on 13.04.26
//  Copyright © 2026 . All rights reserved.
    
import Foundation

@objc protocol HomebrewHelperProtocol {
    func isInstalled(_ programName: String, reply: @escaping (Bool) -> Void)

    func download(
        url: String,
        cookiesFilePath: String?,
        reply: @escaping (_ filepath: String?, _ errorMessage: String?) -> Void
    )
}
@objc protocol HomebrewHelperClientProtocol {
    func downloadProgress(_ percent: Double)
}


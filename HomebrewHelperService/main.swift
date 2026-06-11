//
//  main.swift
//  XVideoLoader
//  
//  Created by Reiner Pittinger on 13.04.26
//  Copyright © 2026 ___ORGANIZATIONNAME___. All rights reserved.
    

import Foundation

let delegate = Delegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()

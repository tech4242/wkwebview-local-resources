//
//  ViewController.swift
//  LocalWKWebView
//
//  Created by Nikolay Dimolarov on 08.02.18.
//  Copyright © 2018 Nikolay Dimolarov. All rights reserved.
//

import UIKit
import WebKit
import Alamofire
import Zip

class ViewController: UIViewController, WKNavigationDelegate {
    
    /*
     Used to download and unzip the zip file with the custom CSS, JS
     */
    func downloadFile(completionHandler: @escaping (URL?, Error?) -> ()) {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("custom_css_js.zip")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        let downloadURL = "https://github.com/tech4242/wkwebview-local-resources/raw/master/custom_css_js.zip"
        let downloadParameters : Parameters = ["":""]
        
        Alamofire.download(downloadURL, method: .get, parameters: downloadParameters, encoding: JSONEncoding.default, to: destination)
            .downloadProgress { progress in
                print("Download Progress: \(progress.fractionCompleted)")
            }
            .response(completionHandler: { (DefaultDownloadResponse) in
                if DefaultDownloadResponse.response?.statusCode == 200 {
                    
                    let fm = FileManager.default
                    let documentsURL = try! fm.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let fileURL = documentsURL.appendingPathComponent("custom_css_js.zip")
                    
                    if(fm.fileExists(atPath: fileURL.path)) {
                        print("Download complete at: \(fileURL.absoluteString)")
                        do {
                            try Zip.unzipFile(fileURL, destination: documentsURL, overwrite: true, password: "", progress: { (progress) -> () in
                                print("Unzip Progress: \(progress)")
                            })
                            completionHandler(fileURL, nil)
                        }
                        catch {
                            print("Couldn't unzip")
                            completionHandler(nil, error)
                        }
                    }
                }
            })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // enable JavaScript via config & setup webView
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        let webView = WKWebView(frame: view.bounds, configuration: configuration)
        
        let loadCustomFiles = true
        
        if(loadCustomFiles) {
            // download & load custom files from remote URL
            downloadFile(completionHandler: { url, error in
                if(url != nil) {
                    let folderURL = url?.deletingPathExtension()
                    let htmlPath = folderURL?.appendingPathComponent("custom.html").path
                    let folderPath = folderURL?.path
                    print(folderPath)
                    let baseUrl = URL(fileURLWithPath: folderPath!, isDirectory: true)
                    print(baseUrl)
                    let htmlURL = URL(fileURLWithPath: htmlPath!, isDirectory: false)
                    webView.loadFileURL(htmlURL, allowingReadAccessTo: folderURL!)
                    webView.navigationDelegate = self
                    self.view = webView
                } else {
                    print(error)
                }
            })
        } else {
            // load normal files from /web
            let htmlPath = Bundle.main.path(forResource: "index", ofType: "html")
            let folderPath = Bundle.main.bundlePath
            let baseUrl = URL(fileURLWithPath: folderPath, isDirectory: true)
            do {
                let htmlString = try NSString(contentsOfFile: htmlPath!, encoding: String.Encoding.utf8.rawValue)
                webView.loadHTMLString(htmlString as String, baseURL: baseUrl)
                webView.navigationDelegate = self
                self.view = webView
            } catch {
                // error handling
            }
        }
    }
    
    /*
     Alternative solution with webView.loadFileURL():
     
     override func viewDidLoad() {
     super.viewDidLoad()
     let webView = WKWebView()
     let htmlPath = Bundle.main.path(forResource: "index", ofType: "html")
     let htmlUrl = URL(fileURLWithPath: htmlPath!, isDirectory: false)
     webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
     webView.navigationDelegate = self
     view = webView
     }
     */
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


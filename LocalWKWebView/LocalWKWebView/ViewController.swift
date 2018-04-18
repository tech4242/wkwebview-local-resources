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
    func downloadFile() {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("custom_css_js.zip")
            print(fileURL)
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        let downloadURL = "https://github.com/tech4242/wkwebview-local-resources/blob/master/custom_css_js.zip"
        let downloadParameters : Parameters = ["":""]
        
        Alamofire.download(downloadURL, method: .get, parameters: downloadParameters, encoding: JSONEncoding.default, to: destination)
            .downloadProgress { progress in
                print("Download Progress: \(progress.fractionCompleted)")
            }
            .response { response in
                print("HTTP Code: \(String(describing: response.response?.statusCode))")
                do {
                    let fm = FileManager.default
                    let documentsURL = try! fm.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let fileURL = documentsURL.appendingPathComponent("custom_css_js.zip")
                    print(fileURL)
                    print(documentsURL)
                    
                    try Zip.unzipFile(fileURL, destination: documentsURL, overwrite: true, password: "", progress: { (progress) -> () in
                        print(progress)
                    })
                }
                catch {
                    print("Something went wrong")
                }
            }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadFile()
        // enable JavaScript via config
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        // setup webView with config and load local HTML file
        let webView = WKWebView(frame: view.bounds, configuration: configuration)
        let htmlPath = Bundle.main.path(forResource: "index", ofType: "html")
        let folderPath = Bundle.main.bundlePath
        let baseUrl = URL(fileURLWithPath: folderPath, isDirectory: true)
        do {
            let htmlString = try NSString(contentsOfFile: htmlPath!, encoding: String.Encoding.utf8.rawValue)
            webView.loadHTMLString(htmlString as String, baseURL: baseUrl)
        } catch {
            // catch error
        }
        webView.navigationDelegate = self
        view = webView
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


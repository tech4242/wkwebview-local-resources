# wkwebview-local-resources
iOS project with a WKWebView that loads local resources, based on one of my SO answers.

### Currently supported:
* Local HTML, CSS and JS files
* Remote HTML, CSS and JS files (as requested by edon2005):
  1) downloading a zip & unzipping (Alamofire + Zip)
  2) Loading those unzipped files that are saved in /Documents/ in the WKWebView - HTML, CSS and JS

### How to use:

1. Clone project
2. `pod install`
3. In `ViewController.swift` on LOC 66 `let loadCustomFiles = true` is used to decide whether to download the zip and load its contents into WKWebView or to load the local /web folder in the Bundle. So changes this accordingly. *I was thinking of making this option a new ViewController with 2 options where you can segue to the right WKWebView but this project should just showcase the functionality and UX stuff is not really needed.*

### Still to do:
* identical project for macOS

### Based on:
https://stackoverflow.com/questions/39336235/wkwebview-does-load-resources-from-local-document-folder/39459878#39459878


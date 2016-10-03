//
//  AppDelegate.swift
//  progA2
//
//  Created by Ashley Midgley on 9/22/16.
//  Copyright © 2016 Ashley Midgley. All rights reserved.
//

import Cocoa
import Quartz

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var ourPDF: PDFView!
    var pages = 0
    var docs = [NSURL]()
    var docIndex = 0
    var loaded = false
    
    @IBOutlet weak var toolbarBox: NSBox!
    
    @IBOutlet weak var thumbnailView: PDFThumbnailView!
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var subtitleLabel: NSTextField!
    
    @IBOutlet weak var headerLabel: NSTextField!
    @IBOutlet weak var currentDocLabel: NSTextField!
    
    @IBOutlet weak var currentPageNoLabel: NSTextField!
    @IBOutlet weak var goToPageNoField: NSTextField!
    
    @IBOutlet weak var prevDocButton: NSButton!
    @IBOutlet weak var nextDocButton: NSButton!

    @IBOutlet weak var textSearchField: NSSearchField!
    @IBOutlet weak var casesLabel: NSTextField!
    @IBOutlet weak var searchCasesStepper: NSStepper!
    var currStepperVal = 0
    var results = [AnyObject]()
    let highlightColor = NSColor(red: 1, green: 1, blue: 0, alpha: 1)
    
    /*
    @IBOutlet weak var bookmarksView: NSScrollView!
    var bookmarks = [NSTextField]()
    var bookmarkNo = [Int]()
    */
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        thumbnailView.setPDFView(ourPDF)
        //thumbnailView.set
        //let thumbSize = NSSize(width: , height: )
       // thumbnailView.setThumbnailSize(thumbSize)
        
        
        prevDocButton.hidden = true
        nextDocButton.hidden = true
        searchCasesStepper.hidden = true
        
        //Need to know when the user clicks on the annotation so we can input keyboard text to annotation field
        //@”PDFAnnotationHit”
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBAction func choosePDF(sender: NSButton) {
        //NSWorkspace.sharedWorkspace().selectFile(nil, inFileViewerRootedAtPath: "/Home")
        let fileChooser = NSOpenPanel();
        fileChooser.title = "Choose a .pdf file";
        fileChooser.showsResizeIndicator = true;
        fileChooser.showsHiddenFiles = false;
        fileChooser.canChooseDirectories = false;
        fileChooser.canCreateDirectories = true;
        fileChooser.allowsMultipleSelection = true;
        fileChooser.allowedFileTypes = ["pdf"];
        
        if(fileChooser.runModal() == NSModalResponseOK) {
            self.docs = fileChooser.URLs
            //let path = result!.path!
            self.loaded = true
            titleLabel.hidden = true
            subtitleLabel.hidden = true
            setPDF(docs[0])
            headerLabel.stringValue = "Current Document:"
            if(docs.count > 1){
                prevDocButton.hidden = false
                nextDocButton.hidden = false
            }
        }else{
            //User clicked on "Cancel"
            return
        }
    }
    
    func setPDF(url: NSURL){
        let pdf = PDFDocument(URL: url)
        ourPDF.setDocument(pdf)
        pages = pdf.pageCount()
        
        let timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(self.updateLabels), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    func updateLabels(){
        currentPageNoLabel.stringValue = "Page \(ourPDF.document().indexForPage(ourPDF.currentPage())+1) of \(pages)"
        let pathC = docs[docIndex].pathComponents!
        currentDocLabel.stringValue = "\(pathC[pathC.count-1])"
        if textSearchField.stringValue == "" || results.isEmpty {
            casesLabel.stringValue.removeAll()
            ourPDF.setHighlightedSelections(nil)
        }else{
            casesLabel.stringValue = "Case \(currStepperVal+1) of \(results.count)"
        }
    }

    @IBAction func previousPage(sender: NSButton) {
        if(ourPDF.canGoToPreviousPage()){
            ourPDF.goToPreviousPage(self)
        }
    }
    
    @IBAction func nextPage(sender: NSButton) {
        if(ourPDF.canGoToNextPage()){
            ourPDF.goToNextPage(self)
        }
    }
    
    @IBAction func previousDocument(sender: NSButton) {
        if !docs.isEmpty {
            if(docIndex != 0){
                docIndex -= 1
                setPDF(docs[docIndex])
            }
        }
    }
    
    @IBAction func nextDocument(sender: NSButton) {
        if !docs.isEmpty {
            if(docIndex != docs.count-1){
                docIndex += 1
                setPDF(docs[docIndex])
            }
        }
    }
    
    @IBAction func zoomOut(sender: NSButton) {
        if(ourPDF.canZoomOut()){
            ourPDF.zoomOut(self)
        }
    }
    
    @IBAction func zoomIn(sender: NSButton) {
        if(ourPDF.canZoomIn()){
            ourPDF.zoomIn(self)
        }
    }
    
    @IBAction func zoomToFit(sender: NSButton) {
        ourPDF.setScaleFactor(CGFloat(1.0))
    }
    
    @IBAction func goToPage(sender: NSButton) {
        let pageNo = Int(goToPageNoField.stringValue)
        if pageNo != nil && pageNo <= pages{
            ourPDF.goToPage(ourPDF.document().pageAtIndex(pageNo!-1))
            goToPageNoField.stringValue.removeAll()
        }
    }
    
    @IBAction func textSearch(sender: NSSearchField) {
        if loaded {
            if textSearchField.stringValue != "" {
                self.results = ourPDF.document().findString(textSearchField.stringValue, withOptions: 1)
                if !results.isEmpty {
                    casesLabel.hidden = false
                    searchCasesStepper.hidden = false
                    for s in results {
                        s.setColor(highlightColor)
                    }
                    ourPDF.setHighlightedSelections(results)
                    ourPDF.goToSelection(results[0] as! PDFSelection)
                }
            }else{
                searchCasesStepper.hidden = true
            }
        }
    }
    
    @IBAction func changeSearchCase(sender: NSStepper) {
        let stepVal = searchCasesStepper.intValue
        let cStepVal = Int32(currStepperVal)
        if stepVal < cStepVal && currStepperVal != 0{
            //moving backwards
            currStepperVal -= 1
            ourPDF.goToSelection(results[currStepperVal] as! PDFSelection)
        }else if stepVal > cStepVal && currStepperVal != results.count-1{
            //moving upwards
            currStepperVal += 1
            ourPDF.goToSelection(results[currStepperVal] as! PDFSelection)
        }
    }

    @IBAction func addAnnotation(sender: NSButton) {
        if loaded {
            let annotation = PDFAnnotationText()
            let rect = NSRect(x: 5, y: 5, width: 40, height: 40)
            annotation.setShouldDisplay(true)
            annotation.setBounds(rect)
            ourPDF.currentPage().addAnnotation(annotation)
        }
    }

    /*
    @IBAction func addBookmark(sender: NSButton) {
        let currPage = ourPDF.document().indexForPage(ourPDF.currentPage())+1
        let fieldRect = NSRect(x: 5, y: 10*(2*bookmarks.count), width: 100, height: 20)
        let bookmark = NSTextField(frame: fieldRect)
        bookmark.stringValue = "\(currentDocLabel.stringValue): P\(currPage)"
        bookmark.editable = false

        if !bookmarkNo.contains(currPage){
            bookmarkNo.append(currPage)
            bookmarks.append(bookmark)
            for b in bookmarks {
                bookmarksView.addSubview(b)
            }
            bookmarksView.updateLayer()
        }
    }
 */
}


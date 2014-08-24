//
//  AppDelegate.swift
//  HB2Pocket
//
//  Created by 十亀 眞怜 on 2014/08/24.
//  Copyright (c) 2014年 Masato Sogame. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSXMLParserDelegate {
                            
    @IBOutlet weak var window: NSWindow!
    
    @IBOutlet weak var HBAtomFileField: NSTextFieldCell!
    @IBOutlet weak var HBAtomFileChooseButton: NSButton!
    @IBOutlet weak var ConvertProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var ConvertButton: NSButton!
    
    var entries: [HBEntry]? = [];
    var tmpEntry: HBEntry?;
    var parseKey: NSString?;

    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        //Disable convert button.
        ConvertButton.enabled = false;
        PocketAPI.sharedAPI().consumerKey = CONSUMER_KEY;
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication!) -> Bool {
        return true;
    }


    // MARK: - IBAction
    
    @IBAction func ChooseButtonPressed(sender: AnyObject) {
        //Open File Chooser
        let openPanel:NSOpenPanel = NSOpenPanel();
        openPanel.canChooseFiles = true;
        openPanel.canChooseDirectories = false;
        openPanel.resolvesAliases = true;
        openPanel.runModal();
        //Get selected file URL.
        var choosenFile = openPanel.URL
        if let fileUrl = choosenFile {
            HBAtomFileField.title = fileUrl.absoluteString;
            ConvertButton.enabled = true;
        } else {
            ConvertButton.enabled = false;
        }
    }
    
    
    @IBAction func ConvertButtonPressed(sender: AnyObject) {
        //Process fileData.
        let parser:NSXMLParser = NSXMLParser(contentsOfURL: NSURL(string: HBAtomFileField.title!))
        parser.delegate = self;
        parser.parse()
    }
    
    // MARK: - NSXMLParser Delegate methods
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError!) {
        NSLog("ParseError: %@", parseError);
    }
    
    func parserDidStartDocument(parser: NSXMLParser) {
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {
        if elementName == "entry" {
            tmpEntry = HBEntry();
        } else if (elementName == "link") {
            if let rel:AnyObject = attributeDict["rel"]{
                if rel as String == "related" {
                    if let href:AnyObject = attributeDict["href"] {
                        tmpEntry?.url = href as String;
                    }
                }
            }
        } else {
            parseKey = elementName;
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        if elementName == "entry" {
            entries?.append(tmpEntry!)
        }
    }
    func parser(parser: NSXMLParser, foundCharacters string: String!) {
        if parseKey? == "title" {
            if let te = tmpEntry {
                if let currentTitle = te.title {
                    te.title = currentTitle + string
                } else {
                    te.title = string;
                }
            }
        } else if parseKey? == "link" {
            if let te = tmpEntry {
                te.url = string;
            }
        } else if parseKey? == "dc:subject" {
            tmpEntry?.tags?.append(string);
        }
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        if let entries = self.entries {
            ConvertProgressIndicator.minValue = 0;
            ConvertProgressIndicator.maxValue = Double(entries.count);
        }
        PocketAPI.sharedAPI().loginWithHandler { (api, err) -> Void in
            if api.loggedIn {
                let httpMethod = PocketAPIHTTPMethodPOST;
                let apiMethod = "send";
                var actions:[Dictionary<String, String>] = [];
                self.ConvertProgressIndicator.doubleValue = 0;
                self.ConvertProgressIndicator.startAnimation(self);
                for (idx, item) in enumerate(self.entries!) {
                    if var entryDic = item.toPocketAPIEntry() {
                        entryDic["action"] = "add";
                        actions.append(entryDic);
                        self.ConvertProgressIndicator.incrementBy(1);
                    }
                }
                var argument = ["actions": actions];

                api.callAPIMethod(apiMethod,
                    withHTTPMethod: httpMethod,
                    arguments: argument,
                    handler: { (api, apimethod, response, err) -> Void in
                        if err != nil {
                            NSLog("Err: \(err)");
                        }
                        self.ConvertProgressIndicator.stopAnimation(self);
                });
            }
        }
    }
}


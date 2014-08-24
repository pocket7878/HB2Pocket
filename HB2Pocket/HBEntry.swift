//
//  HBEntry.swift
//  HB2Pocket
//
//  Created by 十亀 眞怜 on 2014/08/24.
//  Copyright (c) 2014年 Masato Sogame. All rights reserved.
//

import Foundation

class HBEntry: NSObject {
    var title:NSString?;
    var url:NSString?;
    var tags:[NSString]?;
    
    override init () {
        super.init()
        self.tags = [];
    }
    
    func toPocketAPIEntry() -> Dictionary<String, String>? {
        if self.title != nil && self.url != nil  && self.tags != nil {
            NSLog("Non empty entry");
            var dic = Dictionary<String, String>();
            dic["title"] = self.title!;
            dic["url"] = self.url!;
            var tagStr = "";
            for (idx, item) in enumerate(self.tags!) {
                if idx > 0 {
                    tagStr += ",";
                }
                tagStr += item;
            }
            dic["tags"] = tagStr;
            return dic;
        } else {
            NSLog("Empty entry");
            if self.title == nil {
                NSLog("Title is empty");
            }
            if self.url == nil {
                NSLog("URL is empty");
            }
            if self.tags == nil {
                NSLog("Tags is empty");
            }
            return nil;
        }
    }
}

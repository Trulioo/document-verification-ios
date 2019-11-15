//
//  TruliooSampleApp
//
//  Created by Trulioo on 2019-11-13.
//  Copyright © 2019 Trulioo. All rights reserved.
//

import Foundation
import UIKit

public struct PiiInfo{
    public let firstName:String
    public let lastName:String
    public let countryCode:String
    public let documentType:String
    
    public let frontImage:UIImage
    public let backImage:UIImage?
    public let liveImage:UIImage?
}

class DocumentVerificationRequest: Codable{
    var AcceptTruliooTermsAndConditions: Bool = true
    var ConfigurationName:String = "Identity Verification"
    var CountryCode:String
    var DataFields:DataFields
    
    init(countryCode:String, dataFields:DataFields){
        self.CountryCode = countryCode
        self.DataFields = dataFields
    }
}

class DataFields: Codable{
    var PersonInfo: PersonInfo
    var Document: Document
    
    init(personInfo: PersonInfo, documentInfo: Document){
        self.PersonInfo = personInfo
        self.Document = documentInfo
    }
}

class PersonInfo: Codable{
    var FirstGivenName:String?
    var FirstSurName:String?
    
    init(piiInfo:PiiInfo){
        self.FirstGivenName = piiInfo.firstName
        self.FirstSurName = piiInfo.lastName
    }
}

class Document: Codable{
    var DocumentFrontImage:String?
    var DocumentBackImage:String?
    var LivePhoto:String?
    var DocumentType:String?
    
    init(frontImage:String, backImage:String?, livePhoto:String?, documentType:String){
        self.DocumentType = documentType
        self.DocumentFrontImage = frontImage
        if(backImage != nil){
            self.DocumentBackImage = backImage
        }
        if(livePhoto != nil){
            self.LivePhoto = livePhoto
        }
    }
}

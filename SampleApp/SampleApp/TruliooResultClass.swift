//
//  TruliooSampleApp
//
//  Created by Trulioo on 2019-11-13.
//  Copyright © 2019 Trulioo. All rights reserved.
//

import Foundation

struct VerifyResult: Codable{
    let TransactionID:String
    let UploadedDt:String
    let CountryCode:String
    let ProductName:String
    let Record:Record
    let Errors:[ServerError]
}

struct Record: Codable{
    let TransactionRecordID:String
    let RecordStatus:String
    let DatasourceResults:[DatasourceResult]
    let Errors:[ServerError]
    let Rule:RecordRule
}

struct ServerError: Codable{
    let Code:String
    let Message:String
}

struct DatasourceResult: Codable{
    let DatasourceName:String
    let DatasourceFields:[DatasourceField]
    let AppendedFields:[AppendedField]
    let Errors:[ServerError]
    let FieldGroups:[String]
}

struct RecordRule: Codable{
    let RuleName:String
    let Note:String
}

struct DatasourceField: Codable{
    var FieldName:String
    var Status:String
}

struct AppendedField: Codable{
    var FieldName:String
    var Data:String
}

struct AuthenticityDetail: Codable{
    var Name:String
    var IsValid:Bool
    var Value:String
    var DocumentId:String
    var Description:String
    var Source:String
    var Properties:String
}

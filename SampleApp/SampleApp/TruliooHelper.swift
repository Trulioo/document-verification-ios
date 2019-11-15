//
//  TruliooSampleApp
//
//  Created by Trulioo on 2019-11-13.
//  Copyright © 2019 Trulioo. All rights reserved.
//

import Foundation
import UIKit

enum APIError: Error{
    case DataError(String)
    case ServerError(String)
    case JSONError(String)
    case UnknownError(String)
}

let maxImageSize = 4 * 1024 * 1024

public class TruliooHelper{
    
    let username = ""
    let password = ""
    
    let basePath = "https://api.globalgateway.io/"
    let testAuthenticationPath = "connection/v1/testauthentication"
    let verificationPath = "verifications/v1/verify"
    
    func TestAuthentication(onSuccess:@escaping(Data, Int, HTTPURLResponse?) -> Void, onFailure:@escaping(Error, Int, URLResponse?) -> Void){
        
        let urlRequest = getUrlRequest(url: basePath+testAuthenticationPath, isPost: false)
        if(urlRequest == nil){
            onFailure(APIError.UnknownError("Unable to read the url"), -1, nil)
            return
        }

        let task = URLSession.shared.dataTask(with: urlRequest!) { (data, response, error) in
            if let error = error{
                if let response = response as? HTTPURLResponse{
                    onFailure(error, response.statusCode, response)
                    return
                }
                onFailure(error, -1, response)
                return
            }
            if let response = response as? HTTPURLResponse{
                if(response.statusCode != 200){
                    if let errorData = data, let errorString = String(data:errorData, encoding: .utf8){
                        onFailure(APIError.ServerError(errorString),response.statusCode, response)
                    }
                    else{
                        onFailure(APIError.ServerError("Unknown server error, check response for detail"),response.statusCode, response)
                    }
                }
                else{
                    if let data = data{
                        onSuccess(data,response.statusCode, response)
                    }
                    else{
                        onFailure(APIError.ServerError("Unknown server error, check response for detail"),response.statusCode, response)
                    }
                }
            }
            else{
                onFailure(APIError.ServerError("Unknown server error, check response for detail"), -1, response)
            }
        }
        task.resume()
    }
    
    func verify(piiInfo: PiiInfo, onSuccess:@escaping(Data, Int, HTTPURLResponse?) -> Void, onFailure:@escaping(Error, Int, URLResponse?) -> Void){
        
        var urlRequest = getUrlRequest(url: basePath+verificationPath, isPost: true)
        if(urlRequest == nil){
            onFailure(APIError.UnknownError("Unable to read the url"), -1, nil)
            return
        }
        
        urlRequest!.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let request = getVerifyRequest(piiInfo: piiInfo)
        do{
            let jsongString = try JSONEncoder().encode(request)
            urlRequest!.httpBody = jsongString
        }catch{
            onFailure(APIError.JSONError("Unable to create JSON request"),-1, nil)
            return
        }
        let task = URLSession.shared.dataTask(with: urlRequest!) { (data, response, error) in
            if let error = error{
                if let response = response as? HTTPURLResponse{
                    onFailure(error, response.statusCode, response)
                    return
                }
                onFailure(error, -1, response)
                return
            }
            if let response = response as? HTTPURLResponse{
                if(response.statusCode != 200){
                    if let errorData = data, let errorString = String(data:errorData, encoding: .utf8){
                        onFailure(APIError.ServerError(errorString),response.statusCode, response)
                    }
                    else{
                        onFailure(APIError.ServerError("Unknown server error, check response for detail"),response.statusCode, response)
                    }
                }
                else{
                    if let data = data{
                        onSuccess(data,response.statusCode, response)
                    }else{
                        onFailure(APIError.ServerError("Unknown data error, check response for detail"),response.statusCode, response)
                    }
                }
            }
            else{
                onFailure(APIError.ServerError("Unknown server error, check response for detail"), -1, response)
            }
        }
        task.resume()
    }
    
    func getUrlRequest(url:String, isPost:Bool) -> URLRequest?{
        guard let url = URL(string: url)
        else {
                return nil
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue(getloginString(), forHTTPHeaderField: "Authorization")
        if(isPost){
            urlRequest.httpMethod = "POST"
        }
        return urlRequest
    }
    
    func getloginString() -> String{
        let tokenString = username + ":" + password
        let tokenData = tokenString.data(using: .utf8)!
        let base64TokenString = tokenData.base64EncodedString()
        return "Basic \(base64TokenString)"
    }
    
    func getVerifyRequest(piiInfo: PiiInfo) -> DocumentVerificationRequest{
        let frontImageString = convertAndCompressImageToBase64(image: piiInfo.frontImage)
        let backImageString = convertAndCompressImageToBase64(image: piiInfo.backImage)
        let liveImageString = convertAndCompressImageToBase64(image: piiInfo.liveImage)
        
        let dataFields = DataFields(personInfo: PersonInfo(piiInfo: piiInfo), documentInfo: Document(frontImage: frontImageString!, backImage: backImageString, livePhoto: liveImageString, documentType: piiInfo.documentType))
        return DocumentVerificationRequest(countryCode: piiInfo.countryCode, dataFields: dataFields)
    }
    
    private func convertAndCompressImageToBase64(image:UIImage?) -> String?{
        if(image == nil)
        {
            return nil
        }
        var quality:CGFloat = 1.0
        var imageData = image!.jpegData(compressionQuality: quality)
        while(imageData!.count > maxImageSize && quality > 0){
            quality -= 0.1
            imageData = image!.jpegData(compressionQuality: quality)
        }
        return imageData?.base64EncodedString()
    }
}

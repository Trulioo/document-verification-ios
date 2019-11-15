//
//  TruliooSampleApp
//
//  Created by Trulioo on 2019-11-13.
//  Copyright © 2019 Trulioo. All rights reserved.
//

import UIKit

class TruliooResultViewController: UIViewController {

    var piiInfo:PiiInfo? = nil
    var progressView : AcuantProgressView!
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var textBox: UITextView!
    
    @IBAction func doneTapped(_ sender: Any) {
        reset()
        let rootVC : RootViewController = self.navigationController?.viewControllers[0] as! RootViewController
        rootVC.resetData()
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textBox.isHidden = true
        doneButton.isEnabled = false
        
        progressView = AcuantProgressView(frame: self.view.frame, center: self.view.center)
        DispatchQueue.global(qos:.userInteractive).async{
            self.showProgressView(text: "Processing")
            if(self.piiInfo == nil){
                self.appendText(text: "Error, no info availble")
                self.endProcess()
            }
            else{
                self.verify()
            }
        }
    }
    
    func verify(){
        let helper = TruliooHelper()
        helper.verify(piiInfo: piiInfo!, onSuccess: onSuccess, onFailure: { (error, statusCode, response) in
            var displayString = ""
            displayString += "Fail, Status Code: \(statusCode) \n"
            displayString += "Error: \(error) \n"
            if(response != nil){
                displayString += "Response: \(String(describing: response)) \n"
            }
            self.appendText(text: displayString)
            self.endProcess()
        })
    }
    
    func onSuccess(data:Data, statusCode:Int, httpResponse:HTTPURLResponse?){
        do{
            // decode result object
            let result = try JSONDecoder().decode(VerifyResult.self, from: data)
            
            self.appendText(text: "Success")
            self.appendText(text: "TransactionID: \(result.TransactionID)")
            self.appendText(text: nil)
            
            let datasourceResult = result.Record.DatasourceResults.first
            if(datasourceResult != nil){
                self.appendText(text:"\nOutput Fields: ")
                let outputFields = datasourceResult!.DatasourceFields
                for fieldRecord in outputFields{
                    self.appendText(text: "\(fieldRecord.FieldName): \(fieldRecord.Status)")
                }
                
                self.appendText(text:"\nAppended Fields: ")
                let appendFields = datasourceResult!.AppendedFields
                var authenticityDetailsString = ""
                for fieldRecord in appendFields{
                    if(fieldRecord.FieldName != "AuthenticityDetails"){
                        self.appendText(text: "\(fieldRecord.FieldName): \(fieldRecord.Data)")
                    }
                    else{
                        do{
                            let detailData = fieldRecord.Data.data(using: .utf8)!
                            let authenticityDetailArray = try JSONDecoder().decode([AuthenticityDetail].self, from: detailData)
                            for record in authenticityDetailArray{
                                authenticityDetailsString += "Detail Name: \(record.Name) \n"
                                authenticityDetailsString += "IsValid: \(record.IsValid) \n"
                                authenticityDetailsString += "Value: \(record.Value) \n"
                                authenticityDetailsString += "Description: \(record.Description) \n"
                                //more info available, check TruliooResultClass for destail
                                authenticityDetailsString += "\n"
                            }
                        }catch{
                            authenticityDetailsString += "Error decoding AuthenticityDetails JSON \n"
                        }
                    }
                }
                if(!authenticityDetailsString.isEmpty){
                    self.appendText(text: "\nAuthenticity Details: \n")
                    self.appendText(text:authenticityDetailsString)
                }
            }
        }
        catch{
            let dataString = String(data:data, encoding: .utf8)!
            self.appendText(text:"Error decoding JSON, printing raw data")
            self.appendText(text: dataString)
        }
        self.endProcess()
    }
    
    func reset(){
        piiInfo = nil
        textBox.text = ""
    }

    private func showProgressView(text:String = ""){
        DispatchQueue.main.async {
            self.progressView.messageView.text = text
            self.progressView.startAnimation()
            self.view.addSubview(self.progressView)
        }
    }
    
    private func hideProgressView(){
        DispatchQueue.main.async {
            self.progressView.stopAnimation()
            self.progressView.removeFromSuperview()
        }
    }
    
    private func appendText(text:String?){
        DispatchQueue.main.async {
            if let text = text{
                self.textBox.text += text + "\n"
            }else{
                self.textBox.text += "\n"
            }
        }
    }
    
    private func endProcess(){
        DispatchQueue.main.async {
            self.hideProgressView()
            self.doneButton.isEnabled = true
            self.textBox.isHidden = false
        }
    }
}

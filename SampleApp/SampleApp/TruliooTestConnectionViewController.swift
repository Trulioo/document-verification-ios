//
//  TruliooSampleApp
//
//  Created by Trulioo on 2019-11-13.
//  Copyright © 2019 Trulioo. All rights reserved.
//

import UIKit

class TruliooTestConnectionViewController:UIViewController {
   
    @IBOutlet weak var textBox: UITextView!
    
    var progressView : AcuantProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView = AcuantProgressView(frame: self.view.frame, center: self.view.center)
        textBox.isHidden = true
        showProgressView(text: "Connecting")
        DispatchQueue.global(qos:.userInteractive).async{
            self.testAuthentication()
        }
    }

    func testAuthentication(){
        let helper = TruliooHelper()
        
        helper.TestAuthentication(
            onSuccess: { (data, statusCode, response) in
            var displayString = ""
            displayString += "Success, Status Code: \(statusCode) \n"
            let formatedData = String(data:data, encoding: .utf8)
            if(formatedData != nil){
                displayString += "Data: " + formatedData!
            }
            self.finishLoading(text: displayString)
            },
            onFailure: { (error, statusCode, response) in
            var displayString = ""
            displayString += "Fail, Status Code: \(statusCode) \n"
            displayString += "Error: \(error) \n"
            if(response != nil){
                displayString += "Response: \(String(describing: response)) \n"
            }
            self.finishLoading(text: displayString)
        })
    }

    func finishLoading(text: String){
        hideProgressView()
        DispatchQueue.main.async{
            self.textBox.insertText(text)
            self.textBox.isHidden = false
        }
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
}

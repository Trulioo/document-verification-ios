//
//  TruliooSampleApp
//
//  Created by Trulioo on 2019-11-13.
//  Copyright © 2019 Trulioo. All rights reserved.
//

import UIKit

class TruliooConfirmationViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate{
    @IBOutlet weak var frontImageView: UIImageView!
    @IBOutlet weak var backImageView: UIImageView!
    @IBOutlet weak var liveImageView: UIImageView!
    @IBOutlet weak var livePhotoLabel: UILabel!
    
    @IBOutlet weak var firstNameBox: UITextField!
    @IBOutlet weak var lastNameBox: UITextField!
    @IBOutlet weak var countryCodeBox: UITextField!
    @IBOutlet weak var docTypeBox: UITextField!
    
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    let countryPickerView = UIPickerView()
    
    // You can fetch the full list with Trulioo API
    let countryCodeArray = ["CA","US"]
    
    public var frontImage: UIImage? = nil
    public var backImage: UIImage? = nil
    public var liveImage: UIImage? = nil
    public var docType:String? = nil
    
    let toolBar = UIToolbar(frame:CGRect(x:0, y:0, width: UIScreen.main.bounds.width, height:45))
    var doneButton:UIBarButtonItem!
    
    @IBAction func confirmTapped(_ sender: Any) {
        let firstName = firstNameBox.text!
        let lastName = lastNameBox.text!
        if(firstName.isEmpty || lastName.isEmpty){
            let alert = UIAlertController(title: "Missing Input Fields", message: "Please Enter First And Last Name", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true)
        }
        else{
            let pii = PiiInfo(firstName: firstName, lastName: lastName, countryCode: countryCodeBox.text!, documentType: docTypeBox.text!, frontImage: frontImage!, backImage: backImage, liveImage: liveImage)
        
            let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
            let resultVC : TruliooResultViewController = storyBoard.instantiateViewController(withIdentifier: "TruliooResultViewController") as! TruliooResultViewController
            resultVC.piiInfo = pii
            self.navigationController?.pushViewController(resultVC, animated: true)
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        reset()
        let rootVC : RootViewController = self.navigationController?.viewControllers[0] as! RootViewController
        rootVC.resetData()
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(frontImage != nil)
        {
            frontImageView.image = frontImage
        }
        if(backImage != nil)
        {
            backImageView.image = backImage
        }
        if(liveImage != nil)
        {
            liveImageView.image = liveImage
        }
        else{
            livePhotoLabel.isHidden = true
        }
        
        doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(self.donePressed))
        toolBar.items = [doneButton]
        
        countryPickerView.dataSource = self
        countryPickerView.delegate = self as UIPickerViewDelegate
        
        firstNameBox.delegate = self as UITextFieldDelegate
        lastNameBox.delegate = self as UITextFieldDelegate
        firstNameBox.inputAccessoryView = toolBar
        lastNameBox.inputAccessoryView = toolBar
        
        countryCodeBox.inputAccessoryView = toolBar
        countryCodeBox.text = countryCodeArray.first
        docTypeBox.text = docType!
        docTypeBox.isEnabled = false
        
        countryCodeBox.inputView = countryPickerView
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
         if pickerView == countryPickerView {
             return countryCodeArray.count
         }
         return 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == countryPickerView {
            return countryCodeArray[row]
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(pickerView == countryPickerView){
            countryCodeBox.text = countryCodeArray[row]
        }
    }
    
    @objc func donePressed(){
        view.endEditing(true)
    }
    
    func reset(){
        frontImage = nil
        backImage = nil
        liveImage = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
       textField.resignFirstResponder()
       return true
    }
       
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
   
    func textFieldDidEndEditing(_ textField: UITextField) {
    }
    
}




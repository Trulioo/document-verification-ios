//
//  ViewController.swift
//  SampleApp
//
//  Created by Tapas Behera on 7/5/18.
//  Copyright © 2018 com.acuant. All rights reserved.
//

import UIKit
import AcuantImagePreparation
import AcuantCamera
import AcuantCommon
import AcuantDocumentProcessing
import AcuantFaceMatch
import AcuantHGLiveness
import AcuantIPLiveness
import AVFoundation

class RootViewController: UIViewController ,UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate,InitializationDelegate, FacialMatchDelegate,DeleteDelegate,AcuantHGLivenessDelegate,CameraCaptureDelegate,LivenessSetupDelegate,LivenessTestDelegate,LivenessTestResultDelegate, LivenessTestCredentialDelegate{
    
    let documentTypeArray = ["DrivingLicence","Passport"]
    let docTypepickerView = UIPickerView()
    
    @IBOutlet var autoCaptureSwitch : UISwitch!
    
    public var capturedFrontImage : UIImage?
    public var capturedBackImage : UIImage?
    public var capturedLiveFace : UIImage?
    public var capturedBarcodeString : String?
    public var documentInstance : String?
    public var isProcessing : Bool = false
    public var isLiveFace : Bool = false
    public var isProcessingFacialMatch : Bool = false
    public var capturedFacialMatchResult : FacialMatchResult? = nil
    public var capturedFaceImageUrl : String? = nil
    public var isRetrying : Bool = false
    private var isInitialized = false
    private var isIPLivenessEnabled = false
    
    public var idOptions : IdOptions? = nil
    public var idData : IdData? = nil
    
    public var ipLivenessSetupResult : LivenessSetupResult? = nil
    
    var side : CardSide = CardSide.Front
    var captureWaitTime = 2
    var minimumNumberOfClassificationAttemptsRequired = 1
    var numerOfClassificationAttempts = 0
    
    var autoCapture = true
    var progressView : AcuantProgressView!

    @IBOutlet var idPassportButton: UIButton!
    
    @IBOutlet weak var docTypeBox: UITextField!
    let toolBar = UIToolbar(frame:CGRect(x:0, y:0, width: UIScreen.main.bounds.width, height:45))
    var doneButton:UIBarButtonItem!
    
    
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
    
    @IBAction func idPassportTapped(_ sender: UIButton) {
        if(CheckConnection.isConnectedToNetwork() == false){
            CustomAlerts.displayError(message: CheckConnection.ERROR_INTERNET_UNAVAILABLE)
        }
        else{
            if(!isInitialized){
                let ipLivenessCallback = IPLivenessCredentialHelper(callback: {
                    (isEnabled) in
                    self.isInitialized = true
                    self.resetData()
                    self.isIPLivenessEnabled = isEnabled
                    self.hideProgressView()
                    self.showDocumentCaptureCamera()
                
                }, onError: {
                    error in
                    DispatchQueue.main.async {
                        self.hideProgressView()
                        CustomAlerts.displayError(message: error.errorDescription!)
                    }
                    
                })
                let retryCallback = ReinitializeHelper(callback: { isInitialized in
                    DispatchQueue.main.async {
                        if(isInitialized){
                            AcuantIPLiveness.getLivenessTestCredential(delegate: ipLivenessCallback)
                        }
                        else{
                            self.hideProgressView()
                        }
                    }
                })
                
                AcuantImagePreparation.initialize( delegate:retryCallback)
                self.showProgressView(text: "Initializing...")
            }
            else{
                resetData()
                showDocumentCaptureCamera()
            }
        }
    }
    
    @IBAction func autocaptureSwitched(_ sender: UISwitch) {
        if sender.isOn {
            autoCapture =  true
        } else {
            autoCapture =  false
        }
    }
    
    private func getIPLivenessCredential(){
        AcuantIPLiveness.getLivenessTestCredential(delegate: self)
    }
    
    func livenessTestCredentialReceived(result:Bool){
        isInitialized = true
        isIPLivenessEnabled = result
    }
    
    func goToTruliooPage(){
        hideProgressView()
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
        let confirmController = storyBoard.instantiateViewController(withIdentifier: "TruliooConfirmationViewController") as! TruliooConfirmationViewController
        
        confirmController.reset()
        if(self.capturedFrontImage != nil){
            confirmController.frontImage = self.capturedFrontImage
        }
        
        if(self.capturedBackImage != nil){
            confirmController.backImage = self.capturedBackImage
        }
        
        if(self.capturedLiveFace != nil){
            confirmController.liveImage = self.capturedLiveFace
        }
        confirmController.docType = docTypeBox.text!
        
        self.navigationController?.pushViewController(confirmController, animated: true)
    }
    
    
    func livenessTestCredentialReceiveFailed(error:AcuantError){
        self.hideProgressView()
        CustomAlerts.displayError(message: "\(error.errorCode) : \(String(describing: error.errorDescription))" )
    }
    
    func showDocumentCaptureCamera(){
        // handler in .requestAccess is needed to process user's answer to our request
        AVCaptureDevice.requestAccess(for: .video) { [weak self] success in
            if success { // if request is granted (success is true)
                DispatchQueue.main.async {
                    let options = AcuantCameraOptions(digitsToShow:self!.captureWaitTime, autoCapture:self!.autoCapture, hideNavigationBar: true)
                    let documentCameraController = DocumentCameraController.getCameraController(delegate:self!, cameraOptions: options)
                    self!.navigationController?.pushViewController(documentCameraController, animated: false)
                }
            } else { // if request is denied (success is false)
                // Create Alert
                let alert = UIAlertController(title: "Camera", message: "Camera access is absolutely necessary to use this app", preferredStyle: .alert)
                
                // Add "OK" Button to alert, pressing it will bring you to the settings app
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }))
                // Show the alert with animation
                self!.present(alert, animated: true)
            }
        }
    }
    
    
    class IPLivenessCredentialHelper:LivenessTestCredentialDelegate{
        init(callback: @escaping (_ isInitalized: Bool) -> (), onError: @escaping (_ error:AcuantError) -> ()){
            self.completion = callback
            self.onError = onError
        }
        var completion: (_ isInitalized: Bool)->()
        var onError: (_ error:AcuantError)->()
        func livenessTestCredentialReceived(result:Bool){
            self.completion(result)
        }
        func livenessTestCredentialReceiveFailed(error:AcuantError){
            self.onError(error)
        }
    }
    
    class ReinitializeHelper:InitializationDelegate{
        init(callback: @escaping (_ isInitalized: Bool) -> ()){
            completion = callback
        }
        var completion: (_ isInitalized: Bool)->()
        func initializationFinished(error: AcuantError?) {
            if(error != nil){
                CustomAlerts.displayError(message: error!.errorDescription!)
                self.completion(false)
            }
            else{
                self.completion(true)
            }
        }
    }
    
    func resetData(){
        side = CardSide.Front
        captureWaitTime = 2
        numerOfClassificationAttempts = 0
        isProcessing = false
        isLiveFace = false
        isRetrying = false
        isProcessingFacialMatch = false
        capturedFrontImage = nil
        capturedBackImage = nil
        capturedLiveFace = nil
        capturedBarcodeString = nil
        capturedFaceImageUrl = nil
        capturedFacialMatchResult = nil
        documentInstance = nil
        idOptions = nil
        idData = nil
        ipLivenessSetupResult = nil
    }
    
    func showFacialCaptureInterface(){
        self.isProcessingFacialMatch = true
        if(isIPLivenessEnabled){
            //Code for IP liveness
            AcuantIPLiveness.performLivenessSetup(delegate: self)
        }
        else{
            // Code for HG Live controller
            let liveFaceViewController = FaceLivenessCameraController()
            liveFaceViewController.delegate = self
            self.navigationController?.pushViewController(liveFaceViewController, animated: true)
        }
        
    }
    
    // IP Liveness
    func livenessSetupSucceeded(result: LivenessSetupResult) {
        ipLivenessSetupResult = result
        result.ui.title = ""
        AcuantIPLiveness.performLivenessTest(setupResult: result, delegate: self)
    }
    
    func livenessSetupFailed(error: AcuantError) {
        livenessTestFailed(error:error)
    }
    
    func livenessTestCompleted() {
        AcuantIPLiveness.getLivenessTestResult(token: ipLivenessSetupResult!.token, userId: ipLivenessSetupResult!.userId, delegate: self)
    }
    
    func livenessTestProcessing(progress: Double, message: String) {
        DispatchQueue.main.async {
            self.showProgressView(text: "\(Int(progress * 100))%")
        }
    }
    
    func livenessTestCompletedWithError(error: AcuantError?) {
        AcuantIPLiveness.getLivenessTestResult(token: ipLivenessSetupResult!.token, userId: ipLivenessSetupResult!.userId, delegate: self)
    }
    
    func livenessTestResultReceived(result: LivenessTestResult) {
        isLiveFace = result.passedLivenessTest
        processFacialMatch(image: result.image!)
    }
    
    func livenessTestResultReceiveFailed(error: AcuantError) {
        livenessTestFailed(error:error)
    }
    
    func livenessTestFailed(error:AcuantError) {
        capturedLiveFace = nil
        isLiveFace = false
        self.isProcessingFacialMatch = false
    }

    func processFacialMatch(image:UIImage){
        capturedLiveFace = image
        goToTruliooPage()
    }
    
    public func liveFaceCaptured(image:UIImage?){
        if(image != nil){
            self.isLiveFace = true
            processFacialMatch(image: image!)
        }
        else{
            self.isProcessingFacialMatch = false
            DispatchQueue.main.async {
                self.hideProgressView()
            }
        }
      
    }
    
    public func setCapturedImage(image:Image, barcodeString:String?){
        self.showProgressView(text: "Processing...")
    
        if(barcodeString != nil){
            capturedBarcodeString = barcodeString
        }
        let croppedImage = cropImage(image: image.image!)
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                if(croppedImage?.image == nil || (croppedImage?.error != nil && croppedImage?.error?.errorCode != AcuantErrorCodes.ERROR_LowResolutionImage)){
                    CustomAlerts.display(
                        message: (croppedImage?.error?.errorDescription)!,
                        action: UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default, handler: { (action:UIAlertAction) in self.retryCapture() }))
                }
                else{
                    let sharpness = AcuantImagePreparation.sharpness(image:croppedImage!.image!)
                    let glare = AcuantImagePreparation.glare(image:croppedImage!.image!)
                    self.hideProgressView()
                    
                    let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
                    let confirmController = storyBoard.instantiateViewController(withIdentifier: "ConfirmationViewController") as! ConfirmationViewController
                    confirmController.sharpness = sharpness
                    confirmController.glare = glare
                    if(self.side==CardSide.Front){
                        confirmController.side = CardSide.Front
                    }else{
                        confirmController.side = CardSide.Back
                    }
                    if(barcodeString != nil){
                        confirmController.barcodeCaptured = true
                        confirmController.barcodeString = barcodeString
                    }
                    confirmController.image = croppedImage
                    self.navigationController?.pushViewController(confirmController, animated: true)
                }
                self.hideProgressView()
            }
        }
    }
    
    func cropImage(image:UIImage)->Image?{
        let croppingData  = CroppingData()
        croppingData.image = image
        
        let croppedImage = AcuantImagePreparation.crop(data: croppingData)
        return croppedImage
    }
    
    public func confirmImage(image:UIImage,side:CardSide){
        if(side==CardSide.Front){
            capturedFrontImage = image
        } else {
            capturedBackImage = image
        }
        if(side==CardSide.Front && self.isBackSideRequired()){
            // Capture Back Side
            let alert = UIAlertController(title: NSLocalizedString("Back Side?", comment: ""), message: NSLocalizedString("Scan the back side of the ID document", comment: ""), preferredStyle:UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
            { action -> Void in
                self.side = CardSide.Back
                self.captureWaitTime = 2
                self.showDocumentCaptureCamera()
            })
            self.present(alert, animated: true, completion: nil)
        } else{
            let alert = UIAlertController(title: NSLocalizedString("Live Photo", comment: ""), message: NSLocalizedString("Capture Live Photo Now", comment: ""), preferredStyle:UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
            { action -> Void in
                self.captureWaitTime = 2
                self.showFacialCaptureInterface()
                self.isProcessing = true
                self.showProgressView(text: "Processing...")
            })
            alert.addAction(UIAlertAction(title: "Skip", style: UIAlertAction.Style.default)
            { action -> Void in
                self.goToTruliooPage()
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    public func retryCapture(){
        showDocumentCaptureCamera()
    }
    
    public func retryClassification(){
        isRetrying = true
        showDocumentCaptureCamera()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(self.donePressed))
        toolBar.items = [doneButton]
        docTypepickerView.dataSource = self
        docTypepickerView.delegate = self as UIPickerViewDelegate
        docTypeBox.inputAccessoryView = toolBar
        docTypeBox.text = documentTypeArray.first
        docTypeBox.inputView = docTypepickerView
        
        autoCaptureSwitch.setOn(true, animated: false)

        self.progressView = AcuantProgressView(frame: self.view.frame, center: self.view.center)
        self.showProgressView(text:  "Initializing...")
        
        AcuantImagePreparation.initialize(delegate:self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func initializationFinished(error: AcuantError?) {
        self.hideProgressView()
        if(error == nil){
            self.hideProgressView()
            self.isInitialized = true
            self.resetData()
        }else{
            if let msg = error?.errorDescription {
                CustomAlerts.displayError(message: "\(error!.errorCode) : " + msg)
            }
        }
    }
    
    func facialMatchFinished(result: FacialMatchResult?) {
        self.isProcessingFacialMatch = false
        if(result?.error == nil){
            capturedFacialMatchResult = result
        }else{
            if let msg = result?.error?.errorDescription {
                CustomAlerts.displayError(message: msg)
            }
        }
    }
    
    func instanceDeleted(success: Bool) {
        print()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func isBackSideRequired()->Bool{
        return docTypeBox.text! != "Passport"
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == docTypepickerView{
            return documentTypeArray.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == docTypepickerView {
            return documentTypeArray[row]
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(pickerView == docTypepickerView) {
            docTypeBox.text = documentTypeArray[row]
        }
    }
    
    @objc func donePressed(){
        view.endEditing(true)
    }
    
}

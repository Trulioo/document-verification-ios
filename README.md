
# Trulioo Sample App with Acuant IOS SDK v11.4.9

**Disclaimer**
This sample application is a prototype written to demonstrate how to integrate with the Trulioo platform. It is by no means production ready and will not be supported by Trulioo. It is being hosted here strictly as an example and should not be used as a foundation for your Document Capture Applications.

You should have received an integration guide from Trulioo to show how to try this demo application.

## Quick Start
This project requires that the system has [https://github.com/Carthage/Carthage](https://github.com/Carthage/Carthage) installed.

Enter Acuant account in  SampleApp/SampleApp/AcuantConfig.plist

Enter Trulioo credentials in  SampleApp/SampleApp/TruliooHelper.swift

**As of May 1, 2020, the AcuantConfig.plist file should look like this**  
  
<?xml version="1.0" encoding="UTF-8"?>  
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"   "http://www.apple.com/DTDs/PropertyList-1.0.dtd">  
<plist version="1.0">  
   <dict>  
       <key>acuant_username</key>  
       <string>xxx</string>  
       <key>acuant_password</key>  
       <string>xxx</string>  
       <key>acuant_subscription</key>  
       <string></string>  
       <key>frm_endpoint</key>  
       <string>https://frm.acuant.net</string>  
       <key>passive_liveness_endpoint</key>  
       <string>https://passlive.acuant.net</string>  
       <key>med_endpoint</key>  
       <string>https://medicscan.acuant.net</string>  
       <key>assureid_endpoint</key>  
       <string>https://services.assureid.net</string>  
       <key>acas_endpoint</key>  
       <string>https://acas.acuant.net</string>  
       <key>ozone_endpoint</key>  
       <string>https://ozone.acuant.net</string>  
   </dict>  
</plist>  
  
## Prerequisites 
This project requires that the system has https://github.com/Carthage/Carthage installed and Xcode version 12.4.

//
//  ViewController.swift
//  Payments
//
//  Created by Suraj Bhardwaj on 14/12/23.
//

import UIKit
import PhonePePayment
class ViewController: UIViewController {
    
    var newTxnId: String {
        "\(UUID().uuidString.suffix(35))" // MAX 35 characters allowed
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        PPPayment.enableDebugLogs = true
        
    }
    @IBAction func startTransactionAction(_ sender: Any) {
//        let paValue = "upiIdTxtField.text! " //payee address upi id
//        let pnValue = "userNameTxtField.text!"     // payee name
//        let trValue = "1234"      //tansaction Id
//        let urlValue = "http://url/of/the/order/in/your/website" //url for refernec
//        let mcValue = "1234"  // retailer category code :- user id
//        let tnValue = "notesTxtField.text!" //transction Note
//        let amValue = "amountTxtField.text!"  //amount to pay
//        let cuValue = "INR"    //currency
//
//        let str =  "phonepe://upi/pay?pa=\(paValue)&pn=\(pnValue)&tr=\(trValue)&mc=\(mcValue)&tn=\(tnValue)&am=\(amValue)&cu=\(cuValue)"
//
//         guard let urlString = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
//         else {
//             return
//         }
//
//         guard let url = URL(string: urlString) else {
//             return
//         }
//
//        UIApplication.shared.open(url) { (success) in
//            print(success)
//            if success{
//                print("You have Gpay app in your phone.")
//            }else{
//                print("You don't have Gpay app in your phone.")
//            }
//        }
        startPhonePeTransaction()
    }

    @IBAction func PGUPIIntentAction(_ sender: Any) {
        isPhonePeInstalled()
        makePGRequest(type: .UPI_INTENT)
    }

    @IBAction func PGUPICollectAction(_ sender: Any) {
        isPhonePeInstalled()
        makePGRequest(type: .UPI_COLLECT)
    }
    func startPhonePeTransaction() {
        let paValue = "8511075431@paytm" // payee address upi id
        let pnValue = "Suraj Bhardwaj" // payee name
        let trValue = newTxnId // transaction Id
        let amountValue = "2" // amount to pay

        let urlString = "phonepe://upi/pay?pa=\(paValue)&pn=\(pnValue)&tr=\(trValue)&am=\(amountValue)"

        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else {
            return
        }

        UIApplication.shared.open(url) { (success) in
            if success {
                print("PhonePe app launched successfully!")
            } else {
                print("PhonePe app not found or not compatible.")
            }
        }
    }

    func isPhonePeInstalled() -> Bool {
       
        guard let openUrl1 = URL(string: UriSchemeConstants.uriScheme1 + UriSchemeConstants.hyphenation),
            let openUrl2 = URL(string: UriSchemeConstants.uriScheme2 + UriSchemeConstants.hyphenation),
                let openUrl3 = URL(string: UriSchemeConstants.uriScheme3 + UriSchemeConstants.hyphenation) else {
                  return false
                }

        let appInstalled = UIApplication.shared.canOpenURL(openUrl1) ||
            UIApplication.shared.canOpenURL(openUrl2) ||
            UIApplication.shared.canOpenURL(openUrl3)

        return appInstalled
      
    }
}
extension ViewController {
    func makeDebitRequest() {
        let saltValue = salt
        let saltIndexValue = saltIndex
        let merchantID = merchantId
        let server = Environment.uat //

        let service = "/v4/debit"
        let txnId = newTxnId // This id must be unquie for each transaction
        let amount = 2 // Amount should be in paisa
        let userId = "" // Logged in user id
        let message = "Payment towards order No. OD139924923" // Message that will be displayed to user
        let orderID = "OD139924923" // Id of oder for which payment is initiated
        let callBackURL = deeplinkSchema // callback scheme to reopen the app

        let offerInfo = ["offerId": "offerId", "offerDescription": "Amazing offer"]
        let discountInfo = ["discountId": "abc", "discountDescription": "mydescription", "someInfo": ["otherInfo": "Test"]] as [String: Any]

        var data: [String: Any] = [:]
        data["merchantId"] = merchantID
        data["transactionId"] = txnId
        data["amount"] = amount
        data["merchantOrderId"] = orderID
        data["message"] = message
        if !userId.isEmpty {
            data["merchantUserId"] = userId
        }

        data["offer"] = offerInfo
        data["discount"] = discountInfo
        data["providerName"] = "xMerchantId"
        data["paymentScope"] = "PHONEPE"

        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) else {
            print("Invalid Data to convert")
            return
        }

        let base64EncodedString = jsonData.base64EncodedString()
        let payloadChecksum = ChecksumHelper.calculateChecksum(of: base64EncodedString, api: service, salt: saltValue, saltIndex: saltIndexValue)

        let headers: [String: String] = ["X-CALL-MODE": "POST",
                                         "X-CALLBACK-URL": "https://enjfktbm7ajrh.x.pipedream.net/"]

        print("Initiating Debit Request with data \(data)")
        print("Initiating Debit Request with payloadChecksum \(payloadChecksum)")

        let request: DPSTransactionRequest = DPSTransactionRequest(body: base64EncodedString,
                                                                  apiEndPoint: service,
                                                                  checksum: payloadChecksum,
                                                                  headers: headers,
                                                                  callBackURL: callBackURL)

        // Set enableLogging = true for debug logs
        PPPayment.init(environment: server, enableLogging: true, appId: "").startPhonePeTransactionRequest(transactionRequest: request, on: self, animated: true) { _, result in
            let text = "\(result)"
            print(text)
            print("Completion:---------------------")
        }
    }

    func makePGRequest(type: PaymentInstrumentType) {
        let saltValue = salt
        let saltIndexValue = saltIndex
        let merchantID = merchantId
        let server = Environment.uat

        let service = "/pg/v1/pay"
        let txnId = newTxnId // This id must be unquie for each transaction
        let amount = 200 // Amount should be in paisa
        let userId = "U100121333" // Logged in user id
        let message = "Payment towards order No. OD139924923" // Message that will be displayed to user
        let iOSAppCallbackSchema = ""
        let callBackURL = "https://www.phonepe.com"
        let redirectURL = "https://www.phonepe.com"

        var paymentInstrument: [String: Any] = ["type": type.rawValue]
        paymentInstrument["vpa"] = type == .UPI_COLLECT ? "umangbhatt1994@ybl" : nil

        var data: [String: Any] = [:]
        data["merchantId"] = merchantID
        data["merchantTransactionId"] = txnId
        data["amount"] = amount
        data["message"] = message
        data["merchantUserId"] = userId
        data["redirectUrl"] = redirectURL
        data["redirectMode"] = "GET"
        data["callbackUrl"] = callBackURL
        data["paymentInstrument"] = paymentInstrument

        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) else {
            print("Invalid Data to convert")
            return
        }

        let base64EncodedString = jsonData.base64EncodedString()
        let payloadChecksum = ChecksumHelper.calculateChecksum(of: base64EncodedString, api: service, salt: saltValue, saltIndex: saltIndexValue)

        let headers: [String: String] = [:]

        print("Initiating PG Request with data \(data)")
        print("Initiating PG Request with payloadChecksum \(payloadChecksum)")

        let request: DPSTransactionRequest = DPSTransactionRequest(body: base64EncodedString,
                                                                  apiEndPoint: service,
                                                                  checksum: payloadChecksum,
                                                                  headers: headers,
                                                                  callBackURL: iOSAppCallbackSchema)

        // Set enableLogging = true for debug logs
        PhonePeDPSDK(environment: server, enableLogging: true)
            .startPG(transactionRequest: request,
                     on: self,
                     animated: true) { _, result in
                let text = "\(result)"
                print(text)
                print("Completion:---------------------")
            }

    }
}

enum PaymentInstrumentType: String {
    case UPI_INTENT
    case UPI_COLLECT
}
private struct UriSchemeConstants {
  static let uriScheme1 = "ppemerchantsdkv1"
  static let uriScheme2 = "ppemerchantsdkv2"
  static let uriScheme3 = "ppemerchantsdkv3"
  static let hyphenation =  "://"
}


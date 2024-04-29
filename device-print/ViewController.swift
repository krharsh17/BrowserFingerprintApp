//
//  ViewController.swift
//  device-print
//
//  Created by Kumar Harsh on 29/04/24.
//

import UIKit
import FingerprintPro

class ViewController: UIViewController {
    
    private var visitorId = ""
    private var requestId = ""
    private var result: FingerprintResponse? = nil
    
    private let yourApiKey = "<your-api-key>"

    private lazy var stackView: UIStackView = {
            let v = UIStackView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.axis = .vertical
            v.spacing = 10
            v.distribution = .fill
            return v
        }()
        
        private lazy var logoView: UIImageView = {
            let iv = UIImageView()
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.contentMode = .scaleAspectFit
            iv.image = UIImage(named: "Logo")
            return iv
        }()
        
        private lazy var emailContainerView: UIView = {
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.backgroundColor = .clear
            v.layer.cornerRadius = 22
            v.layer.borderColor = UIColor.orange.cgColor
            v.layer.borderWidth = 1.5
            v.clipsToBounds = true
            return v
        }()
        
        private lazy var emailTextField: UITextField = {
            let tf = UITextField()
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.placeholder = "Email..."
            tf.tintColor = .orange
            tf.clipsToBounds = true
            tf.delegate = self
            return tf
        }()
        
        private lazy var passwordContainerView: UIView = {
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            v.backgroundColor = .clear
            v.layer.cornerRadius = 22
            v.layer.borderColor = UIColor.orange.cgColor
            v.layer.borderWidth = 1.5
            v.clipsToBounds = true
            return v
        }()
        
        private lazy var passwordTextField: UITextField = {
            let tf = UITextField()
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.placeholder = "Password..."
            tf.isSecureTextEntry = true
            tf.tintColor = .orange
            tf.clipsToBounds = true
            tf.delegate = self
            return tf
        }()
        
        private lazy var signUpButton: UIButton = {
            let b = UIButton()
            b.translatesAutoresizingMaskIntoConstraints = false
            b.setTitleColor(.orange, for: .normal)
            b.setTitle("Sign up", for: .normal)
            b.addTarget(self, action: #selector(didTapSignUpButton(sender:)), for: .touchUpInside)
            b.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            b.isUserInteractionEnabled = false
            b.alpha = 0.5
            return b
        }()

        override func viewDidLoad() {
            super.viewDidLoad()
            
            setUpViews()
            
        }
    
        private func getInformation() async {
            
            let region: Region = .eu
            let configuration = Configuration(apiKey: yourApiKey, region: region, extendedResponseFormat: true)
            let client = FingerprintProFactory.getInstance(configuration)
            
            do {
                let response = try await client.getVisitorIdResponse()
                switch response.confidence > 0.9 {
                case true:
                    self.visitorId = response.visitorId
                    self.requestId = response.requestId
                    self.result = response
                    print(response)
                    getVisitorInformation()
                default:
                    print("Error: Confidence rate too low")
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
            
        }

        
        private func setUpViews() {
            self.view.addSubview(stackView)
            stackView.addArrangedSubview(logoView)
            stackView.addArrangedSubview(emailContainerView)
            emailContainerView.addSubview(emailTextField)
            stackView.addArrangedSubview(passwordContainerView)
            passwordContainerView.addSubview(passwordTextField)
            stackView.addArrangedSubview(signUpButton)
            
            NSLayoutConstraint.activate([
            
                stackView.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
                stackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
                self.view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 30),
                
                logoView.heightAnchor.constraint(equalToConstant: 60),
                emailContainerView.heightAnchor.constraint(equalToConstant: 45),
                passwordContainerView.heightAnchor.constraint(equalToConstant: 45),
                
                emailTextField.topAnchor.constraint(equalTo: emailContainerView.topAnchor),
                emailTextField.leadingAnchor.constraint(equalTo: emailContainerView.leadingAnchor, constant: 10),
                emailContainerView.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor, constant: 10),
                emailContainerView.bottomAnchor.constraint(equalTo: emailTextField.bottomAnchor),
                
                passwordTextField.topAnchor.constraint(equalTo: passwordContainerView.topAnchor),
                passwordTextField.leadingAnchor.constraint(equalTo: passwordContainerView.leadingAnchor, constant: 10),
                passwordContainerView.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor, constant: 10),
                passwordContainerView.bottomAnchor.constraint(equalTo: passwordTextField.bottomAnchor),
            ])
        }

        @objc private func didTapSignUpButton(sender: UIButton) {
            
            Task {
                await getInformation()
                
                guard let email = emailTextField.text,
                      email != "",
                      let password = passwordTextField.text,
                      password != ""
                else { return }
                
                let queryUrl = "<your-server-ngrok-url>/register"
                
                let url = URL(string: queryUrl)!
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"

                let json: [String: Any] = ["email": email,
                                           "password": password,
                                           // TODO: 3
                                           "visitorId": visitorId,
                                           "requestId": requestId
                ]

                let jsonData = try? JSONSerialization.data(withJSONObject: json)

                request.httpBody = jsonData
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                    
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode)
                    else {
                        print("A server error occurred")
                        print(String(data: data!, encoding: .utf8) ?? "")
                        return
                    }
                    
                    print(String(data: data!, encoding: .utf8) ?? "")
                    
                    DispatchQueue.main.async {
                        self.hidesLoginTextFieldsAndShowsUserInfo()
                    }
                    
                }
                task.resume()
            }

        }
    
    private func hidesLoginTextFieldsAndShowsUserInfo() {
            let views = [emailContainerView, passwordContainerView, signUpButton]
            UIView.animate(withDuration: 1, animations: {
                views.forEach { $0.alpha = 0 }
            }, completion: { completion in
                views.forEach { $0.isHidden = true }
            })
            
            if let result = result {
                self.showsLabelWith(text: """
                    Your visitor ID: \(result.visitorId)
                    IP address: \(result.ipAddress ?? "")
                """)
            }
        }
        
        private func showsLabelWith(text: String) {
            DispatchQueue.main.async {
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
                label.textAlignment = .center
                label.numberOfLines = 0
                label.text = text
                label.alpha = 0
                self.stackView.addArrangedSubview(label)
                UIView.animate(withDuration: 1, delay: 1) {
                    label.alpha = 1
                }
            }
        }

    private func getVisitorInformation() {
            
        let queryUrl = "<your-server-ngrok-url>/visitorInfo"
        
        let url = URL(string: queryUrl)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let json: [String: Any] = ["visitorId": visitorId,
                                   "requestId": requestId
        ]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            
            if let error = error {
               print(error.localizedDescription)
               return
           }
           
           guard let httpResponse = response as? HTTPURLResponse,
                 (200...299).contains(httpResponse.statusCode)
           else {
               return }
           
           guard let responseData = data else { return }
           
           let decoder = JSONDecoder()
           do {
               let responseBody = try decoder.decode(GetVisitsResponse.self, from: responseData)
               guard let visits = responseBody.visits,
                     let latestVisit = visits.first
               else { return }
               self.showsLabelWith(text: """
                   Visits total: \(visits.count)
                   Incognito mode: \(latestVisit.incognito ? "on" : "off")
                   First visit: \(latestVisit.firstSeenAt?.global ?? "unknown")
                   Device: \(latestVisit.browserDetails.device ?? "unknown")
               """)
           } catch let error {
               print(error.localizedDescription)
           }
       }

        task.resume()
            
        }


}

extension ViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let isSignUpButtonEnabled: Bool = emailTextField.text != nil && emailTextField.text != "" && passwordTextField.text != "" && passwordTextField.text != nil
        signUpButton.isUserInteractionEnabled = isSignUpButtonEnabled
        signUpButton.alpha = isSignUpButtonEnabled ? 1 : 0.5
    }
    
}


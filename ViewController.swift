//
//  ViewController.swift
//  deneme2
//
//  Created by Eren Erinanc on 27.10.2020.
//

import UIKit

class ViewController: UIViewController,UNUserNotificationCenterDelegate {
    //set the country flags
    @IBOutlet var button1: UIButton!
    @IBOutlet var button2: UIButton!
    @IBOutlet var button3: UIButton!
    
    var scoreLabel: UILabel!
    
    var countries = ["estonia", "france", "germany", "ireland", "italy", "monaco", "nigeria", "poland", "russia", "spain", "uk", "us"]
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var correctAnswer = 0
    var question = 1
    var highScore = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Send request to the user for notifications. We want to remind them to come and play
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert,.badge,.sound]) {(granted, error) in}
        
        scheduleNotification()
        
        //Place buttons and add constraints
        setTheScene()
  
        askQuestion()
        
        //Decode the saved high score data and set it to the highScore variable
        decodeSavedData()

    }
    
    func setTheScene() {
        
        scoreLabel = UILabel()
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.textAlignment = .right
        scoreLabel.text = "Score: 0"
        view.addSubview(scoreLabel)
        
        button1.layer.borderWidth = 1
        button2.layer.borderWidth = 1
        button3.layer.borderWidth = 1
        
        button1.layer.borderColor = UIColor.lightGray.cgColor
        button2.layer.borderColor = UIColor.lightGray.cgColor
        button3.layer.borderColor = UIColor.lightGray.cgColor
        
        NSLayoutConstraint.activate([
                                        scoreLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
                                        scoreLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }
    
    func askQuestion(action: UIAlertAction! = nil) {
        
        //Randomizes the order of the flags so it shows different flag images in different order
        countries.shuffle()
        
        button1.setImage(UIImage(named: countries[0]), for: .normal)
        button2.setImage(UIImage(named: countries[1]), for: .normal)
        button3.setImage(UIImage(named: countries[2]), for: .normal)
        
        //This will give us a country name. User should find this country from the flags
        correctAnswer = Int.random(in: 0...2)
        title = "Q." + String(question) + "-" + countries[correctAnswer].uppercased()
        
        question += 1

    }
    
    func decodeSavedData() {
        let defaults = UserDefaults.standard
        
        if let savedHighScore = defaults.object(forKey: "highScore") as? Data {
            let jsonDecoder = JSONDecoder()
            do {
                highScore = try jsonDecoder.decode(Int.self, from: savedHighScore)
            } catch {
                print("Failed to load high score.")
            }
        }
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        var title: String
        
        //Scaling down the flag button each time it is tapped
        UIView.animate(withDuration: 0.3, delay: 0, options: [], animations: {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { finished in
            UIView.animate(withDuration: 0.3, delay: 0, options: [] ) {
                sender.transform = .identity }
        }
    
        //Each button is tagged on IB so we can check with the correct answer
        if sender.tag == correctAnswer {
            score += 1
            if score > highScore {
                highScore = score
                title = "This is the new high score!: \(highScore)"
            } else {
                title = "Correct"
            }
        } else {
            title = "Wrong! That is the flag of \(countries[sender.tag].uppercased())"
            score -= 1
        }
        
        //10 questions for each round. When it hits to 11, show users their score and ask if they want to continue
        if question == 11 {
            let ac = UIAlertController(title: title, message: "Final score is \(score)", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "One more round?", style: .default, handler: askQuestion))
            present(ac, animated: true)
            question = 1
            score = 0
        } else {
        let ac2 = UIAlertController(title: title, message: "Your score is \(score)", preferredStyle: .alert)
        ac2.addAction(UIAlertAction(title: "Continue", style: .default, handler: askQuestion))
        present(ac2, animated: true)
        }

    }
    
    func save() {
        let jsonEncoder = JSONEncoder()
        if let savedData = try? jsonEncoder.encode(highScore){
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "highScore")
        } else {
            print("Failed to save high score.")
        }
    }
    
    func scheduleNotification() {
        registerCategories()
        
        let center = UNUserNotificationCenter.current()
//        center.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Come play!"
        content.body = "Don't you want to beat your high score today champ?"
        content.categoryIdentifier = "ComePlayCall"
        content.userInfo = ["customData": "responded"]
        content.sound = UNNotificationSound.default
        
        var dateComponents = DateComponents()
        
        //These values are just for testing the notification
        dateComponents.hour = 11
        dateComponents.minute = 5
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func registerCategories() {
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        let show = UNNotificationAction(identifier: "Show", title: "Let's do it!", options: .foreground)
        
        let category = UNNotificationCategory(identifier: "ComePlayCall", actions: [show], intentIdentifiers: [])
        
        center.setNotificationCategories([category])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if let customData = userInfo["customData"] as? String {
            
            print("Custom data received : \(customData)")
            
            switch response.actionIdentifier {
            
            //Show user a welcome message inside the app when they tap "Show" from the notification interface
            case "Show":
                let ac = UIAlertController(title: "Welcome back", message: nil, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
                present(ac, animated: true)
                
            case UNNotificationDefaultActionIdentifier:
                print("Default identifier")
                
            default:
                break
            }
        }
        
        completionHandler()
    }

}

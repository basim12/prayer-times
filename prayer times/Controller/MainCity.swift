//
//  ViewController.swift
//  prayer times
//
//  Created by hammam abdulaziz on 15/08/1439 AH.
//  Copyright © 1439 hammam abdulaziz. All rights reserved.
//
//TODO:fix am
//TODO:fix notification
//TODO:fix bright of next prayer
//TODO:bring comment from old code
//TODO:fix synce of time
import UIKit
import ChameleonFramework
import Alamofire
import SwiftyJSON
import CoreLocation
import GooglePlaces
import AVFoundation
import UserNotifications
import SVProgressHUD


class MainCity: UIViewController, CLLocationManagerDelegate  {

    //MARK:- Labels
    //MARK: label of the name of the city
    @IBOutlet weak var cityNameLabel: UILabel!
    //MARK: Prayers labels
    @IBOutlet weak var nextPrayer: UILabel!
    @IBOutlet weak var fajerPrayer: UILabel!
    @IBOutlet weak var dohorPrayer: UILabel!
    @IBOutlet weak var aserPrayer: UILabel!
    @IBOutlet weak var maghrebPrayer: UILabel!
    @IBOutlet weak var ishaPrayer: UILabel!
    //MARK: Times of prayers labels
    @IBOutlet weak var nextPrayerTime: UILabel!
    @IBOutlet weak var fajerPrayerTime: UILabel!
    @IBOutlet weak var dohorPrayerTime: UILabel!
    @IBOutlet weak var aserPrayerTime: UILabel!
    @IBOutlet weak var maghrebPrayerTime: UILabel!
    @IBOutlet weak var ishaPrayerTime: UILabel!
    //MARK:- varibels
    //MARK: array of all the countries
    var countriesEN: [String] = []
    var countriesAR: [String] = []
    //MARK: locations varibels
    //google api to fetch the name of the city
    var placesClient: GMSPlacesClient!
    //create loction object
    let loctionManger = CLLocationManager()
    // create variables of latitude and longitude
    var lat : Double = 0
    var long : Double = 0
    //MARK: variables of counting the time
    var countDownSeconds = 59
    var countDownMinute = 0
    var countDownHour = 0
    var currentMinute : Int?
    var currentHour : Int?
    var timer = Timer()
    var timesOfPrayers = [String]()
    var indexOfNextPrayer = 0
    var hourOfPrayerTime: Int?
    var minuteOfPrayTime: Int?
    var isAM : Bool = false
    var isTimerRunning : Bool = false
    //MARK: varible of the sound
    var audioPlayer : AVAudioPlayer!
    //MARK:- Buttons
    //to refresh tho location if the user is in another city
    @IBAction func refreshButtonPressed(_ sender: UIButton) {
        SVProgressHUD.show()
        getCityName()
        
        loctionManger.startUpdatingLocation()
        locationManager(CLLocationManager.init(), didUpdateLocations: [CLLocation].init())
    }
    
    
    
    //FIXME: CHANGE THE DESIGHN
    //convert the time form
    @IBAction func convertionBetweenAMAndPM(_ sender: UIButton) {
        if isAM {
            fajerPrayerTime.text = timesOfPrayers[0]
            dohorPrayerTime.text = timesOfPrayers[1]
            aserPrayerTime.text = timesOfPrayers[2]
            maghrebPrayerTime.text = timesOfPrayers[3]
            ishaPrayerTime.text = timesOfPrayers[4]
            isAM = !isAM
            
        }else{
            fajerPrayerTime.text = convertToAM(time: getHour(prayNumber: 0), prayNumber: 0)
            dohorPrayerTime.text = convertToAM(time: getHour(prayNumber: 1), prayNumber: 1)
            aserPrayerTime.text = convertToAM(time: getHour(prayNumber: 2), prayNumber: 2)
            maghrebPrayerTime.text = convertToAM(time: getHour(prayNumber: 3), prayNumber: 3)
            ishaPrayerTime.text = convertToAM(time: getHour(prayNumber: 4), prayNumber: 4)
            isAM = !isAM
        }
    }
    
    
    
    
    //MARK:- viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show()
 
        //FIXME: PUT IT IN OTHER PLACE
        // jumaa exeption
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayInWeek = formatter.string(from: date)
        
        if (dayInWeek == "Friday"){
            dohorPrayer.text = "Friday"
        }
        
       
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { (didallow, error) in
        }
        
        // loction configuration
        loctionManger.delegate = self
        loctionManger.desiredAccuracy = kCLLocationAccuracyBest
        loctionManger.requestWhenInUseAuthorization()
       
        //fetch the countries of the worled
        //fetchCountries()
        
        placesClient = GMSPlacesClient.shared()
        getCityName()
        getLocation()
        sendNotification()
    }
    
    
    
    
    //MARK:- fetch Data
    //MARK: fetch the countries of the worled
    //fill the arrays with the countries
    func fetchCountries(){
        for code in NSLocale.isoCountryCodes as [String] {
            let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
            let englishName = NSLocale(localeIdentifier: "en_UK").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
            let arabicName = NSLocale(localeIdentifier: "ar").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
            countriesEN.append(englishName)
            countriesAR.append(arabicName)
        }
    }
    
    
    
    
  
              //MARK: fetch the city name
    //TODO: consider if want to change the value of city in local 
    //bring the city name from gps and display it in screen
     func getCityName() {
              //to chick if there is a saved name doni go to the api

        if let cityName = UserDefaults.standard.string(forKey: "cityName"){
            self.cityNameLabel.text = cityName
        }else{
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    self.cityNameLabel.text = place.addressComponents![3].name

                    UserDefaults.standard.set(place.addressComponents![3].name , forKey: "cityName")
                }
            }
        })
        }
        
    }
    
 
        
    
    
    
    
    //MARK: fetch the location
    // get latitude longitude data method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if  UserDefaults.standard.double(forKey: "lat") != nil &&  UserDefaults.standard.double(forKey: "long") != nil {
            lat = UserDefaults.standard.double(forKey: "lat")
            long = UserDefaults.standard.double(forKey: "long")
            timezone()

        }else{
        let location = locations[locations.count - 1]
        // if data not = 0
        if location.horizontalAccuracy > 0 {
            loctionManger.stopUpdatingLocation()
            // save latitude longitude data
            lat = location.coordinate.latitude
            long = location.coordinate.longitude

            UserDefaults.standard.set(lat, forKey: "lat")
            UserDefaults.standard.set(long, forKey: "long")
            
            // call TimeZone Method
            timezone()
        }
        }
    }
    
    
    
    //MARK: fetch timezone
    // timezone method
    func timezone(){
        // get timezone data
        let timeZone : String?
        if let curTimeZone = UserDefaults.standard.string(forKey: "timeZone"){
            timeZone = curTimeZone
        } else {
        var localTimeZoneAbbreviation: String { return TimeZone.current.abbreviation() ?? "" }
        // git only number of timezone using substring
         timeZone = String(localTimeZoneAbbreviation.suffix(2))
            UserDefaults.standard.set(timeZone , forKey: "timeZone")
        }
        // call API method
        API( lat: lat, long: long, timeZone: timeZone!)

    }
    
    
    
    
    //MARK: fetch prayers times
    // Api pray Time method
    func API ( lat : Double , long : Double , timeZone : String){
        // url of API
        let urls = "http://api.islamhouse.com/v1/Xm9B2ZoddJrvoyGk/services/praytime/get-times/Makkah/\(lat)/\(long)/\(timeZone)/json"
        Alamofire.request(urls, method: .get)
            .responseJSON { response in
                if response.result.isSuccess {
                    // save JSON result in variable
                    let fetchedPrayerTimes : JSON = JSON(response.result.value!)
                   // show pray time in UI
                    self.fajerPrayerTime.text = fetchedPrayerTimes["times"][0].stringValue
                    self.dohorPrayerTime.text = fetchedPrayerTimes["times"][2].stringValue
                    self.aserPrayerTime.text = fetchedPrayerTimes["times"][3].stringValue
                    self.maghrebPrayerTime.text  = fetchedPrayerTimes["times"][5].stringValue
                    self.ishaPrayerTime.text =  fetchedPrayerTimes["times"][6].stringValue
                   
                    
                    self.timesOfPrayers.removeAll()
                    self.timesOfPrayers.append(fetchedPrayerTimes["times"][0].stringValue )
                    self.timesOfPrayers.append(fetchedPrayerTimes["times"][2].stringValue )
                    self.timesOfPrayers.append(fetchedPrayerTimes["times"][3].stringValue )
                    self.timesOfPrayers.append(fetchedPrayerTimes["times"][5].stringValue )
                    self.timesOfPrayers.append(fetchedPrayerTimes["times"][6].stringValue )
                                        SVProgressHUD.dismiss()

                    self.determineTheNextPrayer()

                } else {
                    print("Error: \(String(describing: response.result.error))")
                }
        }
    }
    
    
    func playSound(){
             do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            print("Playback OK")
            try AVAudioSession.sharedInstance().setActive(true)
            print("Session is Active")
        } catch {
            print(error)
        }
        
      
        if let url = Bundle.main.url(forResource: "019--1", withExtension: "mp3"){
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
        }catch{
            print(error)
        }
            audioPlayer.play()
            
        }
    }
    
    
    
    //track the shacking of the phone
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if audioPlayer.isPlaying {
            audioPlayer.stop()
        }
    }
    
    
    
    //MARK:- show updates on screen 
    //chek which is the next prayer

    func determineTheNextPrayer(){
        fetchCurrentTime()
        for index in 0...4{
            getPrayerTime(at: index)
            
            if currentHour! <= hourOfPrayerTime! {
               
                if currentMinute! < minuteOfPrayTime!{
                    setCountDownTime(at: index)
                
                }else {
                    // if current minutes is greater so it will count to the next pray
                    getPrayerTime(at: index + 1)
                    setCountDownTime(at: index + 1)
                  
                   // playsound()
                }
                break
            }
        }
        
        //to show the result on screen and update it every second
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(MainCity.updateTimer)), userInfo: nil, repeats: true)
        SVProgressHUD.dismiss()
    }
    
    
    //fetch the date and time
    func fetchCurrentTime(){
        let date = Date()
        let calendar = Calendar.current
        currentHour = calendar.component(.hour, from: date)
        currentMinute = calendar.component(.minute, from: date)
        countDownSeconds = 59 - calendar.component(.second, from: date)
    }
    
    
    
    
    //get prayer time of the determined prayer to compare it with current time
    func getPrayerTime(at index: Int){
        hourOfPrayerTime = Int(timesOfPrayers[index].split(separator: ":")[0])!
        minuteOfPrayTime = Int(timesOfPrayers[index].split(separator: ":")[1])!
        
    }
    
    
    
    
    
    //set the Values of count down numbers to the next prayer
    func setCountDownTime(at index: Int){
        countDownHour = hourOfPrayerTime! - currentHour!
        countDownMinute = minuteOfPrayTime! - currentMinute!
        if countDownMinute < 0 {
            countDownMinute = 59 - countDownMinute
            countDownHour = countDownHour - 1
        }
        indexOfNextPrayer = index
        updateNextPrayerColores()
       
        
    }
    
    
 
    //make the next prayer  bold to destinguish it
    func updateNextPrayerColores(){
        switch(indexOfNextPrayer){
        case 0 :do {
            makeBold(atPrayer: fajerPrayer, atTime: fajerPrayerTime)
            makeBright(atPrayer: ishaPrayer, atTime: ishaPrayerTime)
            }
        case 1 :do {
            makeBold(atPrayer: dohorPrayer, atTime: dohorPrayerTime)
            makeBright(atPrayer: fajerPrayer, atTime: fajerPrayerTime)
            }
        case 2 :do {
            makeBold(atPrayer: aserPrayer, atTime: aserPrayerTime)
            makeBright(atPrayer: dohorPrayer, atTime: dohorPrayerTime)
            }
        case 3 :do {
            makeBold(atPrayer: maghrebPrayer, atTime: maghrebPrayerTime)
            makeBright(atPrayer: aserPrayer, atTime: aserPrayerTime)
            }
        case 4 :do {
            makeBold(atPrayer: ishaPrayer, atTime: ishaPrayerTime)
            makeBright(atPrayer: maghrebPrayer, atTime: maghrebPrayerTime)
            }
        default:print("error")
            
            
        
     

    }
    }
    
    
    
    
    @objc func updateTimer() {
        
        isTimerRunning = !isTimerRunning ? isTimerRunning : isTimerRunning
        
        if countDownSeconds == 0 {
            
            if countDownMinute == 0{
                //  countDownMinute = 59
                if countDownHour == 0 {
                    // here is the time for azan
                    determineTheNextPrayer()
                    playSound()
                    
                }else{
                    countDownHour -= 1
                    countDownMinute = 59
                    countDownSeconds = 59
                }
            }else{
                countDownMinute -= 1
                countDownSeconds = 59
            }
        }else{
            countDownSeconds -= 1
        }
        nextPrayerTime.text = "\(countDownHour):\(countDownMinute):\(countDownSeconds)"
        
        //set the notification
        if countDownHour == 0 && countDownMinute == 5 && countDownSeconds == 0 {
            
            sendNotification()
        }
    }
    
    
    
    
    func getLocation(){
      
        if  UserDefaults.standard.double(forKey: "lat") != nil &&  UserDefaults.standard.double(forKey: "long") != nil {
            lat = UserDefaults.standard.double(forKey: "lat")
            long = UserDefaults.standard.double(forKey: "long")
            timezone()
            
        }else{
            loctionManger.startUpdatingLocation()
            locationManager(CLLocationManager.init(), didUpdateLocations: [CLLocation].init())
          
        }
    }
    
    
    
    
    func makeBold(atPrayer prayerLabel: UILabel ,atTime prayerTime: UILabel){
        //make the labels black to let the user destinguesh between prayers
        prayerLabel.backgroundColor = UIColor(hexString: "023F56").withAlphaComponent(0.5)
        prayerTime.backgroundColor = UIColor(hexString: "023F56").withAlphaComponent(0.5)

        }
    

    
    
    func makeBright(atPrayer prayerLabels: UILabel, atTime prayerTime: UILabel){
        prayerLabels.backgroundColor = UIColor(hexString: "023F56").withAlphaComponent(0)
        prayerTime.backgroundColor = UIColor(hexString: "023F56").withAlphaComponent(0)
    }
    
    
    
    
   
    
    func sendNotification(){
        let prayers = ["fajer","dohor","asr","maghreb","isha"]
        
        let content = UNMutableNotificationContent()
        content.title = "\(prayers[indexOfNextPrayer]) azan will be after 5 minutes"
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "azanSoon", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    
  
    
    
    
    
    func convertToAM(time : Int , prayNumber: Int) -> String{
        
        if time > 12 {
            
            return "\(time - 12) : \(Int(timesOfPrayers[prayNumber].split(separator: ":")[1])!) PM"
           
        }
        else {
            
            return "\(time) : \(Int(timesOfPrayers[prayNumber].split(separator: ":")[1])!) AM" }
    }
    
    
    
    
    func getHour(prayNumber : Int) -> Int{
        
        return Int(timesOfPrayers[prayNumber].split(separator: ":")[0])!
    }
    
}







//
//  ShowCityViewController.swift
//  prayer times
//
//  Created by باسم امام on ٢١ شعبان، ١٤٣٩ هـ.
//  Copyright © ١٤٣٩ هـ hammam abdulaziz. All rights reserved.
//

import UIKit
import  Alamofire
import SwiftyJSON

import SVProgressHUD

class DisplayAnotherCity: UIViewController {
    var CityName : String = ""
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
    //MARK: locations varibels
    // create variables of latitude and longitude
    var lat : String = ""
    var long : String = ""
    var timeZone : String = ""
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
    //MARK:- Buttons
    //convert the time form
    @IBAction func homeButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
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
    
    
    
    
    //git the prayer time and convert it in am,pm mode
    func convertToAM(time : Int , prayNumber: Int) -> String{
        if time > 12 {
            
            if time < 22{
                return "0\(time - 12):\(Int(timesOfPrayers[prayNumber].split(separator: ":")[1])!) PM"
            }else{
                return "\(time - 12):\(Int(timesOfPrayers[prayNumber].split(separator: ":")[1])!) PM"
            }
        }
        else {
            
            if time < 10{
                return "0\(time):\(Int(timesOfPrayers[prayNumber].split(separator: ":")[1])!) AM"
            }else{
                return "\(time):\(Int(timesOfPrayers[prayNumber].split(separator: ":")[1])!) AM"
            }
            
        }
    }
    
    
    
    
    //git hour of prayer time
    func getHour(prayNumber : Int) -> Int{
        return Int(timesOfPrayers[prayNumber].split(separator: ":")[0])!
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show()
        cityNameLabel.text = CityName // show city name
        
        TimeZoneAPI()
        checkIfJumaaOrNot()
    }
    
    
    
    
    // git location zone and timezone
    func TimeZoneAPI(){
        let urls = "https://timezoneapi.io/api/address/?"+CityName // api TimeZone
        Alamofire.request(urls, method: .get)
            .responseJSON { response in
                if response.result.isSuccess {
                    // save JSON result in variable
                    let APITime : JSON = JSON(response.result.value!)
                    // get loction zone
                    let LoctionZone = APITime["data"]["addresses"][0]["location"].stringValue
                    // get lat and sotry it in varbel
                    if let range = LoctionZone.range(of: ",") {
                        self.lat = String(LoctionZone[LoctionZone.startIndex..<range.lowerBound])
                        print(self.lat)
                    }
                    // get long and sotry it in varbel
                    if let range = LoctionZone.range(of: ",") {
                        self.long = String(LoctionZone[range.upperBound...])
                        print(self.long)
                    }
                    // get timezone
                    let TZone = APITime["data"]["addresses"][0]["datetime"]["offset_gmt"].stringValue
                    // get timezone and sotry it in varbel
                    if let range = TZone.range(of: ":") {
                       self.timeZone = String(TZone[TZone.startIndex..<range.lowerBound])
                        print(self.timeZone)
                    }
                    // call api pray method
                    self.API(lats : self.lat, longs : self.long , timeZones: Int(self.timeZone)!)
                } else {
                    print("Error: \(String(describing: response.result.error))")
                }
        }
    }
    
    
    
    
    //  api pray method
    func API ( lats : String , longs : String , timeZones : Int){
        print(timeZones)
        // url of API
        let urls = "http://api.islamhouse.com/v1/Xm9B2ZoddJrvoyGk/services/praytime/get-times/Makkah/"+lats+"/"+longs+"/\(timeZones)/json"
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
                   
                    self.determineTheNextPrayer()
                } else {
                    print("Error: \(String(describing: response.result.error))")
                }
        }
    }
    
    
    
    
    //MARK:- get and calculate data from fetched data
    //chick which is the next prayer
    func determineTheNextPrayer(){
        fetchCurrentTime()
        
        for index in 0...4{
            getPrayerTime(at: index)
            
            if currentHour! < hourOfPrayerTime! {
                setCountDownTime(at: index)
                break
            }else if currentHour! == hourOfPrayerTime!{
                if currentMinute! < minuteOfPrayTime!{
                    setCountDownTime(at: index)
                }else {
                    // if current minutes is greater so it will count to the next pray
                    getPrayerTime(at: index + 1)
                    setCountDownTime(at: index + 1)
                }
                break
            }
        }
        //to show the result on screen and update it every second
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(MainCity.updateTimer)), userInfo: nil, repeats: true)
        SVProgressHUD.dismiss()
    }
    
    
    
    
    //get the currunt time
    func fetchCurrentTime(){
        let date = Date()
        let calendar = Calendar.current
        currentHour = calendar.component(.hour, from: date)
        currentMinute = calendar.component(.minute, from: date)
        countDownSeconds = 59 - calendar.component(.second, from: date)
    }
    
    
    
    
    //get prayer time of the determined prayer from results of api
    func getPrayerTime(at index: Int){
        hourOfPrayerTime = Int(timesOfPrayers[index].split(separator: ":")[0])!
        minuteOfPrayTime = Int(timesOfPrayers[index].split(separator: ":")[1])!
    }
    
    
    
    
    //compare current time to prayers time to determine the next prayer
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
    
    
    
    
    //MARK:- show updates on screen
    //make the next prayer bold to destinguish it
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
    
    
    
    
    //make the determined prayer bold to distinguesh it between the others
    func makeBold(atPrayer prayerLabel: UILabel ,atTime prayerTime: UILabel){
        //make the labels black to let the user destinguesh between prayers
        prayerLabel.backgroundColor = UIColor(hexString: "023F56").withAlphaComponent(0.5)
        prayerTime.backgroundColor = UIColor(hexString: "023F56").withAlphaComponent(0.5)
    }
    
    
    
    
    //if the pray is boled and no need for it make it go back to original
    func makeBright(atPrayer prayerLabels: UILabel, atTime prayerTime: UILabel){
        prayerLabels.backgroundColor = UIColor(hexString: "023F56").withAlphaComponent(0)
        prayerTime.backgroundColor = UIColor(hexString: "023F56").withAlphaComponent(0)
    }
    
    
    
    
    //updates the time on next prayer every second
    @objc func updateTimer() {
        isTimerRunning = !isTimerRunning ? isTimerRunning : isTimerRunning
        if countDownSeconds == 0 {
            
            if countDownMinute == 0{
                //  countDownMinute = 59
                if countDownHour == 0 {
                    // here is the time for azan
                    determineTheNextPrayer()
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
        }
    }
    
    
    
    
    //check jumaa
    func checkIfJumaaOrNot(){
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayInWeek = formatter.string(from: date)
        
        if (dayInWeek == "Friday"){
            dohorPrayer.text = "Friday"
        }
    }

}

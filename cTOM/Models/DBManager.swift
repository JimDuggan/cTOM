//
//  DBManager.swift
//  cTOM
//
//  Created by Conor O'Grady on 29/01/2018.
//  Copyright © 2018 Conor O'Grady. All rights reserved.
//

import Foundation
import UIKit


final class DBManager {
    
    static let sharedInstance = DBManager()
    
    static let dbFileName: String = "cTOM.db"
    static var ctomDB: FMDatabase!
    static var trialList = [Int]()
    static var trialWithVideo = [Int : String]()
    static var trialWithAnswer = [Int : String]()
    // dictionary to story correct answers with id's
    static var trialWithImages = [Int : [String]]()
    static var trialWithText = [Int : String]()
    static var trialWithAudio = [Int : String]()
    static var allParticipants = [String]()
    
    private init() {}
    
    static func checkForNoSession(test: Int) -> Bool {
        
        var sessionArray = [Int]()
        // array to store session_id's
        
        let query = "select ss.session_id from 'Trial-Session' as s inner join Trial as t on s.trial_id = t.trial_id inner join Session as ss on ss.session_id = s.session_id where t.test_id = \(test)"
        
        if let results:FMResultSet = DBManager.ctomDB.executeQuery(query, withArgumentsIn: []) {
            while results.next() == true {
                sessionArray.append(Int(results.int(forColumn: "session_id")))
            }
        }
        
        return sessionArray.isEmpty
        // check if array is empty
    }
    // checks if any results exist. Returns true if no rows in Trial-Session table
    
    static func getLatestResultSummary(test: Int) -> ResultSummary {
        var latestSession: Int?
        var latestParticipant: String?
        var sessionDate: String?
        
        let query = "select MAX(ss.session_id) as session_id, ss.participant_id, ss.timestamp from 'Trial-Session' as s inner join Trial as t on s.trial_id = t.trial_id inner join Session as ss on ss.session_id = s.session_id where t.test_id = \(test)"
        
        if let results:FMResultSet = DBManager.ctomDB.executeQuery(query, withArgumentsIn: []) {
            while results.next() == true {
                latestSession = (Int(results.int(forColumn: "session_id")))
                latestParticipant = results.string(forColumn: "participant_id")
                sessionDate = results.string(forColumn: "timestamp")
            }
        }
        // checks and stores latest session for passed in test_id
        
        var accuracyArray = [String]()
        var reactionArray = [Double]()
        
        let resultQuery = "select accuracy_measure, time_measure, answer_tag from 'Trial-Session' where session_id = \(latestSession!)"
        
        if let results:FMResultSet = DBManager.ctomDB.executeQuery(resultQuery, withArgumentsIn: []) {
            while results.next() == true {
                accuracyArray.append(results.string(forColumn: "accuracy_measure")!)
                reactionArray.append(Double((results.double(forColumn: "time_measure"))))
            }
        }
        // extracting results data for latest session id from above
        
        var accuracyTotal = 0
        let trialTotal = accuracyArray.count
        
        for measure in accuracyArray {
            
            if measure == "TRUE" {
                accuracyTotal += 1
            }
        }
        // iterating through results array and incrementing by 1 for every 'true'
        
        var totalReactionTime = 0.0
        var unansweredTrials = 0
        
        for reaction in reactionArray {
            if reaction != 0 {
                totalReactionTime += reaction
            } else {
                unansweredTrials += 1
            }
        }
        // iterating through reactionArray and getting total reaction time for rows where reaction time is not 0
        
        let averageReaction = totalReactionTime / (Double)(reactionArray.count - unansweredTrials)
        // get average reaction time
        
        return ResultSummary(accuracyMeasure: "\(accuracyTotal) / \(trialTotal)", sessionID: latestSession!, meanReaction: "\(String(format: "%.3f", averageReaction)) seconds", participantID: latestParticipant!, date: sessionDate!)
        // store and return result data in ResultSummary object
    }
    // gets most recent result data for passed in test
    
    static func createResultsCSV() -> URL {
        
        let deviceID = UIDevice.current.identifierForVendor!.uuidString
        // devices unique ID
        
        let fileName = "Results.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        // url for results csv file to be exported
        
        var csvText = "test_id,test_name,trial_id,trial_name,participant_id,gender,age,session_id,correct_answer,participant_answer,accuracy,time_measure,timestamp,trial_order,admin_id,admin_email,device_id\n"
        // headers for csv file
        
        let query = "select t.test_id, te.test_name, tr.trial_id, t.trial_name, s.participant_id, p.gender, p.age, tr.session_id, t.correct_answer_tag, tr.answer_tag, tr.accuracy_measure, tr.time_measure, tr.timestamp, tr.trial_order, s.admin_id, ad.email from 'Trial-Session' as tr inner join Trial as t on tr.trial_id = t.trial_id inner join Session as s on tr.session_id = s.session_id inner join Participant as p on s.participant_id = p.participant_id inner join Test as te on t.test_id = te.test_id inner join Administrator as ad on s.admin_id = ad.admin_id"
        
        if let results:FMResultSet = DBManager.ctomDB.executeQuery(query, withArgumentsIn: []) {
            while results.next() == true {
                var newLine = ""
                newLine.append(results.string(forColumn: "test_id")! + ",")
                newLine.append(results.string(forColumn: "test_name")! + ",")
                newLine.append(results.string(forColumn: "trial_id")! + ",")
                newLine.append(results.string(forColumn: "trial_name")! + ",")
                newLine.append(results.string(forColumn: "participant_id")! + ",")
                newLine.append(results.string(forColumn: "gender")! + ",")
                newLine.append(results.string(forColumn: "age")! + ",")
                newLine.append(results.string(forColumn: "session_id")! + ",")
                newLine.append(results.string(forColumn: "correct_answer_tag")! + ",")
                newLine.append(results.string(forColumn: "answer_tag")! + ",")
                newLine.append(results.string(forColumn: "accuracy_measure")! + ",")
                newLine.append(results.string(forColumn: "time_measure")! + ",")
                newLine.append(results.string(forColumn: "timestamp")! + ",")
                newLine.append(results.string(forColumn: "trial_order")! + ",")
                newLine.append(results.string(forColumn: "admin_id")! + ",")
                newLine.append(results.string(forColumn: "email")! + ",")
                newLine.append(deviceID + "\n")
                
                csvText.append(newLine)
            }
        }
        // creating new lines in csv file resulting from SQL query
        
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
        // writing csv data to url path created above
        
        return path!
    }
    // creates csv file to be exported with results data
    
    static func createNewSession() {
        let update = "INSERT INTO `Session`('participant_id', 'admin_id') VALUES (?, ?);"
        
        do {
            try DBManager.ctomDB.executeUpdate(update, values: [Trackers.currentParticipant!, Trackers.currentAdmin!])
        } catch {
            print(error)
        }
        // stores new session to database for current participant
        
        let query = "select * from Session order by session_id desc limit 1"
        
        if let results:FMResultSet = DBManager.ctomDB.executeQuery(query, withArgumentsIn: []) {
            while results.next() == true {
                Trackers.currentSession = (Int(results.int(forColumn: "session_id")))
            }
        }
        // check last record to retrieve session_id and store to currentSession variable
    }
    
    static func getAllAddedParticipants() {
        allParticipants.removeAll()
        
        let query = "select participant_id from Participant"
        
        if let results:FMResultSet = DBManager.ctomDB.executeQuery(query, withArgumentsIn: []) {
            while results.next() == true {
                allParticipants.append(String((results.string(forColumn: "participant_id"))!))
            }
        }
    }
    // stores all added participants to allParticipants String array
    
    static func checkParticipantID(id: String, age: String, gender: String) -> Bool {
        let query = "select * from Participant where participant_id = \"\(id)\""
        
        if let results:FMResultSet = DBManager.ctomDB.executeQuery(query, withArgumentsIn: []) {
            while results.next() == true {
                if results.string(forColumn: "participant_id") == id {
                    print("id already exists")
                    return false
                }
            }
        }
        // return false if participant_id already exists
        
        let update = "INSERT INTO `Participant`(`participant_id`, `gender`, `age`, `admin_id`) VALUES (?, ?, ?, ?);"
        
        do {
            try DBManager.ctomDB.executeUpdate(update, values: [id, gender, age, Trackers.currentAdmin!])
        } catch {
            print(error)
        }
        // store new participant and return true otherwise
        
        return true
    }
    // Checks database to participant_id is not already in use -> used for new participant
    
    
    static func getCurrentAdmin(email: String) -> Int {
        
        var currentAdmin: Int?
        let query = "select * from Administrator where email = \"\(email)\""
        
        if let results:FMResultSet = DBManager.ctomDB.executeQuery(query, withArgumentsIn: []) {
            while results.next() == true {
                currentAdmin = Int(results.int(forColumn: "admin_id"))
                Trackers.currentAdminFirstName = results.string(forColumn: "first_name")
            }
        }
        
        return currentAdmin!
    }
    // retrieves id for currently logged in admin and stores admin first name in Trackers class
    
    static func checkEmailAndPasswordCorrect(email: String, password: String) -> Bool {
        let query = "select * from Administrator where email = \"\(email)\""
        
        if let results:FMResultSet = DBManager.ctomDB.executeQuery(query, withArgumentsIn: []) {
            while results.next() == true {
                if results.string(forColumn: "password") == password {
                    return true
                } else {
                    print("incorrect password")
                }
            }
        } else {
            print("incorrect email")
            print(query)
        }
        return false
    }
    // Checks database to ensure email and password exist -> used for login
    
    static func checkEmailForRegister(email: String, password: String, fName: String, lName: String) -> Bool {
        let query = "select * from Administrator where email = \"\(email)\""
        
        if let results:FMResultSet = DBManager.ctomDB.executeQuery(query, withArgumentsIn: []) {
            while results.next() == true {
                if results.string(forColumn: "email") == email {
                    print("email already exists")
                    return false
                }
            }
        }
        
        let update = "INSERT INTO `Administrator`(`password`, `first_name`, `surname`, 'email') VALUES (?, ?, ?, ?);"
        
        do {
            try DBManager.ctomDB.executeUpdate(update, values: [password, fName, lName, email])
        } catch {
            print(error)
        }
        
        return true
    }
    // Checks database to ensure email is not already in use -> used for register
    
    static func getTrialInfoForTest(test: Int) {
        if Trackers.currentTest == test {
            
            let query = "select * from Trial where test_id = \(test)"
            
            let results:FMResultSet? = DBManager.ctomDB.executeQuery(query, withArgumentsIn: [])
            
            while results?.next() == true {
                trialList.append(Int((results?.int(forColumn: "trial_id"))!))
                trialWithAnswer[Int((results?.int(forColumn: "trial_id"))!)] = String((results?.string(forColumn: "correct_answer_tag"))!)
            }
            
        }
    }
    // extracts video paths for specific test and stors in array. Also store trial id and correct answers in dictionary
    
    
    static func getImageDataForTest() {
        for trial in trialList {
        
            let query = "select t.media_id, m.name, m.media_type from 'Trial-Media' as t inner join Media as m on t.media_id = m.media_id where t.trial_id = \(trial) AND m.media_type = 'Image'"
            
            let results:FMResultSet? = DBManager.ctomDB.executeQuery(query, withArgumentsIn: [])
            var imageArray = [String]()
            
            while results?.next() == true {
                imageArray.append(String((results?.string(forColumn: "name"))!))
            }
            
            trialWithImages[trial] = imageArray
        }
    }
    // returns dict with current trial list and corresponding image file names
    
    
    static func getTextDataForTest() {
        for trial in trialList {
            
            let query = "select t.media_id, m.name, m.media_type from 'Trial-Media' as t inner join Media as m on t.media_id = m.media_id where t.trial_id = \(trial) AND m.media_type = 'Text'"
            
            let results:FMResultSet? = DBManager.ctomDB.executeQuery(query, withArgumentsIn: [])
            
            while results?.next() == true {
                trialWithText[trial] = (results?.string(forColumn: "name"))!
            }
        }
    }
    // returns dict with current trial list and corresponding text file names
    
    
    static func getAudioDataForTest() {
        for trial in trialList {
            
            let query = "select t.media_id, m.name, m.media_type from 'Trial-Media' as t inner join Media as m on t.media_id = m.media_id where t.trial_id = \(trial) AND m.media_type = 'Audio'"
            
            let results:FMResultSet? = DBManager.ctomDB.executeQuery(query, withArgumentsIn: [])
            
            while results?.next() == true {
                trialWithAudio[trial] = (results?.string(forColumn: "name"))!
            }
        }
        
    }
    // returns dict with current trial list and corresponding audio file names
    
    static func getLongestMediaForTest(test: Int) -> Double {
        
        var longestDuration: Double?

        let query = "select max(m.second_duration) as 'second_duration' from Media as m inner join 'Trial-Media' as t on m.media_id = t.media_id inner join 'Trial' as r on t.trial_id = r.trial_id where r.test_id = \(test)"
        
        let results:FMResultSet? = DBManager.ctomDB.executeQuery(query, withArgumentsIn: [])
        
        while results?.next() == true {
            longestDuration = (Double)((results?.double(forColumn: "second_duration"))!)
        }
      
        return longestDuration!
    }
    // returns double in seconds for trial with longest duration
    
    static func getVideoDataForTest() {
        for trial in trialList {
            
            let query = "select t.media_id, m.name, m.media_type from 'Trial-Media' as t inner join Media as m on t.media_id = m.media_id where t.trial_id = \(trial) AND m.media_type = 'Video'"
            
            let results:FMResultSet? = DBManager.ctomDB.executeQuery(query, withArgumentsIn: [])
            
            while results?.next() == true {
                trialWithVideo[trial] = (results?.string(forColumn: "name"))!
            }
        }
        
    }
    // returns dict with current trial list and corresponding video file names
    
    static func storeResultsToDatabase() {
        
        let update = "INSERT INTO `Trial-Session`(`trial_id`, 'session_id', `answer_tag`, `accuracy_measure`, 'time_measure', 'trial_order', 'timestamp') VALUES (?, ?, ?, ?, ?, ?, ?);"
        
        for result in Trackers.resultsArray {
            
            do {
                try DBManager.ctomDB.executeUpdate(update, values: [result.getTrialID(), result.getSession(), result.getAnswerTag(), result.getAccuracyMeasure(), result.getSecondMeasure(), result.getOrder(), result.getDate()])
            } catch {
                print(error)
            }
        }
    }
    // Store data from various result objects to DB
    
    
    static func copyDatabaseIfNeeded() {
        // Move database file from bundle to documents folder
        
        let fileManager = FileManager.default
        
        let documentsUrl = fileManager.urls(for: .documentDirectory,
                                            in: .userDomainMask)
        
        guard documentsUrl.count != 0 else {
            return // Could not find documents URL
        }
        
        let finalDatabaseURL = documentsUrl.first!.appendingPathComponent(DBManager.dbFileName)
        
        if !( (try? finalDatabaseURL.checkResourceIsReachable()) ?? false) {
            print("DB does not exist in documents folder")
            
            let documentsURL = Bundle.main.resourceURL?.appendingPathComponent(DBManager.dbFileName)
            
            do {
                try fileManager.copyItem(atPath: (documentsURL?.path)!, toPath: finalDatabaseURL.path)
            } catch let error as NSError {
                print("Couldn't copy file to final location! Error:\(error.description)")
            }
            
        } else {
            print("Database file found at path: \(finalDatabaseURL.path)")
        }
        
    }
    
    static func openDatabase() {
        
        let fileManager = FileManager.default
        let dirPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        // get directory path for apps documents directory
        
        let dbPath = dirPath[0].appendingPathComponent(DBManager.dbFileName).path
        // retrieve path of .db file
        
        DBManager.ctomDB = FMDatabase(path: dbPath as String)
        // create DB
        
        DBManager.ctomDB.open()

        
    }
    
    
}

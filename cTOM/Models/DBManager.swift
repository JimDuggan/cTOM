//
//  DBManager.swift
//  cTOM
//
//  Created by Conor O'Grady on 29/01/2018.
//  Copyright © 2018 Conor O'Grady. All rights reserved.
//

import Foundation


final class DBManager {
    
    static let sharedInstance = DBManager()
    
    static let dbFileName: String = "cTOM.db"
    static var ctomDB: FMDatabase!
    static var trialList = [Int]()
    static var trialWithVideo = [Int : String]()
    static var trialWithAnswer = [Int : Int]()
    // dictionary to story correct answers with id's
    static var trialWithImages = [Int : [String]]()
    static var trialWithText = [Int : String]()
    static var trialWithAudio = [Int : String]()
    
    private init() {}
    
    
    static func getTrialInfoForTest(test: Int) {
        if Trackers.currentTest == test {
            
            let query = "select * from Trial where test_id = \(test)"
            // will need to change this to join for stories trials
            
            let results:FMResultSet? = DBManager.ctomDB.executeQuery(query, withArgumentsIn: [])
            
            while results?.next() == true {
                trialList.append(Int((results?.int(forColumn: "trial_id"))!))
                trialWithAnswer[Int((results?.int(forColumn: "trial_id"))!)] = Int((results?.int(forColumn: "correct_answer_tag"))!)
            }
            
        }
    }
    // extracts video paths for specific test and stors in array. Also store trial id and correct answers in dictionary
    
    
    static func getImageDataForTest() {
        for trial in trialList {
        
            let query = "select t.media_id, m.name, m.media_type from 'Trial-Media' as t inner join Media as m on t.media_id = m.media_id where t.trial_id = \(trial) AND m.media_type = 'Image' order by t.'order'"
            
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
    
    
    static func getVideoDataForTest() {
        for trial in trialList {
            
            let query = "select t.media_id, m.name, m.media_type from 'Trial-Media' as t inner join Media as m on t.media_id = m.media_id where t.trial_id = \(trial) AND m.media_type = 'Video'"
            
            let results:FMResultSet? = DBManager.ctomDB.executeQuery(query, withArgumentsIn: [])
            
            while results?.next() == true {
                trialWithVideo[trial] = (results?.string(forColumn: "name"))!
            }
        }
        
    }
    // returns dict with current trial list and corresponding audio file names
    
    
    
    static func storeResultsToDatabase() {
        
        let update = "INSERT INTO `Trial-Session`(`trial_id`, `answer_tag`, `accuracy_measure`, 'time_measure', 'trial_order', 'timestamp') VALUES (?, ?, ?, ?, ?, ?);"
        
        for result in Trackers.resultsArray {
            
            do {
                try DBManager.ctomDB.executeUpdate(update, values: [result.getTrialID(), result.getAnswerTag(), result.getAccuracyMeasure(), result.getSecondMeasure(), result.getOrder(), result.getDate()])
            } catch {
                print(error)
            }
        }
    }
    // Store various data from various result objects to DB
    
    
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

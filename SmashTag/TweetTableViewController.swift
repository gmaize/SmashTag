//
//  TweetTableViewController.swift
//  SmashTag
//
//  Created by Gianni Maize on 6/14/17.
//  Copyright © 2017 Maize Man. All rights reserved.
//

import UIKit
import Twitter

class TweetTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField?.delegate = self
			if searchText != nil {
				searchTextField.text = searchText
				title = searchText
			}
        }
    }
    
    // when the return (i.e. Search) button is pressed in the keyboard
    // we go off to search for the text in the searchTextField
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == searchTextField {
            searchText = searchTextField.text
        }
        return true
    }
	
	
	var tweets = [Array<Twitter.Tweet>]()
    
    var searchText : String? {
        didSet {
            searchTextField?.text = searchText
            searchTextField?.resignFirstResponder()
            lastTwitterRequest = nil
            tweets.removeAll()
            tableView.reloadData()
            searchForTweets()
            title = searchText
			RecentSearchTerms.add(term: searchText!)
        }
    }
	
	func insertTweets(_ newTweets: [Twitter.Tweet]) {
		self.tweets.insert(newTweets, at: 0)
		self.tableView.insertSections([0], with: .fade)
	}
	
    private func twitterRequest() -> Twitter.Request? {
        if let query = searchText, !query.isEmpty {
            return Twitter.Request(search: query, count: 100)
        }
        return nil
    }
    
    private var lastTwitterRequest: Twitter.Request?
    
    private func searchForTweets() {
        if let request = twitterRequest() {
            lastTwitterRequest = request
            request.fetchTweets { [weak self] newTweets in
                DispatchQueue.main.async {
                    if request == self?.lastTwitterRequest {
                        self?.insertTweets(newTweets)
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        // we use the row height in the storyboard as an "estimate"
        tableView.estimatedRowHeight = tableView.rowHeight
        // but use whatever autolayout says the height should be as the actual row height
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tweets.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //grab available Tweet cell container
        let cell = tableView.dequeueReusableCell(withIdentifier: "Tweet", for: indexPath)
        //get the 'Tweet' associated with this section & row
        let tweet = tweets[indexPath.section][indexPath.row]
        if let tweetCell = cell as? TweetTableViewCell {
            tweetCell.tweet = tweet //set the tweet cell's content
        }
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destinationViewController = segue.destination
        if let navigationViewController = destinationViewController as? UINavigationController {
            destinationViewController = navigationViewController.visibleViewController ?? destinationViewController
        }
        if let selectedTweetCell = sender as? TweetTableViewCell,
            let mentionsTableViewController = destinationViewController as? TweetMentionsTableViewController {
                mentionsTableViewController.tweet = selectedTweetCell.tweet
		}
	}
}

class RecentSearchTerms {
	static let maxTerms = 100
	static let defaults = UserDefaults.standard
	
	static func getTerms() -> [String] {
		return defaults.stringArray(forKey: "RecentSearchTerms") ?? [String]()
	}
	
	static func add(term: String) {
		let term = term.lowercased().trimmingCharacters(in: .whitespaces)

		var recentTerms = self.getTerms()
		if recentTerms.contains(term) {
			recentTerms.remove(at: recentTerms.index(of: term)!)
		} else if recentTerms.count == maxTerms {
			recentTerms.remove(at: maxTerms - 1)
		}
		recentTerms.insert(term, at: 0)
		defaults.set(recentTerms, forKey: "RecentSearchTerms")
	}
}


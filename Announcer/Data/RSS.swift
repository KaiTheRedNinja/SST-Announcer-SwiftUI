//
//  RSS.swift
//  Announcer
//
//  Created by AYAAN JAIN stu on 4/1/23.
//

import Foundation
import FeedKit
import MarkdownUI

/**
 Source URL for the Blog

 - important: Ensure that the URL is set to the correct blog before production.

 # Production Blog URL
 [http://studentsblog.sst.edu.sg](http://studentsblog.sst.edu.sg)

 # Development Blog URL
 [https://testannouncer.blogspot.com](https://testannouncer.blogspot.com)

 This constant stores the URL for the blog linked to the RSS feed.
 */
let blogURL = "http://studentsblog.sst.edu.sg"

/**
 URL for the blogURL's RSS feed

 - important: This will only work for blogs created on Blogger.

 This URL is the blogURL but with the path of the RSS feed added to the back.
 */
let rssURL = "\(blogURL)/feeds/posts/default"

extension PostManager {

    /**
     Fetches the blog posts from the blogURL

     - returns: An array of `Post` from the blog
     - important: This method will handle errors it receives by returning an empty array

     This method will fetch the posts from the blog and return it as [Post]
     */
    static func fetchValues(range: Range<Int>) throws -> [Post] {
        // since its 1 indexed, use the lowerbound+1 as the start index
        let query = "\(rssURL)/?start-index=\(range.lowerBound+1)&max-results=\(range.count)"

        // turn it into a URL and parse it
        let url = URL(string: query)!
        let parser = FeedParser(URL: url)
        let result = parser.parse()

        // if it was successful, then return the conversion.
        switch result {
        case .success(let feed):
            let feed = feed.atomFeed

            return convertFromEntries(feed: (feed?.entries)!)
        case .failure(let error):
            throw error
        }
    }

    /**
     Converts an array of `AtomFeedEntry` to an array of `Post`

     - returns: An array of `Post`

     - parameters:
     - feed: An array of `AtomFeedEntry`

     This method will convert the array of `AtomFeedEntry` from `FeedKit` to an array of `Post`.
     */
    static func convertFromEntries(feed: [AtomFeedEntry]) -> [Post] {
        var posts = [Post]()
        for entry in feed {

            let title = entry.title ?? ""
            let content = (entry.content?.value) ?? ""
            let date = entry.published ?? .now

            let categories = entry.categories?.compactMap({ entry in
                entry.attributes?.term
            }) ?? []

            var post = Post(title: title,
                            content: content,
                            date: date,
                            pinned: false,
                            read: false,
                            reminderDate: nil,
                            categories: categories)

            let pTitle = post.postTitle
            post.read = PostManager.readPosts.contains(pTitle)
            post.reminderDate = PostManager.reminderDates[pTitle]
            post.userCategories = PostManager.userCategoriesForPosts[pTitle]

            posts.append(post)
        }
        return posts
    }

    /// Performs a "zipper merge" between `newItems` and ``PostManager.postStorage``
    /// - Parameter newItems: The items to zipper merge into post storage
    ///
    /// The exact process that occurs goes somewhat like this:
    /// In this implementation, we use two pointers, one for `storage` and one for `newItems`, to iterate
    /// through both arrays simultaneously. We compare the current item from each array and append the
    /// smaller item to the `combinedArray`. If the items are equal, we append one from storage and move
    /// both pointers forward. Once we've processed all items from one array, we append any remaining items
    /// from the other array to the `combinedArray`.
    ///
    /// This solution has a time complexity of O(n) as we process each element in the input arrays once, and
    /// is more efficent than an append-sort method as it saves the time and space of sorting the array at the end.
    static func addPostsToStorage(newItems: [Post]) {
        let storage = PostManager.postStorage

        var combinedArray: [Post] = []
        var storageIndex = 0
        var newItemsIndex = 0

        // do a "zipper merge" of storage and the new items array
        while storageIndex < storage.count && newItemsIndex < newItems.count {
            let storageItem = storage.elements[storageIndex].value
            let newItem = newItems[newItemsIndex]

            if storageItem < newItem {
                combinedArray.append(storageItem)
                storageIndex += 1
            } else if newItem < storageItem {
                combinedArray.append(newItem)
                newItemsIndex += 1
            } else {
                combinedArray.append(storageItem)
                storageIndex += 1
                newItemsIndex += 1
            }
        }

        // of the following two while loops, only one will run. As the while loop above
        // is an AND statement, when one index hits the maximum, it will break. These
        // while loops are just the "cleaners" that append any remaining items.

        // clear any remaining storage items
        while storageIndex < storage.count {
            combinedArray.append(storage.elements[storageIndex].value)
            storageIndex += 1
        }

        // clear any remaining new items
        while newItemsIndex < newItems.count {
            combinedArray.append(newItems[newItemsIndex])
            newItemsIndex += 1
        }
        let keys = combinedArray.map { $0.postTitle }
        PostManager.postStorage = .init(uniqueKeys: keys,
                                        values: combinedArray)

        Log.info("Post manager things: \(keys.map({ $0.description }))")
    }
}

private func < (lhs: Post, rhs: Post) -> Bool {
    lhs.date.timeIntervalSince1970 < rhs.date.timeIntervalSince1970
}

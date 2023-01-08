//
//  AnnouncementDetailView+Components.swift
//  Announcer
//
//  Created by Kai Quan Tay on 8/1/23.
//

import SwiftUI

extension AnnouncementDetailView {
    var title: some View {
        // title
        HStack {
            Text(post.title)
                .bold()
                .multilineTextAlignment(.leading)
        }
        .font(.title2)
        .padding(.bottom, -5)
    }

    var categories: some View {
        // categories
        HStack {
            CategoryScrollView(post: $post)
                .font(.subheadline)
            Button {
                // add category
                showEditCategoryView.toggle()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .opacity(0.6)
            }
        }
    }

    var postAndReminder: some View {
        HStack {
            TimeAndReminder(post: $post)
                .font(.subheadline)
            Spacer()
            Button {
                showEditReminderDateView.toggle()
            } label: {
                if post.reminderDate == nil {
                    Image(systemName: "calendar.badge.plus")
                } else {
                    Image(systemName: "slider.horizontal.3")
                }
            }
            .opacity(0.6)
        }
    }

    var links: some View {
        VStack(alignment: .leading) {
            ForEach(post.getLinks(), id: \.absoluteString) { url in
                Text(url.description)
                    .underline()
                    .foregroundColor(.accentColor)
                    .lineLimit(1)
                    .onTapGesture {
                        safariViewURL = url
                        showSafariView = true
                    }
            }
        }
    }

    var addNewCategory: some View {
        NavigationView {
            EditCategoriesView(post: $post,
                               posts: $posts,
                               showEditCategoryView: $showEditCategoryView)
        }
    }

    var editReminderDate: some View {
        NavigationView {
            EditReminderDateView(post: $post,
                                 showEditReminderDateView: $showEditReminderDateView)
        }
    }
}
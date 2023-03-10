//
//  LinkPreview.swift
//  Announcer
//
//  Created by Kai Quan Tay on 7/3/23.
//

import SwiftUI
import LinkPresentation
import PostManager

class CustomLinkView: LPLinkView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: 0,
               height: super.intrinsicContentSize.height)
    }
}

struct LinkPreview: UIViewRepresentable {

    typealias UIViewType = CustomLinkView

    var metadata: LPLinkMetadata?

    init(metadata: LPLinkMetadata? = nil) {
        guard let metadata else { return }
        self.metadata = .init()
        self.metadata?.url = metadata.url
        self.metadata?.originalURL = metadata.originalURL
        self.metadata?.title = metadata.title
        self.metadata?.iconProvider = metadata.iconProvider
    }

    func makeUIView(context: Context) -> CustomLinkView {
        guard let metadata = metadata else { return CustomLinkView() }
        let linkView = CustomLinkView(metadata: metadata)
        return linkView
    }

    func updateUIView(_ uiView: CustomLinkView, context: Context) {
    }

    static func fetchMetadata(for url: URL,
                       completion: @escaping (Result<LPLinkMetadata, Error>) -> Void) {

        let metadataProvider = LPMetadataProvider()
        metadataProvider.startFetchingMetadata(for: url) { (metadata, error) in
            loadQueue.async {
                if let error = error {
                    print(error)
                    completion(.failure(error))
                    return
                }
                if let metadata = metadata {
                    completion(.success(metadata))
                }
            }
        }
    }
}

struct LinkPreview_Previews: PreviewProvider {
    static var previews: some View {
        LinkPreview()
    }
}

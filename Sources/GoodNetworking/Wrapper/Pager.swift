//
//  ResourcePager.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 25/10/2024.
//

import SwiftUI

@available(iOS 17.0, *)
public struct Pager<R: Listable>: View {

    @State private var isFinished = false
    private let resource: () -> Resource<R>

    public init(resource: @escaping @autoclosure () -> Resource<R>) {
        self.resource = resource
    }

    public var body: some View {
        Group {
            if !isFinished {
                ProgressView()
            } else {
                Rectangle().frame(width: 0, height: 0).hidden()
            }
        }
        .onAppear { Task.detached { await getNextPage() }}
    }

    private func getNextPage() async {
        if let nextPage = resource().nextPageRequest() {
            isFinished = false
            do {
                try await resource().list(request: nextPage)
            } catch {
                isFinished = true
            }
        } else {
            isFinished = true
        }
    }

}

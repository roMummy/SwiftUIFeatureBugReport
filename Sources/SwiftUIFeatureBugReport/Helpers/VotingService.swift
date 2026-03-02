//
//  VotingService.swift
//  SwiftUIFeatureBugReport
//
//  Created by Tom Redway on 25/09/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor public class VotingService: ObservableObject {

    @AppStorage("votedIssues") private var votedIssueData: Data = Data()
    
    private var votedIssues: Set<Int> {
        
        get {
            (try? JSONDecoder().decode(Set<Int>.self, from: votedIssueData)) ?? []
        }
        
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                votedIssueData = encoded
            }
        }
    }
    
    public init() {}
    
    // MARK: - Public API
    
    public func hasVoted(for issueNumber: Int) -> Bool {
        
        votedIssues.contains(issueNumber)
    }
    
    public func addVote(to issueNumber: Int, using gitHubService: GitHubService) async throws {

        guard !hasVoted(for: issueNumber) else {
            
            throw VotingError.alreadyVoted
        }
        
        try await gitHubService.addVote(to: issueNumber)
        
        // Track locally to prevent future duplicate votes
        var voted = votedIssues
        voted.insert(issueNumber)
        votedIssues = voted
    }
}


@MainActor public class IssueOwnershipService {
    
    @AppStorage("ownedFeedbackIssues") private var ownedIssueData: Data = Data()
    
    private var ownedIssues: Set<Int> {
        
        get { (try? JSONDecoder().decode(Set<Int>.self, from: ownedIssueData)) ?? [] }
        set {
            
            if let encoded = try? JSONEncoder().encode(newValue) {
                
                ownedIssueData = encoded
            }
        }
    }
    
    public init() {}
    
    // Mark an issue as owned by this device
    public func markAsOwned(_ issueNumber: Int) {
        
        var owned = ownedIssues
        owned.insert(issueNumber)
        ownedIssues = owned
    }
    
    // Check if this device owns an issue
    public func ownsIssue(_ issueNumber: Int) -> Bool {
        
        ownedIssues.contains(issueNumber)
    }
    
    // Get all owned issue numbers
    public func getOwnedIssues() -> Set<Int> {
        
        return ownedIssues
    }
}


public enum VotingError: LocalizedError {
    
    case alreadyVoted
    case notVoted
    
    public var errorDescription: String? {
        
        switch self {
            
        case .alreadyVoted: return "You've already voted for this issue"
        case .notVoted: return "You haven't voted for this issue"
        }
    }
}

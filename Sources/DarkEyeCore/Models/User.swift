//
//  User.swift
//  DarkEyeCore
//
//  Created by Amr Aboelela on 6/10/22.
//  Copyright © 2022 Amr Aboelela.
//

import Foundation
import SwiftLevelDB

public enum UserRole: String {
    case member
    case moderator
    case admin
}

public enum UserStatus: String {
    case pending // pending membership when a user first register.
    case active
    case suspended
}

@available(macOS 10.15.0, *)
public struct User: Codable, Hashable {
    public static let prefix = "user-"
    
    public var username: String
    public var password: String
    public var role: String?
    public var status: String?
    public var timeJoined: Int
    public var timeLoggedin: Int?
    public var url: String?

    // MARK: - Accessors

    public var userRole: UserRole {
        get {
            if let role = role, let result = UserRole(rawValue:role) {
                return result
            }
            return .member
        }
        set {
            self.role = newValue.rawValue
        }
    }
    
    public var userStatus: UserStatus {
        get {
            if let status = status, let result = UserStatus(rawValue:status) {
                return result
            }
            return .active
        }
        set {
            self.status = newValue.rawValue
        }
    }
    
    public var moderatorOrAdmin: Bool {
        return userRole == .moderator || userRole == .admin
    }
    
    public var active: Bool {
        return userStatus == .active
    }

    public var joinedDate: String {
        return Date.friendlyDateStringFrom(timeInterval: TimeInterval(timeJoined))
    }
    
    public var loggedinDate: String {
        if let timeLoggedin = timeLoggedin {
            return Date.friendlyDateStringFrom(timeInterval: TimeInterval(timeLoggedin))
        } else {
            return ""
        }
    }
    
    // MARK: - Factory methods
    
    public static func createWith(username: String) -> User {
        return User(username: username, password: "", timeJoined: Date.secondsSinceReferenceDate)
    }

    public static func userWith(username: String) async -> User? {
        if let user: User = await database.valueForKey(prefix + username) {
            return user
        } else {
            return nil
        }
    }

    // MARK: - Data handling

    public func update(location: String, url: String) -> User {
        var result = self
        result.url = url
        return result
    }

    // MARK: - Delegates

    public func hash(into hasher: inout Hasher) {
        hasher.combine(username)
    }
    
    // MARK: - Public functions

    public static func usernameExists(_ username: String) async -> Bool {
        if let _: User = await database.valueForKey(User.prefix + username) {
            return true
        } else {
            return false
        }
    }
    
    public static func users(withUsernamePrefix usernamePrefix: String) async -> [User] {
        var result = [User]()
        await database.enumerateKeysAndValues(backward: false, startingAtKey: nil, andPrefix: prefix + usernamePrefix) { (key, user: User, stop) in
            if user.userStatus != .suspended {
                result.append(user)
            }
        }
        return result
    }
    
}

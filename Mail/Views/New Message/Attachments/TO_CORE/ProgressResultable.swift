/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Combine
import Foundation
import InfomaniakCore

/// Some wrapper type that give initial access to a progress, and also to an async result
///
/// Helpful to manage UI tracking of complex subtasks using the `Progress` type
///  while working with the easy to use `Result` type.
protocol ProgressResultable {
    
    /// Success type
    associatedtype Success
    
    /// Error type
    associatedtype Failure: Error

    /// The progress associated with the current task
    var progress: Progress { get }

    /// The result associated with the current task
    /// Re-processed each time
    var result: Result<Success, Failure> { get async }
}

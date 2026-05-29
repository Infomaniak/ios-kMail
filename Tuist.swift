import Foundation
import ProjectDescription

let tuist = Tuist(
    fullHandle: "infomaniak/infomaniak-mail",
    xcodeCache: .xcodeCache(upload: false),
    project: .tuist(
        generationOptions: .options(
            enableCaching: false
        )
    )
)

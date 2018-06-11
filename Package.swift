// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "ProductManager",
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/skelpo/JWTMiddleware.git", from: "0.6.0"),
        .package(url: "https://github.com/skelpo/FluentQuery.git", .branch("mysql"))
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentMySQL", "Vapor", "JWTMiddleware", "MySQLFluentQuery"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)


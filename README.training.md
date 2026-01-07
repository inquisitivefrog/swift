
Installation
------------
1. https://www.swift.org/install/macos/

Project Layout
---------------
1. Package.swift
2. Sources/main.swift
3. Tests/mainTests.swift

Execution
---------
1. swift build
2. swift run
3. swift test
4. swift repl (IDE)

Deploy
------
1. https://developer.apple.com/testflight/
2. https://www.apple.com/app-store/

Documentation
-------------
1. https://www.w3schools.com/swift/swift_intro.asp
2. https://www.swift.org/documentation/

Rules
-----
1. iOS apps need a Mac with Xcode to build and run
2. ship apps to TestFlight or Apple App Store using your Apple developer account.
3. layout 
   a. Package.swift in top dir declares entry points into Sources/ and Tests/
   b. Sources/ subdir contains hook file and main.swift
   c. Tests/ subdir contains hook file and Tests.swift
4. Xcode tool use
   a. building and running the app
   b. testing the app using the ios simulator or the iphone if attached by cable
   c. managing the project by adding, updating files
   d. debugging the app while running
   e. app signing for device specific testing
   f. managing the core data model
5. Cursor tool use
   a. write all Swift code from user directives
   b. create the file structure
   c. design the architecture
   d. write Core Data model
   e. fix bugs
   f. explain how things work


Language Concepts
-----------------
1. filetype: main.swift
2. constant assignment (immutable)
   let name = "Tim"
3. variable assignment (mutable)
   var age = 24
   print(name + ", " + age)
4. variable type declaration (Int, Double, Bool, String)
   let pi: Double = 3.14159
   var count: Int = 3
5. string interpolation
   print("pi = \(pi), count = \(count)")
6. function
   func name(var1: type, var2: type) -> return_value {
     return  return_value
   }
   // function called
   print(name("go", "fish"))
7. semicolon
   let a: Int = 2; let b: String = "apple"
8. blocks with curly braces
   {
     let a: Int = 1
     let b: Int = 2
9. STDOUT
   print(\(a + b))
   pinrt(n, terminator: " ") // remove newline
10. built-in math functions
    abs, min, max
11. comments
    // single line
    /* multiple lines
    */
    /* outside nested
       /* inside */
    */
12. auto documentation
    /// anything here is passed to documentation
13. concatenation
    print("hello" + "world")
14. interpolation
    let a = 2
    print("a = \(a)")
15. multiple variable declarations
    var x = 1, y = 2, z = 3
16. type annotations
    let a: Int = 2
    var b: Bool = true
17. identifiers in lower camelcase, defaultTimeout
    names for variables, constants, types, functions
    Unicode ok, underscore ok, alphanumerics ok
18. reserved words
    if identifiers need to use same names as reserve words, then backtick escape to avoid confusion
19. constants in lower camelcase, defaultTimeout
    declaration of variables as constants is helpful when 
    a. constants need to be easily sorted and aggregated for later periodic change
    b. identifier names used can cause confusion with 

    

//
//  libIso18013_exampleUITestsLaunchTests.swift
//  libIso18013-exampleUITests
//
//  Created by Martina D'urso on 06/10/24.
//

import XCTest

final class libIso18013_exampleUITestsLaunchTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Initialize the app and launch it
        app = XCUIApplication()
        app.launch()
        
        // Continue after failure
        continueAfterFailure = false
    }
    
    func testInfoBoxViewWithTextSubtitle() throws {
        
        // Assicurati che il titolo sia presente
        let title = app.staticTexts["InfoBoxViewTitle"]
        XCTAssertTrue(title.exists)
        
        // Assicurati che il sottotitolo di testo sia presente
        let subtitle = app.staticTexts["InfoBoxViewSubtitle"]
        XCTAssertTrue(subtitle.exists)
    }
    
    func testInfoBoxViewWithImageSubtitle() throws {
        
        // Assicurati che il titolo sia presente
        let title = app.staticTexts["InfoBoxViewTitle"]
        XCTAssertTrue(title.exists)
        
        // Assicurati che il sottotitolo dell'immagine sia presente
        let image = app.images["InfoBoxViewSubtitleImage"]
        XCTAssertTrue(image.exists)
    }
}

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
    
    func testCustomTextFieldTypingAndClearButton() throws {
        // Assicurati che la CustomTextField sia visibile
        let textField = app.textFields["Inserisci testo..."]
        XCTAssertTrue(textField.exists)
        
        // Inserisci del testo nella CustomTextField
        textField.tap()
        textField.typeText("Prova di testo")
        
        // Verifica se il testo è stato inserito correttamente
        XCTAssertEqual(textField.value as? String, "Prova di testo")
        
        // Assicurati che il tasto di cancellazione sia visibile
        let clearButton = app.buttons["xmark.circle.fill"]
        XCTAssertTrue(clearButton.exists)
        
        // Clicca sul tasto di cancellazione per svuotare il campo di testo
        clearButton.tap()
        
        // Verifica se il testo è stato correttamente cancellato
        XCTAssertEqual(textField.label, "")
    }
}

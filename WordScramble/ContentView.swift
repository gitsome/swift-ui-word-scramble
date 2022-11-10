//
//  ContentView.swift
//  WordScramble
//
//  Created by john martin on 9/16/22.
//

import SwiftUI

enum FocusField: Hashable {
    case textField
}

struct WordListItem: View {
    
    var word: String
    
    @State private var viewLoaded = false
    
    var body: some View {
        
        HStack {
            Image(systemName: "\(word.count).circle.fill")
                .foregroundColor(viewLoaded ? .black : .blue)
                .rotation3DEffect(.degrees(Double(viewLoaded ? 0 : 360)), axis: (x: 0, y: 1, z: 0))
            Text(word)
                .foregroundColor(viewLoaded ? .black : .blue)
        }.onAppear {
            withAnimation (Animation.easeInOut(duration: 0.5).delay(0.15)) {
                viewLoaded = true
            }
        }
    }
}

struct ContentView: View {
        
    @State private var allWords: [String] = []
    
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showErrorMessage = false
    
    @State private var score = 0
        
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        NavigationView {
            
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [.gray, .white]), startPoint: .bottom, endPoint: .top)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    
                    Spacer()
                    
                    Text("Score: \(score)")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    TextField("Enter your word", text: $newWord)
                        .padding()
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .textField)
                        .onSubmit(addNewWord)
                        
                    List {
                        
                        Section ("Words") {
                            ForEach(usedWords, id: \.self) { word in
                                WordListItem(word: word)
                            }
                        }
                    }.listStyle(.insetGrouped)
                }
                .navigationTitle(rootWord)
                .toolbar {
                    Button("New Word", action: startNewGame)
                }
                .onAppear(perform: loadGame)
                .alert(errorTitle, isPresented: $showErrorMessage) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }.onTapGesture {
                    focusedField = nil
                }
            }
        }
    }
    
    func isNewWord (_ word: String) -> Bool {
        return !usedWords.contains(word)
    }
    
    func isSubsetOfLetters(_ word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        
        return true
    }
    
    func isRealWord (_ word: String) -> Bool {

        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let range = NSRange(location: 0, length: trimmedWord.utf16.count)
        let checker = UITextChecker()
        
        let misspelledRange = checker.rangeOfMisspelledWord(in: trimmedWord, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    func addNewWord() {
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validation checks
        let isLongEnough = answer.count > 2
        let isNew = isNewWord(answer)
        let isSubset = isSubsetOfLetters(answer)
        let isReal = isRealWord(answer)
        
        if !isLongEnough {
            errorTitle = "Keep Going!"
            errorMessage = "Your word must be at least 3 characters"
            showErrorMessage = true
            return
        }
        
        if !isNew {
            errorTitle = "Whoops"
            errorMessage = "You already used this word!"
            showErrorMessage = true
            return
        }
        
        if !isSubset {
            errorTitle = "Nope!"
            errorMessage = "Some of your letters are not in the root word."
            showErrorMessage = true
            return
        }
        
        if !isReal {
            errorTitle = "Sorry!"
            errorMessage = "That word is not in our dictionary. Try another!"
            showErrorMessage = true
            return
        }
            
        usedWords.insert(answer, at: 0)
        newWord = ""
        
        updateScore()
        
        focusedField = .textField
    }
    
    func updateScore () {
        score = usedWords.reduce(0){ $0 + $1.count }
    }
    
    func loadWords () -> [String] {
        
        if let fileURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let fileContents = try? String(contentsOf: fileURL) {
                return fileContents.components(separatedBy: "\n")
            }
        }
        
        return []
    }
    
    func loadGame () {
        
        let loadedWords = loadWords()
        
        if loadedWords.count == 0 {
            fatalError("Could not load the words file")
        } else {
            allWords = loadedWords
            startNewGame()
        }
    }
    
    func startNewGame () {
        score = 0
        rootWord = allWords.randomElement()!
        usedWords = []
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

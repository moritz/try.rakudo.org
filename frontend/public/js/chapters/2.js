{
    "title": "Basics - List Ops",
    "steps": [
                {
                    "example": "[+] 1..2",
                    "match" : ["\\[\\+\\]", "1\\.\\.2"],
                    "explanation": "List operators let you manipulate whole lists."
                },
                {
                    "example" : "2 + 3 * 4 / 5",
                    "match" : ["2", "\\+", "3", "\\*", "4", "/", "5"],
                    "explanation": "Multiply/divide are done before add/subtract"
                },
                {
                    "example": "(2 + 3) * 4 / 5",
                    "match" : ["\\(", "2", "\\+", "3", "\\)", "\\*", "4", "/", "5"],
                    "explanation": "Parentheses are done before anything else"
                }
             ]
}


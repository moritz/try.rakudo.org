{
    "title": "Basics - Math Infix",
    "steps": [
                {
                    "example": "1 + 2",
                    "match": "1\\s*\\+\\s*2",
                    "explanation": "Let's begin with a basic addition operation"
                },
                {
                    "example": "10 - 2 * 4",
                    "match": "10\\s*\\-\\s*2\\s*\\*\\s*4",
                    "explanation": "Multiply/divide are done before add/subtract"
                },
                {
                    "example": "(10 - 2) * 4",
                    "match": "\\(\\s*10\\s*\\-\\s*2\\s*\\)\\s*\\*\\s*4",
                    "explanation": "Parentheses are done before anything else"
                }
             ]
}

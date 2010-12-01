{
    "title": "Basics - List Ops",
    "steps": [
                {
                    "example": "[+] 1..2",
                    "match" : ["\\[\\+\\]", "1", "\\.\\.", "2"],
                    "explanation": "List operators let you manipulate whole lists."
                },
                {
                    "example" : "1..^5",
                    "match" : ["1", "\\.\\.\\^", "5"],
                    "explanation": "“..” is the Range operator. “..^” means “up to, but not including”"
                },
                {
                    "example": "1 ^.. 5",
                    "match" : ["1", "\\^\\.\\.", "5"],
                    "explanation": "“^..” is similar, meaning “exclude the first item”"
                },
                {
                    "example": "&lt;a b c d&gt;.join(',')",
                    "match" : ["\\<", "a", "b", "c", "d", "\\>\\.join\\(", "','", "\\)"],
                    "explanation": "Angle brackets quote a string and split it on whitespace"
                }
             ]
}


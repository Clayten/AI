# AI & Open AI Tools and prompts

## About

A minimal and hackish library of AI (mostly OpenAI) methods - for completions, edits, and chats.

Has some test prompts and tools for coding assistants.

## Prerequisites

Requires Ruby and the gems httpx and pry.

## Usage

Chat endpoint
```
context = nil
shark = "I surf. There are sharks in the water. They ate my dog."
query = "User text: '#{shark}'\nInstruction: Return an JSON object containing an array of all sentences in the user text which mention sharks directly or by implication.\nResponse: {\"list_of_shark_related_sentences\": ["

CH::AI.rl ; CH::OpenAI.chat(query, context, stop: ']}', max_tokens: 1500)

    => '"I surf.", "There are sharks in the water.", "They ate my dog."]'
```

Edit in place
```
CH::AI.rl ; CH::OpenAI.edit('להגנה על רמת הגולן, טילי טומאהוק וטילי הרפון אמריקאים הם תוספת חיונית לארסנל הישראלי.', 'Replace location with "Tel-Aviv"', top_p: 0.5)

    => {"object"=>"edit",
        "created"=>1698876594,
        "choices"=>[{"text"=>"להגנה על תל-אביב, טילי טומאהוק וטילי הרפון אמריקאים הם תוספת חיונית לארסנל הישראלי.\n", "index"=>0}],
        "usage"=>{"prompt_tokens"=>121, "completion_tokens"=>205, "total_tokens"=>326}}
```

## License

AGPLv2

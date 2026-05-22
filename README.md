# Lab 04: ContextFromFile — The Bot Whose Brain Lives in a Text File

**Series:** `trilingual-coding-compounding` · **Project 4 of the LLM-from-scratch path**
**Subjects covered:** file I/O, UTF-8 encoding, safe path handling, prompt injection, system vs user role, separation of data from code, multi-turn chat loop, message history, env-based secrets
**Languages required:** **R**, **Python**, **C#** (build once, learn three times)
**Career arcs covered:** AI Engineer (foundation), LLM application developer (immediate need), Prompt Engineer (daily skill), RAG-system developer (next stop)
**Prerequisite:** Project 3 (`Chatbot_with_memory`) — env loading, HTTP POST, JSON parsing, system-seeded `messages`, infinite loop with `quit`
**Time Estimate:** 60–90 minutes per language (3–4 hours total)
**Difficulty arc:** Tasks 1–4 setup · 5–10 R build · 11–14 Python build · 15–18 C# build · 19–20 interview-realistic

---

## Objective

Build a chatbot whose **personality, knowledge, and rules live in an external `.txt` file**, not in your source code. By the end of this lab you can: swap a bot's behavior by editing one file (no recompile), read UTF-8 text safely on Windows without `?` boxes for emojis or accents, inject loaded text into the **system role** of an OpenAI chat call, and explain *why* context belongs in `system` and not `user`. You will do all of this **three times** — once in R, once in Python, once in C# — because the skill is the pattern, not the syntax.

---

## Concept: A Context File Is a Standing Instruction

A **context file** is a plain `.txt` document that the program reads from disk **once at startup** and pastes into the **system prompt** of every chat request. The model treats it as the rulebook for the whole conversation — not as a question to answer.

```
your_repo/
|
+-- context.txt          <-- the bot's "brain" lives here
|                            edit this to change behavior
|
+-- R/chatbot.R          <-- the bot's "body"
+-- python/chatbot.py        each language is just a different
+-- csharp/Program.cs        wrapper around the same idea
```

The wrapper code does five things, in order, *every time you start it*:

1. Read `OPENAI_API_KEY` from `.env`.
2. Read `context.txt` from disk (UTF-8).
3. Build `system_prompt = base_instructions + context_text`.
4. Seed the `messages` list with one entry: `{role: "system", content: system_prompt}`.
5. Loop: read user input → append → POST to OpenAI → append reply → repeat until `quit`.

The breakthrough is step 2. **Once context lives in a file, a non-programmer can change the bot.** A teacher can drop in a syllabus, a lawyer can drop in case notes, a designer can rewrite the persona — and the source code never opens.

> **Why this matters:** This is the first project where the bot's behavior is **data**, not **code**. That single shift is the foundation of every retrieval-augmented system on Earth.

---

## Why External Context Exists — The Story

Every line of this lab is here because a previous generation of developers got burned by hardcoded prompts.

**Project 1 era (`Hello_LLM`):** A one-shot call. You write one user message, you get one reply. The "personality" is whatever the base model thinks it should be. Changing the bot means rewriting the message string in your source code.

**Project 2 era (`Persona_Bot`):** Someone says "what if we tell the model to act like a pirate?" The `system` role is born — a string prepended to the conversation that the model treats as standing instructions. Problem: the persona lives in a `system_prompt = "You are a pirate..."` line in `chatbot.py`. Want to change to a fortune teller? Edit code. Push code. Restart.

**Project 3 era (`Chatbot_with_memory`):** We start passing the full `messages` array on every turn so the bot remembers earlier exchanges. The persona is *still* in source code.

**Project 4 — this lab (~2022, the GPT-3.5 / GPT-4 era):** Teams realized two painful truths:
1. **Prompts change more often than code.** A prompt engineer might iterate 50 times a day. A code deploy is a 20-minute ritual. Mismatch.
2. **Non-developers should be able to edit prompts.** Product managers, lawyers, doctors, teachers — the people who *know* what the bot should say — should not need to open a `.py` file.

The fix was embarrassingly simple: **move the prompt out of source code and into a `.txt` file.** Read it at startup. Inject it into the system role. Done. The pattern is so simple it feels like nothing, but it is the seed of everything that followed.

**Project 5 era (`PDF_Reader_Bot`):** Same trick, fancier reader — parse a PDF, inject its text into the system prompt.

**RAG era (2023+):** Same trick, *retrieved* text — vector-search a knowledge base for the chunks most relevant to the user's question, inject the top K chunks into the system prompt right before the API call. ChatGPT with custom knowledge, Notion AI, every "chat with your docs" product — all of them are this Project 4 pattern with a retrieval step bolted in front.

> **The point of the story:** External context is the *primitive* that unlocks every later abstraction in LLM application engineering. Master this lab and you have already mastered 80% of the mental model for RAG.

---

## The Context Family — Who Lives There

External context has a family tree. Knowing the family tree means recognizing 90% of "new" LLM techniques in blog posts as old friends.

**The direct siblings (by how the context is sourced):**

| Family member | Where the context comes from | Where you meet it |
|---|---|---|
| **Inline persona** | A string literal in source code | Project 2, every quick demo |
| **File-loaded context** | One `.txt` from disk (this lab) | Project 4, internal tools |
| **PDF-extracted context** | Text extracted from a PDF | Project 5 |
| **Multi-doc concatenated context** | Several files glued into one prompt | Small KB bots |
| **Retrieved context (RAG)** | Top-K chunks from a vector store | Notion AI, ChatGPT custom GPTs |
| **Tool/function definitions** | A JSON schema sent alongside `messages` | OpenAI function calling, agents |

**The roles in a chat request (the three slots context can fill):**

| Role | What the model treats it as | Typical use |
|---|---|---|
| `system` | **Standing instructions** for the whole conversation | Persona, policy, loaded knowledge — *put context here* |
| `user` | **One turn** in the thread | The live question for this round |
| `assistant` | **One reply** from the model | Appended after each API call to preserve memory |

> **Critical rule:** File-backed context is a *standing instruction*, so it belongs in the **system** role — not as a fake first user turn. Putting it in `user` makes the model think you just asked it a 4,000-word question. Putting it in `system` makes the model behave that way for every reply.

**The cousins (same pattern, other libraries):**

| Cousin | Library / ecosystem | Notable difference |
|---|---|---|
| `PromptTemplate` | LangChain | Adds variable substitution (`{name}`) before injection |
| `Document` | LlamaIndex | Adds chunking + metadata for retrieval |
| Prompt `.skprompt.txt` files | Semantic Kernel (C#) | File-based prompts as a first-class concept |
| `ChatOptions.SystemInstruction` | Microsoft.Extensions.AI | C# wrapper for the same system-role seed |
| Custom GPT "Instructions" box | OpenAI ChatGPT UI | Same `.txt` idea, hosted UI instead of disk |

---

## The Anatomy of a Context-Backed Chat Request — In One Diagram

Every request your bot sends to OpenAI is one JSON body. Train your eye to read it top-to-bottom.

```
POST https://api.openai.com/v1/chat/completions
Authorization: Bearer sk-...                     <- from .env, never hardcoded
Content-Type: application/json

{
  "model": "gpt-4o-mini",
  "messages": [
    { "role": "system",                          <- role 1: standing instructions
      "content": "You are a helpful tutor.\n\n   <-           base instructions
                  <CONTEXT FROM context.txt>"    <-           + injected file text
    },
    { "role": "user",                            <- role 2: a user turn
      "content": "What is broadcasting?" },
    { "role": "assistant",                       <- role 3: model's previous reply
      "content": "Broadcasting is..." },
    { "role": "user",                            <- newest user turn (this call)
      "content": "Give me an example." }
  ]
}
```

**Reading the message stack left to right:**

- `system` (always index 0) — your `base_instructions + context_text` lives here. **Sent on every call** so the bot never forgets.
- `user` / `assistant` pairs — the conversation history, appended turn by turn.
- The newest `user` turn at the bottom — what the model is being asked *right now*.

> **Why this matters:** A senior LLM engineer can look at one of these JSON bodies and predict the bot's reply tone *before* the API call returns. That skill starts with internalizing "system = standing rule, user = this turn, assistant = previous reply."

### What a successful response looks like

```
{
  "id": "chatcmpl-...",
  "choices": [
    { "index": 0,
      "message": { "role": "assistant",
                   "content": "Broadcasting is when PyTorch..." },
      "finish_reason": "stop" }
  ],
  "usage": { "prompt_tokens": 412, "completion_tokens": 87, "total_tokens": 499 }
}
```

The one field you care about for the chat loop:

```
response["choices"][0]["message"]["content"]   <- the reply string you print + append
```

> **The senior-engineer skill:** Reading this JSON out loud as *"choice zero, the message, dot content"* — without thinking — is what separates juniors from seniors. Every language in this lab pulls the same path. Only the syntax for indexing changes.

---

## Trilingual Reference Table

The single most important table in this whole lab. Every row is one concept, expressed three ways.

| Concept | R | Python | C# |
|---|---|---|---|
| Import library | `library(httr2); library(jsonlite); library(dotenv)` | `import requests`, `from dotenv import load_dotenv` | `using System.Net.Http; using System.Text.Json;` |
| Load `.env` | `dotenv::load_dot_env("../.env")` | `load_dotenv("../.env")` | `DotNetEnv.Env.Load("../.env")` |
| Read API key | `Sys.getenv("OPENAI_API_KEY")` | `os.getenv("OPENAI_API_KEY")` | `Environment.GetEnvironmentVariable("OPENAI_API_KEY")` |
| Build a relative path | `file.path("..", "context.txt")` | `os.path.join("..", "context.txt")` | `Path.Combine("..", "context.txt")` |
| Read UTF-8 file | `paste(readLines(p, encoding = "UTF-8", warn = FALSE), collapse = "\n")` | `open(p, encoding="utf-8").read()` | `File.ReadAllText(p, Encoding.UTF8)` |
| Concatenate strings | `paste0(base, "\n\n", context_text)` | `f"{base}\n\n{context_text}"` | `$"{baseText}\n\n{contextText}"` |
| Build a JSON body | `jsonlite::toJSON(list(model=..., messages=...), auto_unbox=TRUE)` | `json.dumps({...})` (or pass `json=` to `requests.post`) | `JsonSerializer.Serialize(new {...})` |
| POST with auth header | `req_headers(req, Authorization = paste("Bearer", key))` | `requests.post(url, headers={"Authorization": f"Bearer {key}"}, json=body)` | `client.DefaultRequestHeaders.Authorization = new("Bearer", key)` |
| Parse JSON reply | `resp_body_json(resp)$choices[[1]]$message$content` | `resp.json()["choices"][0]["message"]["content"]` | `doc.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString()` |
| Infinite loop | `while (TRUE) { ... }` | `while True: ...` | `while (true) { ... }` |
| Exit condition | `if (tolower(user) == "quit") break` | `if user.lower() == "quit": break` | `if (user.ToLower() == "quit") break;` |
| Append to history | `messages[[length(messages) + 1]] <- list(role=..., content=...)` | `messages.append({"role": ..., "content": ...})` | `messages.Add(new { role = ..., content = ... });` |

> **Rule #1 of trilingual learning:** Build one mental model per row, three syntaxes per row. The model is the point — the syntax is the price you pay.

---

## Career Pathway Sidebar

| Level | Why this lab matters |
|---|---|
| **Self-taught beginner** | First time your bot's behavior is editable without code — the moment LLM apps start to feel real |
| **AI Engineer interview** | "How would you let a PM change the prompt without a deploy?" — this exact pattern is the answer |
| **LLM application dev** | Every internal tool starts as a single `context.txt` before it becomes a vector store |
| **RAG-system engineer** | The injection step in retrieval-augmented generation is *literally* this code, just fed by a retriever instead of one file |
| **Prompt engineer** | You stop being a person who edits strings in source files and become a person who versions `.txt` files in git |

---

## Project Structure (build this once, reuse for all three languages)

```
ContextFromFile/
|
+-- context.txt              <- the bot's personality (edit me, no recompile)
+-- .env                     <- OPENAI_API_KEY=sk-...  (gitignored, never committed)
+-- .gitignore               <- includes .env
|
+-- R/
|   `-- chatbot.R
|
+-- python/
|   +-- chatbot.py
|   `-- requirements.txt
|
+-- csharp/
|   +-- Program.cs
|   `-- ContextFromFile.csproj
|
+-- REPEATABLE_PROMPT.md     <- series rules
`-- README.md
```

> **Why one `context.txt` at the repo root:** All three language folders sit one level deep, so each can reach it with the same `..` jump. The single shared file proves the point of the lab — *the data is decoupled from the code, in all three languages simultaneously.*

---

## The 20 Tasks

> Each task is structured for maximum understanding, not maximum typing. After **Purpose** and code, every task includes:
>
> - **Human-Readable Breakdown** — "Hey computer, here is what I want you to do," one paragraph.
> - **Reading it left to right** — every symbol glossed in order.
> - **The story** — *why* this pattern exists, what bug it prevents, what real-world need it serves.
> - **Analogy** — a one-line metaphor.
> - **Expected output** — exactly what your terminal should show.
> - **Switches / Output decoded / Troubleshoot** — three small tables.
>
> Read every block. The code is the smallest part of each task.

---

### Task 1 — Build the repo skeleton

**Purpose:** A predictable folder shape means every later task knows where every file lives.

```powershell
mkdir ContextFromFile
cd ContextFromFile
mkdir R, python, csharp
New-Item context.txt, .env, .gitignore, README.md -ItemType File
```

**Human-Readable Breakdown:**
> "Hey shell, make a folder called `ContextFromFile`. Step into it. Make three subfolders, one per language. Make four empty files at the root: the context file, the secrets file, the gitignore, and the readme. That is the entire project skeleton — three sibling code folders sharing one `context.txt` and one `.env`."

**Reading it left to right:**
- `mkdir ContextFromFile` -> "create the project root."
- `cd ContextFromFile` -> "step into it so every later path is relative to here."
- `mkdir R, python, csharp` -> "create three sibling code folders. PowerShell takes a comma-separated list."
- `New-Item ... -ItemType File` -> "create empty files. `-ItemType File` is required or PowerShell creates folders by default."

**The story:** The folder shape is not arbitrary. The repo root holds **data** (`context.txt`, `.env`) and **documentation** (`README.md`). Each language folder holds **code**. That separation is the whole point of this lab — when a teammate edits `context.txt`, no language folder is touched, no commit conflicts, no rebuild. It is also why every code file uses `..` to reach the data: the data is *above* the code, conceptually and on disk.

**Analogy:** A house with one shared kitchen (the root) and three bedrooms (R, python, csharp). Everyone eats from the same fridge (`context.txt`).

**Expected output (after `dir`):**

```
context.txt
.env
.gitignore
README.md
R/
python/
csharp/
```

**Switches**

| Token | Meaning |
|---|---|
| `mkdir a, b, c` | PowerShell creates multiple folders in one call |
| `New-Item -ItemType File` | Forces file creation (otherwise New-Item makes a folder) |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `New-Item: A positional parameter cannot be found` | Add `-ItemType File` |
| Folder already exists error | Use `-Force` or `cd` into the existing one |

---

### Task 2 — Write `.gitignore` so secrets never get committed

**Purpose:** The single biggest beginner mistake in LLM projects is pushing an API key to GitHub.

`.gitignore`:

```text
.env
.Rhistory
.Rproj.user/
__pycache__/
*.pyc
bin/
obj/
.vs/
```

**Human-Readable Breakdown:**
> "Hey git, never track these. The `.env` file holds my API key — if it ever lands on GitHub, someone scrapes it within minutes and runs up my OpenAI bill. The other lines are language-specific noise (R history, Python bytecode, .NET build output) that nobody else needs."

**Reading it left to right:**
- `.env` -> "the secrets file. **This single line is the most important line in the whole repo.**"
- `.Rhistory`, `.Rproj.user/` -> "R's session noise."
- `__pycache__/`, `*.pyc` -> "Python's compiled bytecode cache."
- `bin/`, `obj/`, `.vs/` -> ".NET build artifacts and Visual Studio metadata."

**The story:** GitHub has bots scanning every public push for keys matching the pattern `sk-...`. They find leaked OpenAI keys in **under 60 seconds** and immediately drain them. There is one defense: never let `.env` near git. The `.gitignore` line is your seatbelt. Add it *before* you ever run `git add .`. Every senior engineer has a story about the time they didn't.

**Analogy:** A bouncer at the door of your repo with a clipboard. `.env` is not on the list. It stays outside.

**Switches**

| Token | Meaning |
|---|---|
| One name per line | Glob pattern, matches files/folders relative to repo root |
| `*.pyc` | All files ending in `.pyc` |
| Trailing `/` | Matches folders, not files |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `.env` already tracked | `git rm --cached .env`, then commit |
| Key already pushed | Rotate it on the OpenAI dashboard *immediately*, don't just delete the commit |

---

### Task 3 — Put your API key in `.env`

**Purpose:** Secrets live in env files, never in source code.

`.env`:

```text
OPENAI_API_KEY=sk-your-real-key-here
```

**Human-Readable Breakdown:**
> "Hey dotenv, the program will look for a variable named `OPENAI_API_KEY` at startup. Here is its value. Nothing fancy — one line, no quotes, no spaces around the equals sign, no `export` prefix."

**Reading it left to right:**
- `OPENAI_API_KEY` -> "the variable name. Convention: SCREAMING_SNAKE_CASE."
- `=` -> "key/value separator. **No spaces around it** — some parsers care."
- `sk-...` -> "the literal key. No quotes."

**The story:** The `.env` file is the universal convention across every modern language for *"non-secret-enough-to-need-a-vault but secret-enough-to-keep-out-of-git."* R, Python, and C# all have a `dotenv` library that reads this exact format. One file, three readers — that is why this lab can stay trilingual without a config-file fight.

**Analogy:** A sticky note on your monitor with the WiFi password. You see it when you sit down, no one else does, it does not live in your code.

**Switches**

| Token | Meaning |
|---|---|
| `KEY=value` | One line, no spaces around `=` |
| `# comment` | Most loaders treat `#` as a comment |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| Key reads as empty string | Spaces around `=`, or quotes wrapping the value |
| Key starts with `sk-proj-...` | That is fine — newer OpenAI keys look like this |

---

### Task 4 — Write your first `context.txt`

**Purpose:** The whole lab exists to load this file. Make sure it has personality.

`context.txt`:

```text
You are a cryptic fortune teller who speaks only in riddles.
When the user asks a question, respond with exactly one short fortune
(1-2 sentences) that hints at the answer but never states it directly.
Always end with: "The stars remain silent on further details."
```

**Human-Readable Breakdown:**
> "Hey future bot, here is who you are. You speak in riddles. You give one short fortune per reply. You always end with the same closing line. Three rules, that is it. The model will follow these as if they were the laws of physics for the rest of the conversation."

**Reading it left to right:**
- Line 1 -> "the persona. Models obey persona statements more reliably than 'please act as'."
- Line 2-3 -> "the format rule. Concrete constraints (`exactly one`, `1-2 sentences`) outperform vague ones (`be brief`)."
- Line 4 -> "the signature. A repeated closing line makes the persona feel consistent."

**The story:** A good `context.txt` reads like a one-page job description: who you are, what you do, what you never do, how you sign off. Vague prompts ("be helpful") produce vague bots. Specific prompts ("end every reply with this exact sentence") produce specific bots. The whole field of prompt engineering is this lesson, learned 10,000 times.

**Analogy:** A character sheet for a tabletop RPG. Stats, voice, catchphrase. The model improvises *within* the character, never *outside* it.

**Switches**

| Element | Why include it |
|---|---|
| Persona ("You are...") | Sets the voice |
| Format constraint ("exactly one...") | Sets the shape of every reply |
| Closing line | Anchors consistency turn after turn |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| Bot ignores the persona after a few turns | Persona is too vague — add concrete rules |
| Replies are too long | Add `1-2 sentences` or `under 50 words` |

---

### Task 5 — R: install packages

**Purpose:** R needs three libraries to do what `requests` + `dotenv` do in Python.

```r
install.packages(
  c("httr2", "jsonlite", "dotenv"),
  repos = "https://cloud.r-project.org"
)
```

**Human-Readable Breakdown:**
> "Hey R, fetch three packages from CRAN. `httr2` is the modern HTTP client — that is how I will POST to OpenAI. `jsonlite` builds and parses JSON. `dotenv` reads my `.env` file. Run this once per machine; you never have to run it again."

**Reading it left to right:**
- `install.packages(c(...))` -> "install one or more packages. `c(...)` is R's literal for 'vector of strings.'"
- `"httr2"` -> "modern successor to `httr`. Pipe-friendly, request-builder pattern."
- `"jsonlite"` -> "the standard R JSON library. `toJSON` and `fromJSON`."
- `"dotenv"` -> "reads a `.env` file into the R session's environment variables."
- `repos = "..."` -> "explicit CRAN mirror; avoids the 'choose a mirror' interactive prompt on fresh installs."

**The story:** R's HTTP story used to be split across `RCurl`, `httr`, and a graveyard of half-finished packages. `httr2` (2021+) unified everything into one fluent builder API: `request() |> req_url_path_append(...) |> req_headers(...) |> req_body_json(...) |> req_perform()`. It looks weirdly verbose at first, but it is the most maintainable pattern in R for talking to JSON APIs. Every line of the chain reads as a noun phrase.

**Analogy:** Setting up your toolbox before a remodel. Hammer, drill, level. Run once, work many times.

**Expected output:**

```
trying URL 'https://cloud.r-project.org/.../httr2_1.0.0.tgz'
...
* DONE (httr2)
* DONE (jsonlite)
* DONE (dotenv)
```

**Switches**

| Token | Meaning |
|---|---|
| `c("a", "b")` | R's vector literal |
| `repos = "..."` | Skip the interactive mirror picker |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `package 'httr2' is not available` | Update R itself — needs 4.1+ |
| Permission denied on install | Run R as your user, not as Administrator; or set `lib = ...` to a writable path |

---

### Task 6 — R: read `context.txt` as UTF-8

**Purpose:** This is the new skill of the lab. Get it right and the bot speaks in your context's voice; get it wrong and accented characters turn into `?`.

`R/chatbot.R` (first lines):

```r
library(httr2)
library(jsonlite)
library(dotenv)

dotenv::load_dot_env("../.env")
api_key <- Sys.getenv("OPENAI_API_KEY")

context_path  <- file.path("..", "context.txt")
context_lines <- readLines(context_path, warn = FALSE, encoding = "UTF-8")
context_text  <- paste(context_lines, collapse = "\n")

cat("Loaded context length:", nchar(context_text), "chars\n")
```

**Human-Readable Breakdown:**
> "Hey R, load the three libraries. Read the `.env` file one level up so my API key becomes an environment variable. Pull that key into a regular R variable. Now build a path to `context.txt` that works no matter where the user runs the script from. Read the file line by line as UTF-8 — that is the *only* encoding flag that matters on Windows. Glue the lines back together with newlines. Print the length so I can confirm something actually loaded."

**Reading it left to right:**
- `library(httr2)` / `library(jsonlite)` / `library(dotenv)` -> "load the three packages we installed in Task 5."
- `dotenv::load_dot_env("../.env")` -> "read the `.env` *one folder up* (we are in `R/`, the file is at the repo root)."
- `Sys.getenv("OPENAI_API_KEY")` -> "pull the variable out. Returns `""` (empty string) if it doesn't exist — no error."
- `file.path("..", "context.txt")` -> "build the path with the right separator for this OS. Safer than hardcoding `"../context.txt"`."
- `readLines(path, warn = FALSE, encoding = "UTF-8")` -> "read the file as a vector of strings, one per line. `warn = FALSE` silences the 'incomplete final line' nag. **`encoding = "UTF-8"` is non-negotiable on Windows.**"
- `paste(lines, collapse = "\n")` -> "glue the vector back into one string with newline separators. This is the format we will inject into the system prompt."
- `nchar(context_text)` -> "character count — your sanity check that loading worked."

**The story:** Windows defaults R's file encoding to whatever your locale says (often `windows-1252`). Your editor saves `context.txt` as UTF-8. Mismatch the two and every accented character ("naive," "cliche," "cafe") becomes a `?` or a `<U+00C3>` mojibake mess. The fix is one keyword: `encoding = "UTF-8"`. Always pass it on Windows. On macOS/Linux it is the default, but pass it anyway — your code becomes portable. The `file.path("..", ...)` instead of `"../..."` is the same kind of small-but-stubborn portability move: on Windows, paths *can* use `/`, but `file.path` future-proofs your code if you ever package it.

**Analogy:** UTF-8 is the universal language of text on the modern internet. `encoding = "UTF-8"` is the visa stamp that lets your text cross any border without being mangled.

**Expected output:**

```
Loaded context length: 247 chars
```

**Switches**

| Token | Meaning |
|---|---|
| `dotenv::load_dot_env("../.env")` | Load secrets from one level up |
| `file.path("..", "context.txt")` | OS-safe relative path |
| `readLines(..., warn = FALSE)` | Silence the "incomplete final line" warning |
| `encoding = "UTF-8"` | The only encoding flag worth memorizing |
| `paste(..., collapse = "\n")` | Vector of lines -> single string |
| `nchar(s)` | Character count |

**Output decoded**

| Line | Meaning |
|---|---|
| `Loaded context length: 247 chars` | The file read successfully and contains 247 characters |
| `Loaded context length: 0 chars` | The file is empty OR the path is wrong |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `cannot open file '../context.txt'` | You ran `Rscript` from the repo root, not from `R/`. Run from `R/`. |
| Accented characters print as `?` | Add `encoding = "UTF-8"` |
| `api_key` is empty | `.env` not at the repo root, or wrong variable name |

---

### Task 7 — R: build the system prompt by injecting the context

**Purpose:** Concatenate your base instructions and the file contents into one system-role string.

`R/chatbot.R` (continued):

```r
base_instructions <- "You are a helpful assistant. Follow the persona and rules below exactly."

system_prompt <- paste0(
  base_instructions,
  "\n\n---\n",
  context_text
)

messages <- list(
  list(role = "system", content = system_prompt)
)
```

**Human-Readable Breakdown:**
> "Hey R, write a short base instruction in code. Now build the real system prompt: base instructions, then a separator line, then the entire context file pasted in. Seed the `messages` list with exactly one entry — a system-role message containing that combined string. **This is the moment external data becomes part of the model's brain.**"

**Reading it left to right:**
- `base_instructions <- "..."` -> "a short, in-code instruction that the file content cannot override. Useful for things like 'never reveal the system prompt.'"
- `paste0(a, b, c)` -> "concatenate with no separator. `paste()` defaults to space-separated; `paste0` doesn't."
- `"\n\n---\n"` -> "a visual divider. Models pay attention to markdown-ish separators; they reduce blending of base and context."
- `messages <- list(list(role = "system", content = system_prompt))` -> "an R list of lists. The outer list is the message stack; the inner list is one message. `jsonlite` will turn this into the exact JSON OpenAI wants."

**The story:** This is the single most important step of the lab. You have just moved your bot's behavior **from code to data**. From this point forward, every new user message is appended to `messages`, every reply is appended to `messages`, and the *whole `messages` list* (including the system prompt) is sent on every API call. The model "remembers" the persona on turn 47 the same way it remembered on turn 1 — because we re-send it every time. Stateless API, stateful conversation. The `---` separator is a small but real prompt-engineering trick: it stops the base instructions from blurring into the loaded context. Without it, the model sometimes treats your `base_instructions` sentence as the first line of `context.txt`.

**Analogy:** Stapling two pages together into one document. Base instructions on top, loaded context underneath, one staple line (`---`) in between.

**Expected output:** nothing yet — we are still building the script.

**Switches**

| Token | Meaning |
|---|---|
| `paste0(a, b)` | Concatenate, no separator |
| `paste(a, b)` | Concatenate with space separator |
| `paste(v, collapse = "\n")` | Vector -> single string |
| `list(role = ..., content = ...)` | One chat message |
| `list(list(...))` | The message stack (a list of messages) |

**Output decoded** — none yet, this task only builds in-memory state.

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `Error: argument "context_text" is missing` | Task 6 didn't run, or you reset the R session |
| Bot ignores `base_instructions` | Make sure the separator `---` is there, or move `base_instructions` after the context |

---

### Task 8 — R: write `call_openai(messages)`

**Purpose:** One function in, one assistant string out. The single API touchpoint.

```r
call_openai <- function(messages) {
  body <- list(
    model    = "gpt-4o-mini",
    messages = messages
  )

  resp <- request("https://api.openai.com/v1/chat/completions") |>
    req_headers(
      Authorization  = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ) |>
    req_body_json(body) |>
    req_perform()

  parsed <- resp_body_json(resp)
  parsed$choices[[1]]$message$content
}
```

**Human-Readable Breakdown:**
> "Hey R, define a function that takes the whole message history and returns the next assistant reply. Build a request body with the model name and the messages. Construct an httr2 request to the OpenAI endpoint, attach the auth and content-type headers, attach the JSON body, send it. Parse the JSON response and dig out `choices[[1]]$message$content` — that is the actual reply string. Return it."

**Reading it left to right:**
- `function(messages) { ... }` -> "an R function. The argument is the full history; the return value is the new assistant reply."
- `body <- list(model = "gpt-4o-mini", messages = messages)` -> "the JSON body. `gpt-4o-mini` is the cheap/fast default; you can swap in `gpt-4o` or `gpt-3.5-turbo`."
- `request("...") |> ...` -> "the httr2 builder pipe. Each step returns a request object; the chain ends with `req_perform()` which actually sends it."
- `req_headers(Authorization = paste("Bearer", api_key))` -> "the OAuth-style bearer header. `paste` glues `Bearer` and the key with a space."
- `` `Content-Type` `` -> "backticked because of the hyphen — R needs that to treat it as one symbol."
- `req_body_json(body)` -> "serialize the R list to JSON and attach as the POST body."
- `req_perform()` -> "send the request, return the response object."
- `resp_body_json(resp)` -> "parse the JSON body to a nested R list."
- `parsed$choices[[1]]$message$content` -> "drill into the standard OpenAI shape: `choices` is a list, take the first one, then `message`, then `content`. **`[[1]]` not `[1]`** — `[[1]]` extracts the element, `[1]` returns a length-1 sublist."

**The story:** This function is the entire reason the rest of the script exists. Everything before it builds the inputs (`messages`); everything after it consumes the output (the assistant string). Isolating the API call in one function gives you one place to add retries, logging, token counting, model switching, and error handling later. *Senior engineers do not have API calls scattered across their code; they have one `call_openai` and 47 callers.* The `[[1]]` vs `[1]` distinction in R is the single most common bug — `[[` drops the list wrapping, `[` keeps it. Get it wrong and you pass a 1-element list to `cat()`, which prints as `list(...)` instead of the actual text.

**Analogy:** A single vending machine. You feed in coins (the `messages` list), one chocolate bar comes out (the reply string). The whole rest of the program is "load coins" and "eat chocolate."

**Switches**

| Token | Meaning |
|---|---|
| `request(url)` | Start an httr2 request chain |
| `\|>` | R's native pipe operator (since 4.1) |
| `req_headers(...)` | Attach HTTP headers |
| `req_body_json(body)` | Attach a JSON body |
| `req_perform()` | Actually send the request |
| `resp_body_json(resp)` | Parse JSON response to R list |
| `lst[[1]]` | Extract first element (drops list wrapper) |
| `lst[1]` | Sublist of first element (keeps list wrapper) |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `HTTP 401` | Bad/missing API key |
| `HTTP 429` | Rate limited — wait or slow the loop |
| `HTTP 400 invalid_request_error` | `messages` malformed; print it before sending |
| Prints `list(...)` instead of text | You used `[1]` instead of `[[1]]` somewhere |

---

### Task 9 — R: the main conversation loop

**Purpose:** Glue the API call into an infinite read-eval-print loop with a clean exit.

```r
cat("Bot ready. Type 'quit' to exit.\n")

while (TRUE) {
  user_input <- readline("You: ")

  if (tolower(trimws(user_input)) == "quit") {
    cat("Bye.\n")
    break
  }

  messages[[length(messages) + 1]] <-
    list(role = "user", content = user_input)

  reply <- call_openai(messages)

  messages[[length(messages) + 1]] <-
    list(role = "assistant", content = reply)

  cat("Bot:", reply, "\n\n")
}
```

**Human-Readable Breakdown:**
> "Hey R, print a 'ready' banner. Now loop forever. Each turn, read one line of user input. If it is `quit` (case-insensitive, trimmed), say goodbye and break out of the loop. Otherwise append the user's turn to `messages` as a user-role entry. Call `call_openai` with the whole history — that returns the assistant's reply string. Append the reply to `messages` as an assistant-role entry. Print the reply. Loop."

**Reading it left to right:**
- `while (TRUE) { ... }` -> "R's infinite loop. The exit is the `break` inside the body."
- `readline("You: ")` -> "blocking read of one line from stdin, with a prompt."
- `tolower(trimws(x))` -> "lowercase and strip whitespace — so `Quit`, ` QUIT `, and `quit\n` all match."
- `messages[[length(messages) + 1]] <- list(...)` -> "R's idiom for 'append to a list.' You compute the new index as one past the current length."
- `call_openai(messages)` -> "send the *whole* history. OpenAI is stateless; memory lives in `messages`."
- `cat("Bot:", reply, "\n\n")` -> "print the reply with a label and a blank line for readability."

**The story:** This is the heartbeat of every chatbot ever written. Loop, read, append, call, append, print. The two appends are why the bot has memory: every previous user turn and every previous assistant reply is in `messages` on the next call. The system prompt — your loaded context — sits at index 1 (R is 1-indexed) and never moves. The conversation grows around it, but it stays. **Most beginner chat bugs are forgetting one of the two appends.** Forget to append the user turn -> the model sees an old question repeated. Forget to append the assistant reply -> the model has no idea what it just said and contradicts itself.

**Analogy:** A receptionist who writes every line of a phone call into a logbook (`messages`) and re-reads the whole logbook out loud before responding to each new sentence. Tedious for a human, instant for an API.

**Expected output:**

```
Bot ready. Type 'quit' to exit.
You: will I get the job?
Bot: A door that creaks loudest is the one that opens widest, yet the threshold demands one more knock. The stars remain silent on further details.

You: quit
Bye.
```

**Switches**

| Token | Meaning |
|---|---|
| `while (TRUE)` | R's infinite loop |
| `readline(prompt)` | Blocking stdin read |
| `trimws(s)` | Strip leading/trailing whitespace |
| `tolower(s)` | Lowercase |
| `lst[[length(lst) + 1]] <- x` | Append to a list |
| `break` | Exit the loop |

**Output decoded**

| Line | Meaning |
|---|---|
| `Bot ready...` | Your script reached the loop |
| `Bot: <reply>` | The API returned a non-empty content string |
| `Bye.` | The `quit` branch fired and `break` executed |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| Bot replies to your old question | You forgot to append the new user turn |
| Bot has no memory between turns | You forgot to append the assistant reply |
| Loop never exits on `quit` | You didn't lowercase or trim — try `Quit ` with trailing space |

---

### Task 10 — R: run the script end-to-end

**Purpose:** Prove the whole R pipeline works.

```powershell
cd R
Rscript chatbot.R
```

**Human-Readable Breakdown:**
> "Hey PowerShell, step into the `R/` folder so the `..` path inside the script points at the repo root. Run the script with `Rscript`. Type one question. Confirm the reply matches the persona in `context.txt`. Type `quit`."

**Reading it left to right:**
- `cd R` -> "**critical**: the script uses `file.path('..', 'context.txt')`, which only works if your current directory is `R/`."
- `Rscript chatbot.R` -> "command-line R interpreter for whole scripts (as opposed to `R` interactive)."

**The story:** Running an R script from the wrong directory is the #1 source of `cannot open file` errors in this whole series. The `..` in your path resolves relative to wherever you launched the command from, not relative to the script file. The fix is either (a) `cd` into the right folder, or (b) use `here::here()` from the `here` package, which finds the project root no matter where you launched from. For this lab, just `cd R` first — same convention across all three languages.

**Analogy:** Same as opening a recipe book. The recipe says "go upstairs to the pantry." If you start in the basement, "upstairs" lands in the living room, not the kitchen.

**Expected output:** see Task 9.

**Switches**

| Token | Meaning |
|---|---|
| `Rscript file.R` | Run an R file non-interactively |
| `R --no-save -f file.R` | Older equivalent |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `Rscript: command not found` | Add R's `bin` folder to your PATH |
| Script runs but `context.txt` not found | You forgot to `cd R/` |

---

### Task 11 — Python: venv and install

**Purpose:** Mirror Task 5 in Python.

```powershell
cd python
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install --quiet requests python-dotenv
```

`python/requirements.txt`:

```text
requests>=2.31
python-dotenv>=1.0
```

**Human-Readable Breakdown:**
> "Hey shell, step into `python/`. Make a virtual environment called `.venv`. Activate it so the next `pip install` only touches this sandbox. Install `requests` (the HTTP client) and `python-dotenv` (the `.env` reader). Write the same two names into `requirements.txt` so anyone cloning the repo can do `pip install -r requirements.txt`."

**Reading it left to right:**
- `python -m venv .venv` -> "run Python's `venv` module to create a sandbox in `.venv/`."
- `.\.venv\Scripts\Activate.ps1` -> "Windows PowerShell activation script. Linux/macOS uses `source .venv/bin/activate`."
- `pip install --quiet ...` -> "install without scrolling logs. `--quiet` is purely aesthetic."

**The story:** Every Python LLM project on Earth starts with a venv. The reason: `requests`, `openai`, `langchain`, `llama-index`, and `numpy` all pin different versions of `urllib3`, `pydantic`, and friends. Install them globally and the next project breaks the previous one. The venv is your seatbelt. The `requirements.txt` is your map back — anyone, anywhere, can reproduce your environment by reading one file.

**Analogy:** A sterile lab bench. Whatever you spill stays on the bench (`.venv/`) and never on your kitchen counter (the global Python install).

**Expected output:**

```
(.venv) PS C:\...\python>
```

**Switches**

| Token | Meaning |
|---|---|
| `python -m venv .venv` | Create the sandbox |
| `Activate.ps1` | PowerShell activation script |
| `pip install -r requirements.txt` | Reinstall from a manifest |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `Activate.ps1 cannot be loaded because running scripts is disabled` | Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once |
| Wrong Python version | Use `py -3.11 -m venv .venv` to pin a version |

---

### Task 12 — Python: read `.env` and `context.txt`

**Purpose:** Same job as Task 6, Python flavor.

`python/chatbot.py` (first lines):

```python
import os
import requests
from dotenv import load_dotenv

load_dotenv("../.env")
API_KEY = os.getenv("OPENAI_API_KEY")

CONTEXT_PATH = os.path.join("..", "context.txt")
with open(CONTEXT_PATH, "r", encoding="utf-8") as f:
    context_text = f.read()

print(f"Loaded context length: {len(context_text)} chars")
```

**Human-Readable Breakdown:**
> "Hey Python, import the three things I need: `os` for paths and env vars, `requests` for HTTP, and `load_dotenv` to read the `.env` file. Load `.env` from one folder up. Pull the API key. Build a relative path to `context.txt`. Open the file with **`encoding='utf-8'`** — yes, even on Windows. Read the whole thing into one string. Print the length to confirm."

**Reading it left to right:**
- `import os` / `import requests` -> "stdlib + the one third-party HTTP client."
- `from dotenv import load_dotenv` -> "the function form: `load_dotenv(path)`."
- `load_dotenv("../.env")` -> "read `.env` one folder up; sets process env vars."
- `os.getenv("OPENAI_API_KEY")` -> "returns `None` if missing — no exception."
- `os.path.join("..", "context.txt")` -> "OS-safe path. Equivalent to R's `file.path`."
- `with open(p, "r", encoding="utf-8") as f` -> "open in text-read mode, **UTF-8 explicit**. The `with` block auto-closes the file."
- `f.read()` -> "read the *entire file* into one string. For tiny files (KB), this is fine. For huge files, switch to streaming."

**The story:** Python's default file encoding on Windows is `cp1252` (a.k.a. `windows-1252`), not UTF-8. Same trap as R, different default. The fix is the same: pass `encoding="utf-8"` every time you open a text file. Skip it and your fortune teller's accented characters render as garbage. The `with` block is Python's context manager — it guarantees the file is closed even if an exception fires mid-read. Use it always; never call `open()` without `with`.

**Analogy:** A library card. `with open(...) as f` checks the book out, lets you read it, and checks it back in automatically when you walk out of the indented block.

**Expected output:**

```
Loaded context length: 247 chars
```

**Switches**

| Token | Meaning |
|---|---|
| `load_dotenv(path)` | Read a `.env` file |
| `os.getenv("KEY")` | Get env var (None if missing) |
| `os.path.join("..", "x")` | OS-safe relative path |
| `open(p, "r", encoding="utf-8")` | UTF-8 read |
| `with ... as f:` | Auto-close on exit |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `UnicodeDecodeError` | You forgot `encoding="utf-8"` |
| `FileNotFoundError` | You ran from the wrong folder — `cd python` first |
| `API_KEY` is `None` | `.env` not at the repo root, or wrong key name |

---

### Task 13 — Python: `call_openai(messages)`

**Purpose:** Mirror Task 8 in Python.

```python
def call_openai(messages):
    resp = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        },
        json={
            "model": "gpt-4o-mini",
            "messages": messages,
        },
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()["choices"][0]["message"]["content"]
```

**Human-Readable Breakdown:**
> "Hey Python, define a function that takes the message history and returns one reply string. POST to the OpenAI endpoint with the bearer auth header, the JSON content-type, and the JSON body (model + messages). Give it a 60-second timeout so a hung network doesn't freeze the bot forever. Raise an exception if the HTTP status isn't 2xx. Otherwise parse the JSON and pull `choices[0]['message']['content']`."

**Reading it left to right:**
- `def call_openai(messages):` -> "function definition; one arg."
- `requests.post(url, headers=..., json=..., timeout=...)` -> "the entire HTTP call in one function call. `json=` tells `requests` to serialize and set the content-type for you."
- `f"Bearer {API_KEY}"` -> "f-string interpolation, same as R's `paste('Bearer', api_key)`."
- `timeout=60` -> "**always pass this.** Default is no timeout — your script will hang forever if the connection drops."
- `resp.raise_for_status()` -> "raise `HTTPError` on 4xx/5xx. Otherwise silent failures cascade."
- `resp.json()["choices"][0]["message"]["content"]` -> "drill into the standard OpenAI shape. `[0]` not `[[1]]` because Python is 0-indexed."

**The story:** `requests` is the gold-standard Python HTTP library. The `json=` parameter is the secret weapon — it serializes a dict to JSON and sets `Content-Type: application/json` for you, removing two common bugs. The `timeout=60` is the line that separates production code from tutorial code: without it, a single network blip locks your script. The `raise_for_status()` is the second separator: without it, a 401 (bad key) returns silently and your next line of code tries to parse an HTML error page as JSON, producing a confusing `KeyError` instead of a clear `HTTPError`.

**Analogy:** Same vending machine as R. Coins in, chocolate out. The only difference is the brand of vending machine — Python's `requests` is the same machine, different paint.

**Expected output:** nothing yet — function body only.

**Switches**

| Token | Meaning |
|---|---|
| `requests.post(url, ...)` | Send POST |
| `json={...}` | Serialize + set content-type |
| `timeout=60` | Cap the wait |
| `resp.raise_for_status()` | Throw on HTTP error |
| `resp.json()` | Parse response body as JSON |
| `lst[0]` | First element (Python is 0-indexed) |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `requests.exceptions.HTTPError: 401` | Bad/missing API key |
| `requests.exceptions.Timeout` | Network slow; raise the timeout or retry |
| `KeyError: 'choices'` | The response is an error body, not a chat completion — print `resp.json()` |

---

### Task 14 — Python: main loop

**Purpose:** Mirror Task 9 in Python.

```python
messages = [
    {"role": "system", "content": f"{base_instructions}\n\n---\n{context_text}"}
]

base_instructions = "You are a helpful assistant. Follow the persona and rules below exactly."
# (Re-order so base_instructions is defined BEFORE the messages line; shown here in narrative order.)

print("Bot ready. Type 'quit' to exit.")
while True:
    user_input = input("You: ")
    if user_input.strip().lower() == "quit":
        print("Bye.")
        break

    messages.append({"role": "user", "content": user_input})
    reply = call_openai(messages)
    messages.append({"role": "assistant", "content": reply})

    print(f"Bot: {reply}\n")
```

> **Order matters** — in your actual file, define `base_instructions` before you reference it. The block above shows the two pieces side by side for narration.

**Human-Readable Breakdown:**
> "Hey Python, seed the `messages` list with one system-role entry whose content is the base instructions plus a separator plus the loaded file text. Print a banner. Loop forever. Read one line of input. If it is `quit` (trimmed, lowercased), say bye and break. Otherwise append a user-role entry, call the API, append the assistant reply, print it."

**Reading it left to right:**
- `messages = [ {...} ]` -> "Python list with one dict. Each dict is one message; the keys match OpenAI's schema."
- `f"{base}\n\n---\n{context_text}"` -> "f-string concatenation. Same idea as R's `paste0` but inline."
- `input("You: ")` -> "blocking stdin read with prompt. Equivalent to R's `readline`."
- `user_input.strip().lower()` -> "chain `.strip()` and `.lower()` — same as R's `tolower(trimws(...))`."
- `messages.append({...})` -> "Python list method, mutates in place. Equivalent to R's `messages[[length(messages)+1]] <-`."
- `print(f"Bot: {reply}\n")` -> "print with a label and a blank line. The `\n` adds spacing between turns."

**The story:** Read this loop side by side with the R loop in Task 9. **They are the same algorithm, twice.** Loop, read, check-for-quit, append-user, call-API, append-assistant, print. That parallelism is the entire point of the trilingual series — once you internalize the algorithm, Python and R are just different keyboards typing the same song. C# next will be the same song again, with semicolons.

**Analogy:** Same receptionist with the same logbook. Different uniform (Python's syntax), same job.

**Expected output:**

```
Bot ready. Type 'quit' to exit.
You: will i get the job?
Bot: The lantern flickers brightest just before dawn breaks, yet only one hand may light the wick. The stars remain silent on further details.

You: quit
Bye.
```

**Switches**

| Token | Meaning |
|---|---|
| `while True:` | Infinite loop |
| `input(prompt)` | Blocking stdin read |
| `s.strip().lower()` | Trim + lowercase |
| `lst.append(x)` | Mutate-in-place append |
| `break` | Exit loop |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `NameError: base_instructions` | Define it before you use it in the f-string |
| Bot forgets previous turns | You missed one of the two `append` calls |

---

### Task 15 — C#: scaffold the project

**Purpose:** Mirror Task 5/11 in C#.

```powershell
cd csharp
dotnet new console -n ContextFromFile
cd ContextFromFile
dotnet add package DotNetEnv
```

> Move `Program.cs` and `ContextFromFile.csproj` up to `csharp/` if you want a flat layout to match R/python — or keep the `dotnet new` default subfolder. Either works; just adjust your `..` paths accordingly.

**Human-Readable Breakdown:**
> "Hey dotnet, create a new console project. Step into the project folder. Install one NuGet package: `DotNetEnv`, the C# port of `python-dotenv`. We do not need a JSON package — `System.Text.Json` ships with .NET. We do not need an HTTP package — `System.Net.Http` ships with .NET. C# is batteries-included; only the env reader needs a third-party install."

**Reading it left to right:**
- `dotnet new console -n ContextFromFile` -> "scaffold a console app named `ContextFromFile`. Creates `Program.cs` + `.csproj`."
- `dotnet add package DotNetEnv` -> "install the `.env` reader from NuGet. Edits the `.csproj` for you."

**The story:** C# has a reputation for being heavy, but for an LLM client it is actually the leanest of the three languages — `HttpClient` and `JsonSerializer` are built in. The only third-party piece is `DotNetEnv`. Compare to Python (`requests` + `python-dotenv`) and R (`httr2` + `jsonlite` + `dotenv`): C# wins on dependency count. The "verbosity" reputation comes from types (`Dictionary<string, object>` etc.), not from imports.

**Analogy:** Buying a car with cruise control and AC standard. You still pay for the GPS, but the basics are included.

**Expected output:**

```
The template "Console App" was created successfully.
info : Package 'DotNetEnv' is compatible with all the specified frameworks in project ...
```

**Switches**

| Token | Meaning |
|---|---|
| `dotnet new console -n Name` | Scaffold a console app |
| `dotnet add package X` | Install NuGet package |
| `dotnet run` | Build + run |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `dotnet: command not found` | Install .NET SDK 8 from microsoft.com/dotnet |
| Package not found | Check NuGet name spelling: `DotNetEnv`, not `dotnetenv` |

---

### Task 16 — C#: read `.env` and `context.txt`

**Purpose:** Mirror Task 6/12 in C#.

`csharp/ContextFromFile/Program.cs` (top):

```csharp
using System;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using DotNetEnv;

Env.Load("../../.env");
string apiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY")
                ?? throw new InvalidOperationException("OPENAI_API_KEY missing");

string contextPath = Path.Combine("..", "..", "context.txt");
string contextText = File.ReadAllText(contextPath, Encoding.UTF8);

Console.WriteLine($"Loaded context length: {contextText.Length} chars");
```

> The `../../` path assumes the `dotnet new` default — `csharp/ContextFromFile/Program.cs`. Adjust if you flattened the folders.

**Human-Readable Breakdown:**
> "Hey C#, import the namespaces I need: I/O, HTTP, headers, encoding, JSON, dotenv. Load the `.env` two folders up because `dotnet run` runs the binary from `bin/Debug/net8.0/`. Pull the API key — if it is missing, throw immediately. Build a path to `context.txt` two folders up. Read the file as **UTF-8**. Print the length."

**Reading it left to right:**
- `using System.IO;` etc. -> "namespace imports. Equivalent to Python's `import os`."
- `Env.Load("../../.env")` -> "DotNetEnv's load function."
- `?? throw new InvalidOperationException(...)` -> "C# null-coalescing operator. If the env var is `null`, throw a clear error instead of letting a `NullReferenceException` bite you later."
- `Path.Combine("..", "..", "context.txt")` -> "OS-safe relative path. **Two levels up** because `dotnet run` executes from `bin/Debug/net8.0/`, not from the project folder."
- `File.ReadAllText(path, Encoding.UTF8)` -> "read the whole file as one string. Explicit `Encoding.UTF8`."
- `contextText.Length` -> "character count on a `string`."

**The story:** The single biggest gotcha in C# console apps is **the working directory**. When you run `dotnet run`, the executable starts inside `bin/Debug/net8.0/`. That means `../../context.txt` from inside the binary lands at the project folder, and `../../../context.txt` lands at the `csharp/` folder. **Print your `Directory.GetCurrentDirectory()` once to see exactly where you are.** Path debugging is 50% of all C# console-app frustration. The other safe path: stash `context.txt` next to the `.csproj` and use `[ContextFromFile.csproj]<CopyToOutputDirectory>Always</CopyToOutputDirectory>` so the file is copied next to the binary at build time. Either works; pick one and document it.

**Analogy:** C# runs your code from a hotel room (`bin/Debug/`), not from your house (the project folder). `..` takes you to the hotel lobby, not your kitchen. Plan your paths from the hotel.

**Expected output:**

```
Loaded context length: 247 chars
```

**Switches**

| Token | Meaning |
|---|---|
| `Env.Load(path)` | Read `.env` |
| `Environment.GetEnvironmentVariable("KEY")` | Read env var (nullable) |
| `??` | Null-coalesce |
| `Path.Combine(...)` | OS-safe path |
| `File.ReadAllText(path, Encoding.UTF8)` | UTF-8 read |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `DirectoryNotFoundException` | Path wrong; print `Directory.GetCurrentDirectory()` and recount the `..` |
| `apiKey` throws on startup | `.env` not found or `OPENAI_API_KEY` not in it |
| Accented chars look wrong in console | Set `Console.OutputEncoding = Encoding.UTF8;` at the top |

---

### Task 17 — C#: `CallOpenAI(messages)`

**Purpose:** Mirror Task 8/13 in C#.

```csharp
using var http = new HttpClient();
http.DefaultRequestHeaders.Authorization =
    new AuthenticationHeaderValue("Bearer", apiKey);

var messages = new List<Dictionary<string, string>>
{
    new() {
        ["role"] = "system",
        ["content"] = $"You are a helpful assistant. Follow the persona and rules below exactly.\n\n---\n{contextText}"
    }
};

async Task<string> CallOpenAI(List<Dictionary<string, string>> history)
{
    var body = new { model = "gpt-4o-mini", messages = history };
    var json = JsonSerializer.Serialize(body);
    using var content = new StringContent(json, Encoding.UTF8, "application/json");

    using var resp = await http.PostAsync(
        "https://api.openai.com/v1/chat/completions", content);
    resp.EnsureSuccessStatusCode();

    var raw = await resp.Content.ReadAsStringAsync();
    using var doc = JsonDocument.Parse(raw);
    return doc.RootElement
              .GetProperty("choices")[0]
              .GetProperty("message")
              .GetProperty("content")
              .GetString() ?? "";
}
```

**Human-Readable Breakdown:**
> "Hey C#, create one shared `HttpClient` and stick the bearer token on its default headers — that way every request reuses the auth. Seed `messages` with a system-role entry whose content concatenates base instructions and the loaded context. Define an async function `CallOpenAI` that takes the history. Build an anonymous body object, serialize it to JSON, wrap it in a `StringContent` with UTF-8 + the JSON content-type. POST it. Throw on non-2xx. Read the response body as string. Parse with `JsonDocument`. Walk `choices[0].message.content` and return the string."

**Reading it left to right:**
- `using var http = new HttpClient()` -> "create the client; `using` disposes it when scope ends. For longer-lived apps, use `IHttpClientFactory` — for this lab, one client is fine."
- `new AuthenticationHeaderValue("Bearer", apiKey)` -> "the typed bearer header. Cleaner than concatenating `"Bearer " + apiKey` by hand."
- `new() { ["role"] = "system", ... }` -> "C# 9 target-typed `new`. Same as `new Dictionary<string, string>() { ... }` but the type is inferred from the list."
- `async Task<string>` -> "an async method returning a string."
- `new { model = "...", messages = history }` -> "an anonymous object. The JSON serializer picks up the field names verbatim."
- `JsonSerializer.Serialize(body)` -> "object -> JSON string."
- `new StringContent(json, Encoding.UTF8, "application/json")` -> "HTTP body with UTF-8 and the right MIME type."
- `await http.PostAsync(url, content)` -> "send. `await` because async."
- `resp.EnsureSuccessStatusCode()` -> "throw on 4xx/5xx. Equivalent to Python's `raise_for_status()`."
- `JsonDocument.Parse(raw)` -> "low-allocation JSON reader. Use this for one-shot reads."
- `.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString()` -> "the same drill as R and Python, just typed."

**The story:** This is the verbose part of C#. R does it in 4 lines, Python in 2, C# in 12. The trade is type safety: every wrong key is a compile-time or runtime error with a precise line number, not a silent `None`/`NULL`. For production code that gets hammered, you would define a record type instead of an anonymous object and use `JsonSerializer.Deserialize<ChatResponse>(...)` for typed output. For this lab, the dynamic walk is the most direct mirror of the R/Python versions.

**Analogy:** Same vending machine, but every button has a label and every output has a barcode. Slower to use, fewer wrong purchases.

**Switches**

| Token | Meaning |
|---|---|
| `using var x = new T()` | Auto-dispose when scope ends |
| `new() { ... }` | Target-typed `new` (C# 9+) |
| `JsonSerializer.Serialize(obj)` | Object -> JSON string |
| `JsonDocument.Parse(json)` | JSON string -> tree |
| `.GetProperty("k")` | Drill into a JSON object |
| `[0]` | Drill into a JSON array |
| `.GetString()` | Pull a string leaf |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `KeyNotFoundException` from `GetProperty` | The response is an error body — print `raw` to see it |
| `HttpRequestException: 401` | Bad/missing API key |
| `JsonException` | The response wasn't valid JSON; print the status code first |

---

### Task 18 — C#: main loop

**Purpose:** Mirror Task 9/14 in C#.

```csharp
Console.OutputEncoding = Encoding.UTF8;
Console.WriteLine("Bot ready. Type 'quit' to exit.");

while (true)
{
    Console.Write("You: ");
    string userInput = Console.ReadLine() ?? "";

    if (userInput.Trim().Equals("quit", StringComparison.OrdinalIgnoreCase))
    {
        Console.WriteLine("Bye.");
        break;
    }

    messages.Add(new() {
        ["role"] = "user",
        ["content"] = userInput
    });

    string reply = await CallOpenAI(messages);

    messages.Add(new() {
        ["role"] = "assistant",
        ["content"] = reply
    });

    Console.WriteLine($"Bot: {reply}\n");
}
```

**Human-Readable Breakdown:**
> "Hey C#, set the console to UTF-8 output so accented characters render correctly. Print a banner. Loop forever. Read one line; if it is null (e.g. Ctrl+Z), treat it as empty. Compare against `quit` case-insensitively; if it matches, say bye and break. Otherwise append a user-role dict, await the API call, append the assistant reply, print it."

**Reading it left to right:**
- `Console.OutputEncoding = Encoding.UTF8` -> "fixes mojibake when the bot returns non-ASCII text."
- `Console.ReadLine() ?? ""` -> "read one line. `?? ""` defends against `null` if stdin is closed."
- `.Equals("quit", StringComparison.OrdinalIgnoreCase)` -> "case-insensitive equality. The "correct" C# way; avoids `.ToLower()` allocating a new string."
- `messages.Add(new() { ... })` -> "append a dictionary to the list."
- `await CallOpenAI(messages)` -> "call the async function and wait for the reply."

**The story:** Same heartbeat, third language. Read this loop side by side with R Task 9 and Python Task 14 — the structure is identical down to the order of statements. **Once you can write all three from memory, you have internalized the algorithm.** That is the trilingual payoff: syntax stops being scary because you know exactly what the next line *should* do, regardless of the keyboard.

**Analogy:** Third uniform, same job. The receptionist now wears a tie.

**Expected output:** identical to R and Python.

**Switches**

| Token | Meaning |
|---|---|
| `Console.ReadLine() ?? ""` | Read or fall back to empty |
| `StringComparison.OrdinalIgnoreCase` | Case-insensitive compare |
| `lst.Add(x)` | Append to a `List<T>` |
| `await fn()` | Wait for an async call |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `NullReferenceException` on `userInput` | Use the `?? ""` fallback |
| Loop runs but never POSTs | Forgot `await`; the call returns a `Task` you ignored |
| Special characters print wrong | Set `Console.OutputEncoding = Encoding.UTF8` |

---

### Task 19 — Swap `context.txt` to change behavior, recompile nothing

**Purpose:** This is the whole lab in one act. Prove the bot is data-driven.

Edit `context.txt` to a completely new persona, save, re-run **any** of the three scripts. No code change.

```text
You are a sarcastic 1940s detective narrating an internal monologue.
Every reply starts with "The dame asked me..." and ends with "...and that was that.".
Keep it under 60 words. Never break character.
```

```powershell
cd ../R          # or python, or csharp/ContextFromFile
Rscript chatbot.R
```

**Human-Readable Breakdown:**
> "Hey lab, watch this. I am going to delete the fortune teller persona and paste in a 1940s detective persona. I will save `context.txt`. I will re-run the **exact same** R script, then the **exact same** Python script, then the **exact same** C# program. All three will switch personality. **Zero lines of code changed.** This is the principle behind every modern LLM product."

**The story:** This task is the *aha* of the whole project. You just edited one text file and turned a fortune teller into a film-noir detective in three programming languages simultaneously. That is the power of separating data from code. The next product you build — internal Q&A bot, customer support agent, study buddy — starts as a single `context.txt` and grows from there. Add more files. Add a retriever. Add tool calls. The skeleton never changes; the data grows.

**Analogy:** Same actor (the model), same theater (the script code), new script pages (`context.txt`). The audience sees a brand-new play.

**Expected output:**

```
You: what happened on tuesday?
Bot: The dame asked me what happened on tuesday, and I told her some questions are like cheap whiskey - they burn going down and leave you sleeping in your overcoat...and that was that.
```

**Troubleshoot**

| Symptom | Fix |
|---|---|
| Bot still uses old persona | Old python process is still running with the old text cached — restart it |
| Persona only half-applies | The persona is contradictory; tighten the rules in `context.txt` |

---

### Task 20 — Interview scenario: load context from a CLI argument

**Task statement:** *"Modify your chatbot so the context file path is a CLI argument, not hardcoded. If no argument is provided, fall back to `../context.txt`. Demonstrate by running the same script with two different context files in the same terminal."*

**R:**

```r
args <- commandArgs(trailingOnly = TRUE)
context_path <- if (length(args) >= 1) args[[1]] else file.path("..", "context.txt")
```

**Python:**

```python
import sys
context_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join("..", "context.txt")
```

**C#:**

```csharp
string contextPath = args.Length > 0
    ? args[0]
    : Path.Combine("..", "..", "context.txt");
```

Run it:

```powershell
Rscript chatbot.R ../personas/fortune.txt
Rscript chatbot.R ../personas/detective.txt
```

**Human-Readable Breakdown:**
> "Hey shell, run the same script twice with two different context files. The first run loads the fortune teller. The second run loads the detective. Same code, same compiled binary, different `.txt` argument. **This is the single most common follow-up question in an LLM-app interview** — they want to see that you understand the context file is *input*, not source code."

**Reading it left to right:**
- `commandArgs(trailingOnly = TRUE)` -> "R's CLI args, *without* the leading interpreter args."
- `sys.argv[1] if len(sys.argv) > 1 else ...` -> "Python's idiom: `sys.argv[0]` is the script name, `[1]` is the first real argument."
- `args.Length > 0 ? args[0] : ...` -> "C# top-level program receives `args` automatically. Ternary picks the first arg or the default."

**The story:** Every interview ever asks some variant of *"how would you make this configurable?"* The progression is always: hardcoded -> file-loaded -> CLI-loaded -> env-var-loaded -> config-file-loaded -> remote-config-loaded. This task is rung 3. Once you have it, you can argue your way through every rung above and below. **The hidden lesson** — every step in that ladder is the same idea: *push the value further from the source code, closer to the operator.* `context.txt` is one step. CLI args are the next. RAG retrieval is the rung where the value doesn't even exist until runtime.

**Analogy:** A bot is a record player. The code is the turntable. `context.txt` is the album. The CLI argument is the album *number* — slot in any record from your shelf, the turntable doesn't care.

**Step-by-step rationale**

| Step | Why |
|---|---|
| Read `args` first | So the default never overrides an explicit user choice |
| Fall back to `../context.txt` | Backwards compatible — old runs still work |
| Same file across all three languages | Cross-language `personas/` folder = a shared persona library |
| One process per persona | Avoids the cache problem in Task 19 |

**Troubleshoot**

| Symptom | Fix |
|---|---|
| Script reads default even with an arg | You read `args[0]` in R (which is wrong — R is 1-indexed for CLI args via `args[[1]]`) |
| `IndexError` in Python | You wrote `sys.argv[1]` without the `len > 1` guard |
| C# `args` is empty when running from Visual Studio | Set the launch profile's "Command line arguments" field |

---

## Context-Loading Decision Guide

```
Got a "bot ignores my context.txt" problem?
  |
  +-- Did the file actually load?
  |     -> Print nchar/len/Length. Zero means path wrong or wrong cwd.
  |
  +-- Is the path resolved from the right cwd?
  |     -> R/python: cd into the language folder before running.
  |     -> C#: cwd is bin/Debug/net8.0; count the `..` from there.
  |
  +-- Did UTF-8 decode correctly?
  |     -> Accented chars / emojis show as ? -> add encoding="UTF-8".
  |
  +-- Is context in the SYSTEM role?
  |     -> If it's in `user`, the model treats it as a 4000-word question.
  |
  +-- Is the system prompt sent on EVERY call?
  |     -> Yes if it's `messages[0]` and you re-send `messages` each turn.
  |
  +-- Does the context contain contradictions?
        -> Models obey concrete rules > vague rules. Tighten the prompt.
```

---

## Lab Checklist (20 Tasks)

- [ ] 01 Build the repo skeleton (R/, python/, csharp/, context.txt, .env, .gitignore)
- [ ] 02 Write `.gitignore` with `.env` in it
- [ ] 03 Put `OPENAI_API_KEY` in `.env`
- [ ] 04 Write your first `context.txt` with a clear persona
- [ ] 05 R: install `httr2`, `jsonlite`, `dotenv`
- [ ] 06 R: read `context.txt` with `encoding = "UTF-8"`
- [ ] 07 R: build `system_prompt` = base + context, seed `messages`
- [ ] 08 R: write `call_openai(messages)`
- [ ] 09 R: main conversation loop with `quit`
- [ ] 10 R: run end-to-end and chat with the persona
- [ ] 11 Python: venv + `requests` + `python-dotenv`
- [ ] 12 Python: read `.env` and `context.txt` with `encoding="utf-8"`
- [ ] 13 Python: `call_openai(messages)`
- [ ] 14 Python: main loop
- [ ] 15 C#: `dotnet new console` + `DotNetEnv`
- [ ] 16 C#: read `.env` and `context.txt` with `Encoding.UTF8`
- [ ] 17 C#: `CallOpenAI(messages)`
- [ ] 18 C#: main loop
- [ ] 19 Swap `context.txt` to change behavior, all three languages
- [ ] 20 Load context from a CLI arg, all three languages

---

## Common Pitfalls

| Mistake | Symptom | Fix |
|---|---|---|
| Context loaded in `user` role | Bot answers the file as a question | Move to `role: "system"` |
| Forgot `encoding = "UTF-8"` | `?` boxes or mojibake for accents/emojis | Pass UTF-8 explicitly |
| Hardcoded API key | Key leaks on first push | Move to `.env`, add `.env` to `.gitignore` |
| Ran script from repo root, not language folder | `cannot open file '../context.txt'` | `cd R` (or python, or csharp) first |
| `.env` not at repo root | API key reads empty | Move `.env` next to `context.txt` |
| Forgot to append user turn | Bot replies to wrong question | `messages.append({...user...})` *before* the API call |
| Forgot to append assistant turn | Bot has no memory | Append the reply *after* the API call |
| Used `[1]` instead of `[[1]]` in R | Prints `list(...)` instead of text | Use `[[1]]` to extract from a list |
| No timeout in `requests.post` | Script hangs forever on bad network | Pass `timeout=60` |
| C# path counted from project folder | `DirectoryNotFoundException` | C# cwd is `bin/Debug/net8.0/`; count `..` from there |
| Edited `context.txt` mid-session | Old persona persists | Restart the script (file is read once at startup) |

---

## Career & Interview Strategy

**Self-learner**
- Redo Tasks 6, 7, and 9 from memory in R *before* moving to Python. The pattern is the lesson; the second language proves you learned it.

**Portfolio / GitHub**
- Pin this repo. Add a 30-second screen recording of swapping `context.txt` and watching the bot's personality change. Hiring managers love it because it shows the data/code split visually.

**AI Engineer interview**
- Practice saying out loud: *"The context belongs in the system role because it's a standing instruction, not a turn. The whole history goes on every call because the API is stateless. UTF-8 because Windows defaults to cp1252."* Three sentences, one job offer.

**RAG-system engineer (next stop)**
- The exact `call_openai(messages)` function you wrote here is the function a RAG system calls *after* the retriever returns chunks. Add one line — `system_prompt += retrieved_chunks` — and you have a primitive RAG bot. That is Project 5 and beyond.

**Prompt engineer**
- Version `context.txt` files in git. Tag releases. Diff personas across versions. You are now a prompt engineer with a workflow, not a person editing strings in `Program.cs`.

---

## Related Projects

| Project | Connection |
|---|---|
| [`Hello_LLM`](https://github.com/kelvintechnical/Hello_LLM) | One-shot call — the simplest possible version |
| [`Persona_Bot`](https://github.com/kelvintechnical/Persona_Bot) | Persona introduced, still in code |
| [`Chatbot_with_memory`](https://github.com/kelvintechnical/Chatbot_with_memory) | Memory introduced via `messages` history |
| **This lab (`ContextFromFile`)** | Persona externalized to `.txt` |
| [`PDF_Reader_Bot`](https://github.com/kelvintechnical/PDFReaderBot) | Same pattern, PDF reader instead of plain text |
| Later in the series | Multi-doc concatenation, top-K retrieval, full RAG |

---

## Why This Lab Is the Hardest One in the First Five

The first three projects only asked you to type code in **one** language. This project asks for **three** languages, **one** shared data file, **two** new concepts (UTF-8 file I/O and prompt injection), and **one** uncomfortable mental shift (data is not code).

If you quit the first time, you quit because the lab is genuinely 3x the surface area of the previous ones. The fix is not "try harder." The fix is **finish R first, then Python, then C#, in that order**, and **do not start the next language until the previous one runs end-to-end**. The trilingual payoff arrives in Python — that is the moment you realize you already know the algorithm and you are only translating syntax. C# is then almost free.

---

## Author

**Kelvin R. Tobias**
[kelvinintech.com](https://kelvinintech.com) · [GitHub](https://github.com/kelvintechnical) · [LinkedIn](https://www.linkedin.com/in/kelvin-r-tobias-211949219)

Part of the compounding trilingual learning series: **build once, learn three times.**

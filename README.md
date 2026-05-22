# Lab 04: ContextFromFile — The Bot Whose Brain Lives in a Text File

**Series:** `trilingual-coding-compounding` · **Project 4 of the LLM-from-scratch path**
**Subjects covered:** file I/O, UTF-8 encoding, safe path handling, prompt injection, system vs user role, separation of data from code, multi-turn chat loop, message history, env-based secrets
**Languages required:** **R**, **Python**, **C#** (build once, learn three times — every task teaches all three)
**Career arcs covered:** AI Engineer (foundation), LLM application developer (immediate need), Prompt Engineer (daily skill), RAG-system developer (next stop)
**Prerequisite:** Project 3 (`Chatbot_with_memory`) — env loading, HTTP POST, JSON parsing, system-seeded `messages`, infinite loop with `quit`
**Time Estimate:** 90–120 minutes (you build all three languages task-by-task, not language-by-language)
**Difficulty arc:** Tasks 1–4 setup · 5–9 loading the brain · 10–12 the API call · 13–17 the chat loop · 18–20 interview-realistic

---

## Objective

Build a chatbot whose **personality, knowledge, and rules live in an external `.txt` file**, not in your source code. By the end of this lab you can: swap a bot's behavior by editing one file (no recompile), read UTF-8 text safely on Windows without `?` boxes for emojis or accents, inject loaded text into the **system role** of an OpenAI chat call, and explain *why* context belongs in `system` and not `user`. You build the bot in all three languages **at the same time, one concept at a time** — so by Task 17 you have R, Python, and C# bots that all read the same `context.txt`.

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
+-- python/chatbot.py        each language is a different
+-- csharp/Program.cs        wrapper around the same idea
```

The wrapper code does five things, in order, every time you start it — and the order is **identical in all three languages**:

1. Read `OPENAI_API_KEY` from `.env`.
2. Read `context.txt` from disk (UTF-8).
3. Build `system_prompt = base_instructions + context_text`.
4. Seed the `messages` list with one entry: `{role: "system", content: system_prompt}`.
5. Loop: read user input → append → POST to OpenAI → append reply → repeat until `quit`.

The breakthrough is step 2. **Once context lives in a file, a non-programmer can change the bot.** A teacher can drop in a syllabus, a lawyer can drop in case notes, a designer can rewrite the persona — and the source code never opens.

> **Why this matters:** This is the first project where the bot's behavior is **data**, not **code**. That single shift is the foundation of every retrieval-augmented system on Earth.

---

## Why External Context Exists — The Story

**Project 1 era (`Hello_LLM`):** One-shot call. One user message, one reply. The personality is whatever the base model thinks. Changing the bot means rewriting a string in source code.

**Project 2 era (`Persona_Bot`):** The `system` role is born — a string prepended to the conversation that the model treats as standing instructions. The persona still lives in `system_prompt = "You are a pirate..."` in source code. Change persona = edit code, push code, restart.

**Project 3 era (`Chatbot_with_memory`):** We pass the full `messages` array on every turn so the bot remembers earlier exchanges. The persona is still in source code.

**Project 4 (this lab, GPT-3.5 / GPT-4 era ~2022):** Teams realized two painful truths:
1. **Prompts change more often than code.** A prompt engineer iterates 50 times a day. A code deploy is a 20-minute ritual.
2. **Non-developers should be able to edit prompts.** PMs, lawyers, teachers — the people who *know* what the bot should say — should not need to open `.py`, `.R`, or `.cs`.

The fix was embarrassingly simple: **move the prompt out of source code and into a `.txt` file.** Read it at startup. Inject it into the system role. That's the whole lab.

**Project 5 (`PDF_Reader_Bot`):** Same trick, fancier reader (PDF → text → inject).

**RAG era (2023+):** Same trick, *retrieved* text — vector-search a knowledge base for the chunks most relevant to the user's question, inject the top K chunks into the system prompt. Every "chat with your docs" product is this Project 4 pattern with a retrieval step bolted in front.

> **The point of the story:** External context is the *primitive* that unlocks every later abstraction. Master this lab and you have already mastered 80% of the mental model for RAG.

---

## The Context Family — Who Lives There

**The direct siblings (by how the context is sourced):**

| Family member | Where context comes from | Where you meet it |
|---|---|---|
| **Inline persona** | A string literal in source code | Project 2, every quick demo |
| **File-loaded context** | One `.txt` from disk (this lab) | Project 4, internal tools |
| **PDF-extracted context** | Text extracted from a PDF | Project 5 |
| **Multi-doc concatenated context** | Several files glued into one prompt | Small KB bots |
| **Retrieved context (RAG)** | Top-K chunks from a vector store | Notion AI, ChatGPT custom GPTs |
| **Tool/function definitions** | A JSON schema sent alongside `messages` | OpenAI function calling, agents |

**The three roles in a chat request (the three slots context can fill):**

| Role | What the model treats it as | Typical use |
|---|---|---|
| `system` | **Standing instructions** for the whole conversation | Persona, policy, loaded knowledge — *put context here* |
| `user` | **One turn** in the thread | The live question for this round |
| `assistant` | **One reply** from the model | Appended after each API call to preserve memory |

> **Critical rule:** File-backed context is a *standing instruction*, so it belongs in the **system** role — not as a fake first user turn. Putting it in `user` makes the model think you just asked a 4,000-word question.

**The cousins (same pattern, other libraries):**

| Cousin | Library / ecosystem | Notable difference |
|---|---|---|
| `PromptTemplate` | LangChain (Python) | Adds variable substitution (`{name}`) before injection |
| `Document` | LlamaIndex (Python) | Adds chunking + metadata for retrieval |
| `.skprompt.txt` files | Semantic Kernel (C#) | File-based prompts as a first-class concept |
| `ChatOptions.SystemInstruction` | Microsoft.Extensions.AI (C#) | C# wrapper for the same system-role seed |
| Custom GPT "Instructions" box | OpenAI ChatGPT UI | Same `.txt` idea, hosted UI instead of disk |

---

## The Anatomy of a Context-Backed Chat Request — In Layers

Reading the whole JSON body as one giant blob is overwhelming. Reading it as **eight small layers** is easy. We build the request from the outside in.

### Layer 1: The HTTP envelope (the address on the package)

```
POST https://api.openai.com/v1/chat/completions
Authorization: Bearer sk-...
Content-Type: application/json
```

Three lines, three jobs:

| Line | What it tells the server |
|---|---|
| `POST <url>` | Which endpoint and HTTP verb (always `POST` for chat) |
| `Authorization: Bearer <key>` | *Who* is asking — your secret API key from `.env` |
| `Content-Type: application/json` | *How* to read the body bytes — as JSON |

> The Authorization header is the only line that's secret. Everything else is identical for every OpenAI chat call ever made.

---

### Layer 2: The request body — outer shape (the two-key envelope)

```json
{
  "model":    "gpt-4o-mini",
  "messages": [ ... ]
}
```

Two top-level keys. That is the whole body.

| Key | What you put there |
|---|---|
| `model` | A string naming the model: `gpt-4o-mini`, `gpt-4o`, `gpt-3.5-turbo`, etc. |
| `messages` | An **array** of message objects — we expand this in Layer 3 |

> Every fancy thing you'll ever add (`temperature`, `max_tokens`, `tools`, `response_format`) is just *more keys at this same outer level*. The two above are the only **required** ones.

---

### Layer 3: One message object (the brick the wall is built from)

```json
{
  "role":    "system",
  "content": "You are a helpful assistant."
}
```

Every entry in `messages` is exactly this two-key shape:

| Key | What it does |
|---|---|
| `role` | Who is "speaking" — one of `system`, `user`, `assistant` |
| `content` | The actual text |

That's it. The entire chat API is built out of these two-key bricks stacked into an array.

---

### Layer 4: The three roles, side by side

| Role | Spoken by | When you use it | Sent how often |
|---|---|---|---|
| `system` | You (the developer) | Standing instructions for the whole chat | Once at index 0, **re-sent every call** |
| `user` | The human typing | One question / one turn | Appended each turn |
| `assistant` | The model | A reply | Appended after each API call |

> **The Project 4 trick:** Put your `context.txt` text into a **system** message. The model then follows it on every reply.

---

### Layer 5: The system message — where `context.txt` gets injected

```json
{
  "role": "system",
  "content": "You are a helpful assistant. Follow the persona below.

---
<entire contents of context.txt go right here>"
}
```

The `content` of the system message is a single string you **build at startup** by concatenating three pieces:

```
   base_instructions       +       separator       +       context_text_from_file
   (a short in-code rule)          (\n\n---\n)             (the entire .txt file)
```

- **`base_instructions`** — a short in-code rule like *"Follow the persona below exactly."*
- **`separator`** — a divider like `\n\n---\n` so the model doesn't blur the two halves.
- **`context_text_from_file`** — the entire `context.txt` you read in Task 7 of this lab.

> **This is the only "new" step in Project 4.** Everything else is Project 3 retyped.

---

### Layer 6: The full messages stack (after two conversation turns)

```json
"messages": [
  { "role": "system",    "content": "<base + context.txt>" },
  { "role": "user",      "content": "What is broadcasting?" },
  { "role": "assistant", "content": "Broadcasting is..." },
  { "role": "user",      "content": "Give me an example." }
]
```

Three rules govern the stack:

1. The **system** message is always at index 0 and **never changes**.
2. **User** and **assistant** messages alternate, appended in the order they happened.
3. The **last** message is the one the model is being asked to respond to *right now*.

> The whole array is sent on every call. OpenAI's API is **stateless** — memory lives in your `messages` list, not on their server.

---

### Layer 7: The response — only one field matters

```json
{
  "id": "chatcmpl-abc123",
  "choices": [
    {
      "index": 0,
      "message": {
        "role":    "assistant",
        "content": "Broadcasting is when PyTorch..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": { "prompt_tokens": 412, "completion_tokens": 87, "total_tokens": 499 }
}
```

Most fields are metadata for logging and billing. The **single field** you extract is:

```
choices  ->  [0]  ->  message  ->  content
```

Read it out loud: *"choices, zero, message, content."* Internalize that phrase — every OpenAI client on GitHub uses this exact drill.

---

### Layer 8: The extraction path in three languages

```r
parsed$choices[[1]]$message$content              # R (1-indexed, $ for fields, [[ ]] to extract list element)
```

```python
resp.json()["choices"][0]["message"]["content"]  # Python (0-indexed, [] for keys and arrays)
```

```csharp
doc.RootElement.GetProperty("choices")[0]
              .GetProperty("message")
              .GetProperty("content").GetString();  // C# (typed, GetProperty for objects, [i] for arrays)
```

Same drill, three syntaxes. **The drill is identical; only punctuation changes.**

---

## Trilingual Reference Table

The single most important table in this lab. Every row is one concept expressed three ways. Bookmark it.

| Concept | R | Python | C# |
|---|---|---|---|
| Import library | `library(httr2)` | `import requests` | `using System.Net.Http;` |
| Load `.env` | `dotenv::load_dot_env("../.env")` | `load_dotenv("../.env")` | `DotNetEnv.Env.Load("../.env")` |
| Read env var | `Sys.getenv("OPENAI_API_KEY")` | `os.getenv("OPENAI_API_KEY")` | `Environment.GetEnvironmentVariable("OPENAI_API_KEY")` |
| Relative path | `file.path("..", "context.txt")` | `os.path.join("..", "context.txt")` | `Path.Combine("..", "context.txt")` |
| Read UTF-8 file | `paste(readLines(p, encoding="UTF-8"), collapse="\n")` | `open(p, encoding="utf-8").read()` | `File.ReadAllText(p, Encoding.UTF8)` |
| String concat | `paste0(a, "\n", b)` | `f"{a}\n{b}"` | `$"{a}\n{b}"` |
| Build JSON | `jsonlite::toJSON(list(...))` | `json.dumps({...})` or pass `json=` | `JsonSerializer.Serialize(new {...})` |
| POST request | `request(url) \|> req_body_json(body) \|> req_perform()` | `requests.post(url, json=body, headers=...)` | `await http.PostAsync(url, content)` |
| Auth header | `req_headers(Authorization = paste("Bearer", k))` | `headers={"Authorization": f"Bearer {k}"}` | `http.DefaultRequestHeaders.Authorization = new("Bearer", k)` |
| Parse JSON | `resp_body_json(resp)` | `resp.json()` | `JsonDocument.Parse(raw)` |
| Extract content | `parsed$choices[[1]]$message$content` | `resp.json()["choices"][0]["message"]["content"]` | `doc.RootElement.GetProperty("choices")[0]...GetString()` |
| List/array | `list(...)` | `[...]` | `new List<T> {...}` |
| Append to list | `lst[[length(lst)+1]] <- x` | `lst.append(x)` | `lst.Add(x)` |
| Infinite loop | `while (TRUE) { ... }` | `while True: ...` | `while (true) { ... }` |
| Read stdin | `readline("You: ")` | `input("You: ")` | `Console.ReadLine()` |
| Lowercase + trim | `tolower(trimws(s))` | `s.strip().lower()` | `s.Trim().ToLower()` |
| Exit loop | `break` | `break` | `break;` |

> **Rule #1 of trilingual learning:** Build one mental model per row, three syntaxes per row. The model is the point — the syntax is the price you pay.

---

## Career Pathway Sidebar

| Level | Why this lab matters |
|---|---|
| **Self-taught beginner** | First time your bot is editable without code — the moment LLM apps feel real |
| **AI Engineer interview** | "How would you let a PM change the prompt without a deploy?" — this exact pattern |
| **LLM application dev** | Every internal tool starts as a single `context.txt` before becoming a vector store |
| **RAG-system engineer** | The injection step in RAG is *literally* this code, fed by a retriever |
| **Prompt engineer** | You version `.txt` files in git instead of editing strings in source files |

---

## Project Structure

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
`-- README.md
```

> All three language folders sit one level deep, so each can reach the shared `context.txt` and `.env` with the same `..` jump. **The single shared file proves the point of the lab — the data is decoupled from the code, in all three languages simultaneously.**

---

## The 20 Tasks — All Three Languages, One Task at a Time

> **The trilingual rule:** Tasks 1–4 are universal setup. From Task 5 onward, every task shows R, Python, and C# code blocks side by side under one shared concept. Complete each task in **all three languages before moving on** — that's the whole compounding trick. By Task 17, you have three working bots that all read the same `context.txt`.
>
> Each task includes: **Purpose**, **Human-Readable Breakdown**, three code blocks (R / Python / C#) each with their own **Reading it left to right**, then a shared **The story**, **Analogy**, **Expected output**, **Switches** table (one row per concept, columns for each language), and **Troubleshoot** table.

---

### Task 1 — Build the repo skeleton (universal)

**Purpose:** A predictable folder shape means every later task knows where every file lives — in every language.

```powershell
mkdir ContextFromFile
cd ContextFromFile
mkdir R, python, csharp
New-Item context.txt, .env, .gitignore, README.md -ItemType File
```

**Human-Readable Breakdown:**
> "Hey shell, make a folder called `ContextFromFile`. Step into it. Make three subfolders, one per language. Make four empty files at the root: the context file, the secrets file, the gitignore, and the readme."

**Reading it left to right:**
- `mkdir ContextFromFile` → create the project root.
- `cd ContextFromFile` → step in so every later path is relative to here.
- `mkdir R, python, csharp` → three sibling code folders (PowerShell takes a comma-separated list).
- `New-Item ... -ItemType File` → create empty files. `-ItemType File` is required or PowerShell creates folders.

**The story:** The repo root holds **data** (`context.txt`, `.env`) and **documentation** (`README.md`). Each language folder holds **code**. That separation is the whole point of this lab — when a teammate edits `context.txt`, no language folder is touched, no commit conflicts, no rebuild. It is also why every code file uses `..` to reach the data: the data is *above* the code, conceptually and on disk.

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

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `New-Item: A positional parameter cannot be found` | Add `-ItemType File` |
| Folder already exists error | `cd` into the existing one instead |

---

### Task 2 — Write `.gitignore` so secrets never get committed (universal)

**Purpose:** The single biggest beginner mistake in LLM projects is pushing an API key to GitHub.

`.gitignore`:

```text
.env

# R
.Rhistory
.Rproj.user/

# Python
__pycache__/
*.pyc
.venv/

# C#
bin/
obj/
.vs/
```

**Human-Readable Breakdown:**
> "Hey git, never track these. The `.env` file holds my API key — if it ever lands on GitHub, scraper bots find it in under 60 seconds and drain it. The other lines are language-specific build/session noise that nobody else needs."

**The story:** GitHub has bots scanning every public push for keys matching `sk-...`. They find leaked OpenAI keys in under 60 seconds and immediately use them. Add `.env` to `.gitignore` *before* you ever run `git add .`. Every senior engineer has a story about the time they didn't.

**Analogy:** A bouncer at the door of your repo with a clipboard. `.env` is not on the list. It stays outside.

**Troubleshoot**

| Symptom | Fix |
|---|---|
| `.env` is already tracked | `git rm --cached .env`, commit |
| Key already pushed | **Rotate it on the OpenAI dashboard immediately** — deleting the commit is not enough |

---

### Task 3 — Put your API key in `.env` (universal)

**Purpose:** Secrets live in env files, never in source code.

`.env`:

```text
OPENAI_API_KEY=sk-your-real-key-here
```

**Human-Readable Breakdown:**
> "Hey dotenv loaders (all three of them), the program will look for a variable named `OPENAI_API_KEY` at startup. Here's its value. One line, no quotes, no spaces around the equals sign, no `export` prefix."

**The story:** The `.env` file is the universal convention across every modern language for *"non-secret-enough-to-need-a-vault but secret-enough-to-keep-out-of-git."* R, Python, and C# all have a `dotenv` library that reads this exact format. **One file, three readers** — that is why this lab can stay trilingual without a config-file fight.

**Analogy:** A sticky note on your monitor with the WiFi password. You see it when you sit down, no one else does, it doesn't live in your code.

**Troubleshoot**

| Symptom | Fix |
|---|---|
| Key reads as empty string | Spaces around `=`, or quotes wrapping the value |
| Key starts with `sk-proj-...` | That's fine — newer OpenAI keys look like this |

---

### Task 4 — Write your first `context.txt` (universal)

**Purpose:** The whole lab exists to load this file. Make sure it has personality.

`context.txt`:

```text
You are a cryptic fortune teller who speaks only in riddles.
When the user asks a question, respond with exactly one short fortune
(1-2 sentences) that hints at the answer but never states it directly.
Always end with: "The stars remain silent on further details."
```

**Human-Readable Breakdown:**
> "Hey future bot (in any language), here is who you are. You speak in riddles. You give one short fortune per reply. You always end with the same closing line. Three rules — the model will follow them as the laws of physics for the rest of the conversation."

**The story:** A good `context.txt` reads like a one-page job description: who you are, what you do, what you never do, how you sign off. **Vague prompts produce vague bots. Specific prompts produce specific bots.** The whole field of prompt engineering is this lesson, learned 10,000 times.

**Analogy:** A character sheet for a tabletop RPG. Stats, voice, catchphrase. The model improvises *within* the character, never *outside* it.

**Troubleshoot**

| Symptom | Fix |
|---|---|
| Bot ignores the persona after a few turns | Too vague — add concrete rules |
| Replies are too long | Add `1-2 sentences` or `under 50 words` |

---

### Task 5 — Install dependencies (R, Python, C#)

**Purpose:** Each language needs a small set of libraries to (1) read `.env`, (2) send HTTP POSTs, (3) build/parse JSON.

**Human-Readable Breakdown:**
> "Hey package manager (whichever one), install the few pieces my language needs. Run once per machine, never again."

#### R

```r
install.packages(
  c("httr2", "jsonlite", "dotenv"),
  repos = "https://cloud.r-project.org"
)
```

**Reading it left to right (R):**
- `install.packages(c(...))` → install from CRAN. `c(...)` is the vector literal.
- `"httr2"` → modern HTTP client (pipe-friendly).
- `"jsonlite"` → JSON build/parse.
- `"dotenv"` → `.env` reader.
- `repos = "..."` → skip the interactive mirror picker.

#### Python

```powershell
cd python
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install requests python-dotenv
```

`python/requirements.txt`:

```text
requests>=2.31
python-dotenv>=1.0
```

**Reading it left to right (Python):**
- `python -m venv .venv` → create an isolated sandbox.
- `Activate.ps1` → switch `python`/`pip` to point inside the sandbox.
- `requests` → HTTP client.
- `python-dotenv` → `.env` reader.
- JSON is the standard library's `json` module — no install needed.

#### C#

```powershell
cd csharp
dotnet new console -n ContextFromFile
cd ContextFromFile
dotnet add package DotNetEnv
```

**Reading it left to right (C#):**
- `dotnet new console -n Name` → scaffold a console app (creates `Program.cs` + `.csproj`).
- `dotnet add package DotNetEnv` → install the `.env` reader from NuGet.
- HTTP (`System.Net.Http`) and JSON (`System.Text.Json`) ship with .NET — no install needed.

**The story:** R needs three packages because JSON and dotenv ecosystems are separate from the HTTP one. Python needs two because `json` is stdlib. C# needs **one** because both `HttpClient` and `JsonSerializer` ship with .NET. This is why **C# is the leanest of the three for LLM work** despite its reputation for being heavy.

**Analogy:** Filling your toolbox. R brings three drawers, Python two, C# one.

**Expected output:** package install logs ending in success messages. (For Python you'll also see the `(.venv)` prefix in your prompt.)

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| Install package | `install.packages("x")` | `pip install x` | `dotnet add package X` |
| HTTP library | `httr2` (third-party) | `requests` (third-party) | `HttpClient` (built-in) |
| JSON library | `jsonlite` (third-party) | `json` (built-in) | `JsonSerializer` (built-in) |
| `.env` reader | `dotenv` (third-party) | `python-dotenv` (third-party) | `DotNetEnv` (third-party) |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| R | `package 'httr2' is not available` | Update R itself (need 4.1+) |
| Python | `Activate.ps1 cannot be loaded` | Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once |
| C# | `dotnet: command not found` | Install .NET SDK 8 from microsoft.com/dotnet |

---

### Task 6 — Load `.env` and pull the API key

**Purpose:** Pull `OPENAI_API_KEY` out of `.env` and into a regular variable, **without ever hardcoding it**.

**Human-Readable Breakdown:**
> "Hey language, read the `.env` file one folder up. That registers `OPENAI_API_KEY` as a process environment variable. Now read that variable into a regular variable I can use. If it's empty/null, that's a startup-time crash — better to die now with a clear message than later in a confusing HTTP 401."

#### R

```r
library(dotenv)

dotenv::load_dot_env("../.env")
api_key <- Sys.getenv("OPENAI_API_KEY")

if (api_key == "") stop("OPENAI_API_KEY missing from .env")
```

**Reading it left to right (R):**
- `library(dotenv)` → load the package.
- `load_dot_env("../.env")` → read `.env` one folder up (we're inside `R/`).
- `Sys.getenv("OPENAI_API_KEY")` → returns `""` if missing — no error.
- `if (api_key == "") stop(...)` → fail loudly on startup.

#### Python

```python
import os
from dotenv import load_dotenv

load_dotenv("../.env")
API_KEY = os.getenv("OPENAI_API_KEY")

if not API_KEY:
    raise RuntimeError("OPENAI_API_KEY missing from .env")
```

**Reading it left to right (Python):**
- `from dotenv import load_dotenv` → just the function we need.
- `load_dotenv("../.env")` → read `.env` one folder up.
- `os.getenv("OPENAI_API_KEY")` → returns `None` if missing.
- `if not API_KEY: raise ...` → fail loudly.

#### C#

```csharp
using DotNetEnv;

Env.Load("../../.env");
string apiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY")
                ?? throw new InvalidOperationException("OPENAI_API_KEY missing from .env");
```

**Reading it left to right (C#):**
- `using DotNetEnv;` → import the namespace.
- `Env.Load("../../.env")` → read `.env` *two* folders up because `dotnet run` runs the binary from `bin/Debug/net8.0/`, not from the project folder.
- `Environment.GetEnvironmentVariable("OPENAI_API_KEY")` → returns `null` if missing.
- `?? throw new ...` → null-coalesce: if the left side is null, throw.

**The story:** All three languages do the same three steps: (1) load the file into the process env, (2) read the env var, (3) fail loudly if it's missing. The differences are skin-deep — R returns `""`, Python returns `None`, C# returns `null`. **The pattern of "fail loud at startup" is the senior-engineer reflex** — debugging an `HTTP 401` two minutes into a chat session is a hundred times worse than debugging "your env file is missing" at second one.

**Analogy:** Checking your wallet before you leave the house. If the key isn't there, don't drive to the airport — fix it now.

**Expected output:** nothing if the key loads. A clear error message if it doesn't.

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| Load `.env` | `load_dot_env("../.env")` | `load_dotenv("../.env")` | `Env.Load("../../.env")` |
| Read env var | `Sys.getenv("K")` | `os.getenv("K")` | `Environment.GetEnvironmentVariable("K")` |
| Missing returns | `""` (empty string) | `None` | `null` |
| Fail loudly | `stop("...")` | `raise RuntimeError(...)` | `?? throw new ...` |
| Path depth | `"../.env"` (from R/) | `"../.env"` (from python/) | `"../../.env"` (from bin/Debug/net8.0/) |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| R | `api_key` is `""` | `.env` not at repo root, or wrong variable name |
| Python | `API_KEY` is `None` | Same — confirm `.env` location |
| C# | `DirectoryNotFoundException` from `Env.Load` | Path count wrong — C# cwd is `bin/Debug/net8.0/` |

---

### Task 7 — Read `context.txt` as UTF-8

**Purpose:** This is the **new skill** of the lab. Get it right and the bot speaks in your context's voice; get it wrong and accented characters turn into `?` boxes.

**Human-Readable Breakdown:**
> "Hey language, build a relative path to `context.txt` one folder up. Read the whole file as UTF-8 — this matters on Windows where the default encoding is *not* UTF-8. Glue the lines into one string. Print the character count as a sanity check."

#### R

```r
context_path  <- file.path("..", "context.txt")
context_lines <- readLines(context_path, warn = FALSE, encoding = "UTF-8")
context_text  <- paste(context_lines, collapse = "\n")

cat("Loaded context length:", nchar(context_text), "chars\n")
```

**Reading it left to right (R):**
- `file.path("..", "context.txt")` → OS-safe relative path.
- `readLines(p, warn = FALSE, encoding = "UTF-8")` → vector of strings, one per line. `warn = FALSE` silences the "incomplete final line" nag. **`encoding = "UTF-8"` is non-negotiable on Windows.**
- `paste(lines, collapse = "\n")` → glue vector into one string with newline separators.
- `nchar(s)` → character count.

#### Python

```python
import os

CONTEXT_PATH = os.path.join("..", "context.txt")
with open(CONTEXT_PATH, "r", encoding="utf-8") as f:
    context_text = f.read()

print(f"Loaded context length: {len(context_text)} chars")
```

**Reading it left to right (Python):**
- `os.path.join("..", "context.txt")` → OS-safe path.
- `with open(p, "r", encoding="utf-8") as f` → text-read mode, **UTF-8 explicit**. The `with` block auto-closes the file.
- `f.read()` → read the entire file into one string.
- `len(s)` → character count.

#### C#

```csharp
using System.IO;
using System.Text;

string contextPath = Path.Combine("..", "..", "context.txt");
string contextText = File.ReadAllText(contextPath, Encoding.UTF8);

Console.WriteLine($"Loaded context length: {contextText.Length} chars");
```

**Reading it left to right (C#):**
- `Path.Combine("..", "..", "context.txt")` → OS-safe path. Note: **two `..` segments** because C# runs from `bin/Debug/net8.0/`.
- `File.ReadAllText(path, Encoding.UTF8)` → one call, UTF-8 explicit.
- `contextText.Length` → character count (property, not method).

**The story:** All three languages default to *something other than UTF-8* on Windows. R defaults to your locale (often `windows-1252`). Python defaults to `cp1252`. C# can also pick up the system code page. **Pass `UTF-8` explicitly every time and your code stops being a locale lottery.** Skip it once and your fortune teller's accented characters render as `?` boxes or `<U+00E9>` mojibake — a confusing failure mode that wastes 30 minutes the first time you hit it. The `..` path is a different gotcha: R and Python jump one folder up, C# jumps **two** because `dotnet run` starts the binary from `bin/Debug/net8.0/`. Print `getwd()` / `os.getcwd()` / `Directory.GetCurrentDirectory()` if you're unsure.

**Analogy:** UTF-8 is the universal language of text on the modern internet. `encoding = "UTF-8"` is the visa stamp that lets your text cross any border without being mangled.

**Expected output (any language):**

```
Loaded context length: 247 chars
```

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| Build path | `file.path("..", "x")` | `os.path.join("..", "x")` | `Path.Combine("..", "..", "x")` |
| Read UTF-8 file | `readLines(p, encoding="UTF-8")` + `paste(..., collapse="\n")` | `open(p, encoding="utf-8").read()` | `File.ReadAllText(p, Encoding.UTF8)` |
| Length | `nchar(s)` | `len(s)` | `s.Length` |
| Auto-close | n/a (immediate read) | `with ... as f:` block | n/a (one-call API) |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| R | `cannot open file '../context.txt'` | You didn't `cd R` first — `..` resolves from your shell's cwd |
| R | Accented chars print as `?` | Add `encoding = "UTF-8"` |
| Python | `UnicodeDecodeError` | You forgot `encoding="utf-8"` |
| Python | `FileNotFoundError` | You didn't `cd python` first |
| C# | `DirectoryNotFoundException` | Count `..` from `bin/Debug/net8.0/`, not from the project folder |
| C# | Console prints `?` for non-ASCII | Add `Console.OutputEncoding = Encoding.UTF8;` at the top |

---

### Task 8 — Build the `system_prompt` by injecting context

**Purpose:** Concatenate **base instructions** + **separator** + **context_text** into one string that will be the system message.

**Human-Readable Breakdown:**
> "Hey language, write a short in-code base instruction. Now concatenate three pieces: base instructions, then a visual separator (`\n\n---\n`), then the entire context file. The result is one big string. **This is the moment external data becomes part of the model's brain.**"

#### R

```r
base_instructions <- "You are a helpful assistant. Follow the persona and rules below exactly."

system_prompt <- paste0(
  base_instructions,
  "\n\n---\n",
  context_text
)
```

**Reading it left to right (R):**
- `base_instructions <- "..."` → assign a short in-code instruction.
- `paste0(a, b, c)` → concatenate with **no separator**. (`paste()` defaults to space-separated; `paste0` doesn't.)
- `"\n\n---\n"` → the visual divider.

#### Python

```python
base_instructions = "You are a helpful assistant. Follow the persona and rules below exactly."

system_prompt = f"{base_instructions}\n\n---\n{context_text}"
```

**Reading it left to right (Python):**
- `base_instructions = "..."` → assign.
- `f"{a}\n\n---\n{b}"` → f-string interpolation. Same idea as R's `paste0`, inline.

#### C#

```csharp
string baseInstructions = "You are a helpful assistant. Follow the persona and rules below exactly.";

string systemPrompt = $"{baseInstructions}\n\n---\n{contextText}";
```

**Reading it left to right (C#):**
- `string baseInstructions = "...";` → declare and assign.
- `$"{a}\n\n---\n{b}"` → C#'s interpolated string. Identical concept to Python's f-string.

**The story:** This is the most important step of the lab. You have just moved your bot's behavior **from code to data**. From this point on, every new user message is appended to `messages`, every reply is appended to `messages`, and the *whole `messages` list* (including the system prompt with the injected context) is sent on every API call. The model "remembers" the persona on turn 47 the same way it did on turn 1 — because we re-send it every time. **Stateless API, stateful conversation.** The `---` separator is a small but real prompt-engineering trick: without it, the model sometimes treats your `base_instructions` sentence as the first line of `context.txt`.

**Analogy:** Stapling two pages into one document. Base instructions on top, loaded context underneath, one staple line (`---`) in between.

**Expected output:** nothing visible yet — this builds an in-memory string.

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| Concat (no sep) | `paste0(a, b, c)` | `f"{a}{b}{c}"` | `$"{a}{b}{c}"` |
| Concat with sep | `paste(a, b, sep="-")` | `f"{a}-{b}"` or `"-".join([a, b])` | `string.Join("-", a, b)` |
| Newline | `"\n"` | `"\n"` | `"\n"` |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| Any | Bot ignores `base_instructions` | Separator missing, or context contradicts the base — tighten one or the other |
| Any | `context_text` shows as `NULL`/`None`/empty | Task 7 didn't run, or path was wrong |

---

### Task 9 — Seed the `messages` list with the system role

**Purpose:** Create the message stack and put **exactly one** entry in it — the system message containing your `system_prompt`.

**Human-Readable Breakdown:**
> "Hey language, create an empty-ish list of messages. Add one entry — a system-role message whose content is the `system_prompt` from Task 8. This is index 0 of the stack and it never changes for the rest of the conversation."

#### R

```r
messages <- list(
  list(role = "system", content = system_prompt)
)
```

**Reading it left to right (R):**
- `list(...)` → R's list literal.
- `list(role = ..., content = ...)` → one message. R lists support named elements.
- `list(list(...))` → outer list is the message stack; inner list is one message. `jsonlite` will serialize this to JSON exactly the way OpenAI wants.

#### Python

```python
messages = [
    {"role": "system", "content": system_prompt}
]
```

**Reading it left to right (Python):**
- `[ ... ]` → Python list literal.
- `{"role": ..., "content": ...}` → dict with two keys. Same shape as the JSON brick from Layer 3.

#### C#

```csharp
var messages = new List<Dictionary<string, string>>
{
    new() {
        ["role"] = "system",
        ["content"] = systemPrompt
    }
};
```

**Reading it left to right (C#):**
- `new List<Dictionary<string, string>>` → list of dictionaries, both strongly typed.
- `new() { ["role"] = ..., ["content"] = ... }` → C# 9 target-typed `new` with a collection initializer. The `["k"] = v` syntax sets dictionary keys at construction.

**The story:** All three languages build the same shape — a list/array containing one dict/list/dictionary with two keys (`role` and `content`). The serializer in each language will then turn this into the same JSON: `[ { "role": "system", "content": "..." } ]`. **The shape matters; the language doesn't.** Once you can mentally translate "list of two-key dicts" between R `list(list(...))`, Python `[{...}]`, and C# `List<Dictionary>`, you're 70% of the way through the trilingual lab.

**Analogy:** A binder. The binder is the messages list. The first page (system message) is glued in and never removed. New pages (user/assistant turns) will get added behind it.

**Expected output:** nothing visible — this builds an in-memory structure.

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| List literal | `list(a, b, c)` | `[a, b, c]` | `new List<T> { a, b, c }` |
| Dict/named entries | `list(k1 = v1, k2 = v2)` | `{"k1": v1, "k2": v2}` | `new() { ["k1"] = v1, ["k2"] = v2 }` |
| Indexing into list | `lst[[1]]` (extract) vs `lst[1]` (sub-list) | `lst[0]` | `lst[0]` |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| R | `jsonlite` produces `{"role":["system"]}` (array values) | Pass `auto_unbox = TRUE` to `toJSON()` so scalars don't become 1-element arrays |
| Python | `TypeError: ... is not JSON serializable` | Make sure values are strings, not e.g. R-style vectors |
| C# | JSON output has Pascal-cased keys | Use `[JsonPropertyName("role")]` or anonymous objects with lowercase fields |

---

### Task 10 — Send the POST request to OpenAI

**Purpose:** Send the messages stack to `/v1/chat/completions` with the bearer auth header. The response will be one JSON blob we parse in Task 11.

**Human-Readable Breakdown:**
> "Hey language, build a request body containing the model name and the messages list. Set two headers: `Authorization: Bearer <key>` and `Content-Type: application/json`. POST it to OpenAI's chat completions URL. Hold onto the response — we'll parse it in the next task."

#### R

```r
resp <- request("https://api.openai.com/v1/chat/completions") |>
  req_headers(
    Authorization  = paste("Bearer", api_key),
    `Content-Type` = "application/json"
  ) |>
  req_body_json(list(
    model    = "gpt-4o-mini",
    messages = messages
  )) |>
  req_perform()
```

**Reading it left to right (R):**
- `request("...")` → start an httr2 request chain.
- `|>` → R's native pipe (since 4.1). Each step returns a modified request object.
- `req_headers(Authorization = paste("Bearer", api_key))` → bearer auth header.
- `` `Content-Type` `` → backticked because of the hyphen.
- `req_body_json(list(...))` → serialize an R list to JSON and attach as POST body.
- `req_perform()` → **actually send** the request. Returns a response object.

#### Python

```python
import requests

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
```

**Reading it left to right (Python):**
- `requests.post(url, ...)` → entire HTTP call in one function call.
- `headers={...}` → dict of headers.
- `json={...}` → tells `requests` to serialize the dict and set `Content-Type: application/json` automatically.
- `timeout=60` → **always pass this.** Default is no timeout — your script will hang forever on a network blip.
- `resp.raise_for_status()` → throw `HTTPError` on 4xx/5xx so you don't silently parse an error page as JSON.

#### C#

```csharp
using var http = new HttpClient();
http.DefaultRequestHeaders.Authorization =
    new AuthenticationHeaderValue("Bearer", apiKey);

var body = new { model = "gpt-4o-mini", messages = messages };
string json = JsonSerializer.Serialize(body);
using var content = new StringContent(json, Encoding.UTF8, "application/json");

using var resp = await http.PostAsync(
    "https://api.openai.com/v1/chat/completions", content);
resp.EnsureSuccessStatusCode();

string raw = await resp.Content.ReadAsStringAsync();
```

**Reading it left to right (C#):**
- `using var http = new HttpClient()` → one shared client. `using` disposes it at scope exit.
- `new AuthenticationHeaderValue("Bearer", apiKey)` → typed bearer header.
- `new { model = ..., messages = ... }` → anonymous object. Field names become JSON keys verbatim.
- `JsonSerializer.Serialize(body)` → object → JSON string.
- `new StringContent(json, Encoding.UTF8, "application/json")` → HTTP body with UTF-8 and the right MIME type.
- `await http.PostAsync(url, content)` → send. `await` because async.
- `resp.EnsureSuccessStatusCode()` → throw on 4xx/5xx (same idea as Python's `raise_for_status`).
- `await resp.Content.ReadAsStringAsync()` → grab the raw response body for parsing in Task 11.

**The story:** Three languages, identical job: **build a body, attach an auth header, POST to a URL, hold the response.** R does it as a fluent pipe chain. Python does it as one mega-function call. C# does it imperatively across multiple lines. The verbosity rank is C# > R > Python, but **every line of each version maps to a line in the others.** Pair these three snippets up and read them like parallel translations of one paragraph.

**Analogy:** Three different couriers, same package. R hands the package down a pipeline of clerks; Python stuffs everything into one envelope; C# fills out a separate form for each label. The package arrives the same way.

**Expected output:** nothing visible yet — the response is in memory.

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| HTTP client | `request(url)` + `req_perform()` | `requests.post(url, ...)` | `HttpClient.PostAsync(url, ...)` |
| Auth header | `req_headers(Authorization = paste("Bearer", k))` | `headers={"Authorization": f"Bearer {k}"}` | `http.DefaultRequestHeaders.Authorization = new(...)` |
| JSON body | `req_body_json(list(...))` | `json={...}` | `new StringContent(JsonSerializer.Serialize(obj), ...)` |
| Timeout | `req_timeout(60)` (chain step) | `timeout=60` (kwarg) | `http.Timeout = TimeSpan.FromSeconds(60)` |
| Error on non-2xx | `req_error(...)` (auto by default) | `resp.raise_for_status()` | `resp.EnsureSuccessStatusCode()` |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| Any | `HTTP 401` | Bad/missing API key (re-check Task 6) |
| Any | `HTTP 429` | Rate limited — wait or slow the loop |
| Any | `HTTP 400 invalid_request_error` | Body shape wrong — log the body before sending |
| Python | Script hangs | Add `timeout=60` |
| C# | `await` not allowed in main | Use C# 9+ top-level statements or wrap in `async Task Main` |

---

### Task 11 — Parse the JSON response and extract the reply

**Purpose:** Drill into the response to pull out `choices[0].message.content` — the actual reply string.

**Human-Readable Breakdown:**
> "Hey language, parse the response body as JSON. Walk into `choices`, take the first element, walk into `message`, walk into `content`. That string is the bot's reply."

#### R

```r
parsed <- resp_body_json(resp)
reply  <- parsed$choices[[1]]$message$content
```

**Reading it left to right (R):**
- `resp_body_json(resp)` → parse the response body to a nested R list.
- `parsed$choices` → access the `choices` field via `$`.
- `[[1]]` → extract the first element. **`[[1]]` not `[1]`** — `[[` drops the list wrapper, `[` keeps it.
- `$message$content` → drill into the nested fields.

#### Python

```python
reply = resp.json()["choices"][0]["message"]["content"]
```

**Reading it left to right (Python):**
- `resp.json()` → parse body as JSON, return dict/list tree.
- `["choices"]` → key access on dict.
- `[0]` → first element of the list (Python is 0-indexed).
- `["message"]["content"]` → drill in.

#### C#

```csharp
using var doc = JsonDocument.Parse(raw);
string reply = doc.RootElement
                  .GetProperty("choices")[0]
                  .GetProperty("message")
                  .GetProperty("content")
                  .GetString() ?? "";
```

**Reading it left to right (C#):**
- `JsonDocument.Parse(raw)` → low-allocation JSON tree.
- `doc.RootElement.GetProperty("choices")` → walk into the `choices` field.
- `[0]` → first array element.
- `.GetProperty("message").GetProperty("content")` → drill further.
- `.GetString() ?? ""` → pull the string. The `?? ""` defends against `null`.

**The story:** Same drill in three languages. **Read all three out loud:** *"choices, zero, message, content."* That phrase is your interview-ready summary of the OpenAI response shape — say it in any language and people will know you've actually shipped LLM code. The single most common bug in this step is R's `[1]` vs `[[1]]`: `[1]` returns a one-element sublist (which prints as `list(...)`), `[[1]]` extracts the element (which prints as the string). Get it wrong and your `cat()` calls show `list(...)` instead of the reply.

**Analogy:** A treasure-hunt riddle: *"Take the choices, pick the first, find the message, then the content."* Same map, three handwritings.

**Expected output (if you `print(reply)`):**

```
A door that creaks loudest is the one that opens widest, yet the threshold demands one more knock. The stars remain silent on further details.
```

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| Parse JSON | `resp_body_json(resp)` | `resp.json()` | `JsonDocument.Parse(raw)` |
| Field access | `obj$field` | `obj["field"]` | `obj.GetProperty("field")` |
| Array index | `lst[[1]]` (1-indexed) | `lst[0]` (0-indexed) | `lst[0]` (0-indexed) |
| Pull string | (string already) | (string already) | `.GetString()` |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| R | Prints `list(...)` instead of text | You used `[1]` instead of `[[1]]` |
| Python | `KeyError: 'choices'` | Response is an error body, not a chat completion — print `resp.json()` first |
| C# | `KeyNotFoundException` | Same — print `raw` to see what came back |
| Any | Reply is empty string | `finish_reason` was `length`; reply truncated. Raise `max_tokens` |

---

### Task 12 — Wrap it all in a `call_openai(messages)` function

**Purpose:** Combine Tasks 10 and 11 into one reusable function. **One function in, one assistant string out.**

**Human-Readable Breakdown:**
> "Hey language, define a function that takes the current `messages` list and returns the next assistant reply as a string. Inside, do exactly Task 10 (POST) then Task 11 (parse). Isolating the API call in one function gives you one place to add retries, logging, and model switching later."

#### R

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

**Reading it left to right (R):**
- `function(messages) { ... }` → R function definition.
- The body is Task 10's chain followed by Task 11's drill.
- The **last expression** in an R function is the return value — no explicit `return` needed.

#### Python

```python
def call_openai(messages):
    resp = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        },
        json={"model": "gpt-4o-mini", "messages": messages},
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()["choices"][0]["message"]["content"]
```

**Reading it left to right (Python):**
- `def call_openai(messages):` → function definition.
- Body is Task 10 + Task 11.
- `return ...` → explicit return.

#### C#

```csharp
async Task<string> CallOpenAI(List<Dictionary<string, string>> history)
{
    var body = new { model = "gpt-4o-mini", messages = history };
    string json = JsonSerializer.Serialize(body);
    using var content = new StringContent(json, Encoding.UTF8, "application/json");

    using var resp = await http.PostAsync(
        "https://api.openai.com/v1/chat/completions", content);
    resp.EnsureSuccessStatusCode();

    string raw = await resp.Content.ReadAsStringAsync();
    using var doc = JsonDocument.Parse(raw);
    return doc.RootElement.GetProperty("choices")[0]
              .GetProperty("message")
              .GetProperty("content").GetString() ?? "";
}
```

**Reading it left to right (C#):**
- `async Task<string> CallOpenAI(...)` → async method returning a string.
- Body is Task 10 + Task 11.
- `return ...` → explicit return.

**The story:** Senior engineers don't have API calls scattered across their code; they have **one `call_openai` and 47 callers.** This single function will, over time, grow to handle retries on `429`, exponential backoff, logging, model switching, token counting, and streaming — all without touching the chat loop. **One function = one place to add features.** That principle (in software-architecture jargon: *encapsulation of an external dependency*) is what this task teaches.

**Analogy:** A single vending machine. Feed in coins (the messages list), one chocolate bar comes out (the reply string). Everything else in the program is "load coins" and "eat chocolate."

**Expected output:** function defined; nothing to print until you call it.

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| Define function | `name <- function(args) { ... }` | `def name(args): ...` | `ReturnType Name(args) { ... }` |
| Return value | Last expression (implicit) | `return x` | `return x;` |
| Async | n/a (httr2 is sync) | n/a (requests is sync) | `async Task<T>` + `await` |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| R | Function returns `NULL` | Last expression must produce the value — no stray semicolons |
| Python | `NameError: API_KEY` inside function | API_KEY must be defined at module scope before `def` |
| C# | Compiler error on `await` | Make the function `async Task<T>` |

---

### Task 13 — Read one line of user input

**Purpose:** Prompt the user, read one line, hold it as a string.

**Human-Readable Breakdown:**
> "Hey language, print `You: ` and wait for the user to type a line and press Enter. Return that line as a string."

#### R

```r
user_input <- readline("You: ")
```

**Reading it left to right (R):**
- `readline(prompt)` → blocking stdin read. Returns the line as a character string (no trailing newline).

#### Python

```python
user_input = input("You: ")
```

**Reading it left to right (Python):**
- `input(prompt)` → blocking stdin read. Returns the line as a `str` (no trailing newline).

#### C#

```csharp
Console.Write("You: ");
string userInput = Console.ReadLine() ?? "";
```

**Reading it left to right (C#):**
- `Console.Write("You: ")` → print without newline.
- `Console.ReadLine()` → blocking stdin read. Returns `null` if stdin is closed (e.g. Ctrl+Z).
- `?? ""` → fall back to empty string instead of `null` to keep the loop safe.

**The story:** Reading a line of stdin is the most boring task in the lab, but it's also where a surprising number of beginner bugs hide. R's `readline` only works inside an interactive script or `Rscript`. Python's `input` strips the trailing newline for you. C#'s `Console.ReadLine` returns `null` (not `""`) on stream close — the `?? ""` is the safe pattern. Different defaults, same job.

**Analogy:** A microphone. All three languages just give you whatever the user said, no editing.

**Expected output:** none yet — input is in memory.

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| Read line | `readline("You: ")` | `input("You: ")` | `Console.Write("You: "); Console.ReadLine()` |
| Returns on EOF | empty string `""` | raises `EOFError` | `null` |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| R | `readline` returns instantly with empty | You ran in non-interactive mode without piped input — use `Rscript` |
| Python | `EOFError` on Ctrl+D | Wrap in `try/except EOFError` |
| C# | `NullReferenceException` later | Use `?? ""` immediately on `Console.ReadLine()` |

---

### Task 14 — The `quit` condition

**Purpose:** If the user types `quit` (any case, with or without spaces), exit the loop cleanly.

**Human-Readable Breakdown:**
> "Hey language, lowercase the input and trim its whitespace. If the result is exactly `quit`, print a goodbye and break out of the loop. Otherwise carry on."

#### R

```r
if (tolower(trimws(user_input)) == "quit") {
  cat("Bye.\n")
  break
}
```

**Reading it left to right (R):**
- `trimws(s)` → strip leading/trailing whitespace.
- `tolower(s)` → lowercase.
- `==` → string equality.
- `cat("Bye.\n")` → print with newline.
- `break` → exit the enclosing loop.

#### Python

```python
if user_input.strip().lower() == "quit":
    print("Bye.")
    break
```

**Reading it left to right (Python):**
- `.strip()` → strip whitespace.
- `.lower()` → lowercase.
- `== "quit"` → equality.
- `break` → exit loop.

#### C#

```csharp
if (userInput.Trim().Equals("quit", StringComparison.OrdinalIgnoreCase))
{
    Console.WriteLine("Bye.");
    break;
}
```

**Reading it left to right (C#):**
- `.Trim()` → strip whitespace.
- `.Equals("quit", StringComparison.OrdinalIgnoreCase)` → case-insensitive equality. Cleaner than `.ToLower()` because no extra string allocated.
- `break;` → exit loop.

**The story:** The lowercase-and-trim is non-optional. Without it, `Quit`, `QUIT`, and `quit ` (trailing space) all bypass your exit condition and the user gets stuck. **The bug pattern is "I typed quit and it just stayed in the loop"** — the fix is always one of `tolower`/`lower`/`OrdinalIgnoreCase`. The C# `StringComparison.OrdinalIgnoreCase` is the modern way to compare without allocating a new lowercase string.

**Analogy:** A bouncer who accepts any spelling of "I'm leaving."

**Expected output:** if the user types `quit`, the program prints `Bye.` and exits.

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| Trim | `trimws(s)` | `s.strip()` | `s.Trim()` |
| Lowercase | `tolower(s)` | `s.lower()` | `s.ToLower()` (or use `OrdinalIgnoreCase`) |
| Equality | `==` | `==` | `==` or `.Equals(..., StringComparison.OrdinalIgnoreCase)` |
| Exit loop | `break` | `break` | `break;` |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| Any | `Quit` doesn't exit | Forgot `tolower`/`lower`/case-insensitive compare |
| Any | `quit ` (trailing space) doesn't exit | Forgot `trim`/`strip` |

---

### Task 15 — Append a user message to `messages`

**Purpose:** Add a new entry to the messages stack with `role: "user"` and the user's input as content. This must happen **before** you call `call_openai`.

**Human-Readable Breakdown:**
> "Hey language, append one new entry to the `messages` list — a user-role message with the latest input as content. This is how the model knows what question to answer this turn."

#### R

```r
messages[[length(messages) + 1]] <-
  list(role = "user", content = user_input)
```

**Reading it left to right (R):**
- `length(messages)` → current count.
- `length(messages) + 1` → the next index (R is 1-indexed).
- `messages[[N]] <- list(...)` → assign at that index. R's idiom for "append to a list."

#### Python

```python
messages.append({"role": "user", "content": user_input})
```

**Reading it left to right (Python):**
- `messages.append(x)` → mutate list in place, add `x` to the end.
- `{"role": "user", "content": user_input}` → the message brick from Layer 3.

#### C#

```csharp
messages.Add(new() {
    ["role"] = "user",
    ["content"] = userInput
});
```

**Reading it left to right (C#):**
- `messages.Add(x)` → append to `List<T>`.
- `new() { ... }` → target-typed `new` with dictionary initializer.

**The story:** Most beginner chat bugs are forgetting one of the two appends. **Forget to append the user turn → the model sees an old question repeated.** Forget to append the assistant reply (Task 16) → the model has no memory of what it just said and contradicts itself. The two appends are the entire memory mechanism of the bot.

**Analogy:** A logbook. Every new line of dialogue gets written in before the next call.

**Expected output:** none visible — in-memory mutation.

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| Append | `lst[[length(lst)+1]] <- x` | `lst.append(x)` | `lst.Add(x)` |
| Type of element | named `list(...)` | `dict` | `Dictionary<string, string>` |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| R | "subscript out of bounds" | Use `length(messages) + 1`, not `length(messages)` |
| Any | Bot replies to wrong question | You called `call_openai` *before* appending the user turn |

---

### Task 16 — Append the assistant reply to `messages`

**Purpose:** After `call_openai` returns, add the reply to `messages` with `role: "assistant"`. This is how the bot remembers what it just said.

**Human-Readable Breakdown:**
> "Hey language, take the `reply` string from `call_openai`. Append it to `messages` as an assistant-role entry. **This step is what gives the bot memory across turns.**"

#### R

```r
messages[[length(messages) + 1]] <-
  list(role = "assistant", content = reply)
```

#### Python

```python
messages.append({"role": "assistant", "content": reply})
```

#### C#

```csharp
messages.Add(new() {
    ["role"] = "assistant",
    ["content"] = reply
});
```

**Reading it left to right:** identical to Task 15, only the `role` value and the content variable change.

**The story:** This is the *other half* of the memory mechanism. The system message at index 0 holds the persona. The alternating user/assistant pairs from Task 15 + Task 16 build a growing transcript. Every API call from this point forward will resend the full transcript, so the model sees "here's who I am, here's everything we've said so far, and here's the new question." That's why a stateless API can feel stateful.

**Analogy:** Same logbook as Task 15. This time you write down the receptionist's reply, in addition to the caller's question.

**Switches and Troubleshoot:** identical to Task 15.

---

### Task 17 — Assemble the main loop

**Purpose:** Glue Tasks 13–16 into one infinite loop that runs until the user types `quit`.

**Human-Readable Breakdown:**
> "Hey language, print a banner. Loop forever. Each iteration: (a) read one line of user input, (b) if it's `quit`, say goodbye and break, (c) append it as a user-role message, (d) call `call_openai(messages)` and get a reply string, (e) append the reply as an assistant-role message, (f) print the reply."

#### R (`R/chatbot.R`, full file)

```r
library(httr2)
library(jsonlite)
library(dotenv)

dotenv::load_dot_env("../.env")
api_key <- Sys.getenv("OPENAI_API_KEY")
if (api_key == "") stop("OPENAI_API_KEY missing from .env")

context_path  <- file.path("..", "context.txt")
context_lines <- readLines(context_path, warn = FALSE, encoding = "UTF-8")
context_text  <- paste(context_lines, collapse = "\n")

base_instructions <- "You are a helpful assistant. Follow the persona and rules below exactly."
system_prompt <- paste0(base_instructions, "\n\n---\n", context_text)

messages <- list(
  list(role = "system", content = system_prompt)
)

call_openai <- function(messages) {
  resp <- request("https://api.openai.com/v1/chat/completions") |>
    req_headers(
      Authorization  = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ) |>
    req_body_json(list(model = "gpt-4o-mini", messages = messages)) |>
    req_perform()
  resp_body_json(resp)$choices[[1]]$message$content
}

cat("Bot ready. Type 'quit' to exit.\n")
while (TRUE) {
  user_input <- readline("You: ")
  if (tolower(trimws(user_input)) == "quit") {
    cat("Bye.\n"); break
  }
  messages[[length(messages) + 1]] <- list(role = "user", content = user_input)
  reply <- call_openai(messages)
  messages[[length(messages) + 1]] <- list(role = "assistant", content = reply)
  cat("Bot:", reply, "\n\n")
}
```

#### Python (`python/chatbot.py`, full file)

```python
import os
import requests
from dotenv import load_dotenv

load_dotenv("../.env")
API_KEY = os.getenv("OPENAI_API_KEY")
if not API_KEY:
    raise RuntimeError("OPENAI_API_KEY missing from .env")

CONTEXT_PATH = os.path.join("..", "context.txt")
with open(CONTEXT_PATH, "r", encoding="utf-8") as f:
    context_text = f.read()

base_instructions = "You are a helpful assistant. Follow the persona and rules below exactly."
system_prompt = f"{base_instructions}\n\n---\n{context_text}"

messages = [{"role": "system", "content": system_prompt}]

def call_openai(messages):
    resp = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {API_KEY}",
                 "Content-Type": "application/json"},
        json={"model": "gpt-4o-mini", "messages": messages},
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()["choices"][0]["message"]["content"]

print("Bot ready. Type 'quit' to exit.")
while True:
    user_input = input("You: ")
    if user_input.strip().lower() == "quit":
        print("Bye."); break
    messages.append({"role": "user", "content": user_input})
    reply = call_openai(messages)
    messages.append({"role": "assistant", "content": reply})
    print(f"Bot: {reply}\n")
```

#### C# (`csharp/ContextFromFile/Program.cs`, full file)

```csharp
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using DotNetEnv;

Env.Load("../../.env");
string apiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY")
                ?? throw new InvalidOperationException("OPENAI_API_KEY missing from .env");

string contextPath = Path.Combine("..", "..", "context.txt");
string contextText = File.ReadAllText(contextPath, Encoding.UTF8);

string baseInstructions = "You are a helpful assistant. Follow the persona and rules below exactly.";
string systemPrompt = $"{baseInstructions}\n\n---\n{contextText}";

var messages = new List<Dictionary<string, string>>
{
    new() { ["role"] = "system", ["content"] = systemPrompt }
};

using var http = new HttpClient();
http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

async Task<string> CallOpenAI(List<Dictionary<string, string>> history)
{
    var body = new { model = "gpt-4o-mini", messages = history };
    using var content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/json");
    using var resp = await http.PostAsync("https://api.openai.com/v1/chat/completions", content);
    resp.EnsureSuccessStatusCode();
    string raw = await resp.Content.ReadAsStringAsync();
    using var doc = JsonDocument.Parse(raw);
    return doc.RootElement.GetProperty("choices")[0]
              .GetProperty("message").GetProperty("content").GetString() ?? "";
}

Console.OutputEncoding = Encoding.UTF8;
Console.WriteLine("Bot ready. Type 'quit' to exit.");
while (true)
{
    Console.Write("You: ");
    string userInput = Console.ReadLine() ?? "";
    if (userInput.Trim().Equals("quit", StringComparison.OrdinalIgnoreCase))
    {
        Console.WriteLine("Bye."); break;
    }
    messages.Add(new() { ["role"] = "user", ["content"] = userInput });
    string reply = await CallOpenAI(messages);
    messages.Add(new() { ["role"] = "assistant", ["content"] = reply });
    Console.WriteLine($"Bot: {reply}\n");
}
```

**The story:** Read all three full files side by side. **They are the same program, three times.** Library imports → load `.env` → read context → build system prompt → seed messages → define `call_openai` → print banner → loop (read → quit-check → append user → call → append assistant → print). **Every line in R has a twin in Python and a cousin in C#.** This is the compounding payoff: by the time you've typed R, Python is half-written in your head, and C# is just "Python with semicolons."

**Analogy:** Three productions of the same play. Same script, three casts.

**Expected output (any language):**

```
Bot ready. Type 'quit' to exit.
You: will I get the job?
Bot: A door that creaks loudest is the one that opens widest, yet the threshold demands one more knock. The stars remain silent on further details.

You: quit
Bye.
```

**Switches:** see the trilingual reference table at the top — every concept in the loop is one row.

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| R | Bot has no memory | One of the two `messages[[length(messages)+1]] <-` lines was skipped |
| Python | Same | One of the two `messages.append(...)` lines was skipped |
| C# | Same | One of the two `messages.Add(...)` lines was skipped |
| Any | Bot answers a stale question | You called `call_openai` *before* appending the user turn |

---

### Task 18 — Run all three end-to-end

**Purpose:** Confirm all three bots talk to the same `context.txt` and produce the persona's voice.

**Human-Readable Breakdown:**
> "Hey shell, run each of the three programs from its language folder. Type the same question to all three. Confirm the reply persona is identical — because they're reading the same `context.txt`."

#### R

```powershell
cd R
Rscript chatbot.R
```

#### Python

```powershell
cd python
.\.venv\Scripts\Activate.ps1
python chatbot.py
```

#### C#

```powershell
cd csharp\ContextFromFile
dotnet run
```

**Reading it left to right:**
- **R**: `cd R` is **critical** — the script's `..` paths only work if your cwd is `R/`. Then `Rscript` runs the file.
- **Python**: `cd python`, re-activate the venv (in case you opened a new terminal), then `python chatbot.py`.
- **C#**: `cd csharp\ContextFromFile`, then `dotnet run` builds and executes from `bin/Debug/net8.0/` — which is why your `..` paths in code were `../../`.

**The story:** Each language has its own "where am I running from" gotcha. R/Python expect cwd = language folder, so `..` = repo root. C# runs from a build output folder two levels deeper, so `..` = project folder and `../..` = repo root. **Print your cwd at the top of each script the first time you run it** to verify before debugging path errors.

**Analogy:** Three actors stepping onto three stages. They all use the same script (`context.txt`) but enter from different doors (each language's cwd).

**Expected output:** identical persona-voiced replies in all three.

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| R | `cannot open file '../context.txt'` | You didn't `cd R` first |
| Python | `FileNotFoundError` | You didn't `cd python` first |
| C# | `DirectoryNotFoundException` | Path count wrong — verify with `Console.WriteLine(Directory.GetCurrentDirectory());` at the top |

---

### Task 19 — Swap `context.txt` to change behavior, recompile nothing (universal)

**Purpose:** This is the whole lab in one act. Prove the bot is data-driven.

Edit `context.txt` to a completely new persona, save, re-run **any** of the three programs. No code change.

`context.txt`:

```text
You are a sarcastic 1940s detective narrating an internal monologue.
Every reply starts with "The dame asked me..." and ends with "...and that was that."
Keep it under 60 words. Never break character.
```

Then re-run:

```powershell
cd ..\R         ;  Rscript chatbot.R
cd ..\python    ;  python chatbot.py
cd ..\csharp\ContextFromFile  ;  dotnet run
```

**Human-Readable Breakdown:**
> "Hey lab, watch this. I'm deleting the fortune teller persona and pasting in a 1940s detective persona. I'll save `context.txt`. I'll re-run the **exact same** R script, then the **exact same** Python script, then the **exact same** C# program. All three switch personality. **Zero lines of code changed.**"

**The story:** This task is the *aha* of the whole project. You edited one text file and turned a fortune teller into a film-noir detective **in three programming languages simultaneously.** That is the power of separating data from code. The next product you build — internal Q&A bot, support agent, study buddy — starts as a single `context.txt` and grows from there. Add more files. Add a retriever. Add tool calls. The skeleton never changes; the data grows.

**Analogy:** Same actor (the model), same theater (the script code), new script pages (`context.txt`). New play, same theater.

**Expected output:**

```
You: what happened on tuesday?
Bot: The dame asked me what happened on tuesday, and I told her some questions are like cheap whiskey - they burn going down and leave you sleeping in your overcoat...and that was that.
```

**Troubleshoot**

| Symptom | Fix |
|---|---|
| Bot still uses old persona | Old process is still running with the old text cached — restart it |
| Persona only half-applies | The persona is contradictory; tighten the rules in `context.txt` |

---

### Task 20 — Interview scenario: load context from a CLI argument

**Task statement:** *"Modify your chatbot so the context file path is a CLI argument, not hardcoded. If no argument is provided, fall back to `../context.txt`. Demonstrate by running the same script with two different context files in the same terminal — in all three languages."*

**Human-Readable Breakdown:**
> "Hey language, look at the CLI arguments. If the user passed a path, use it. Otherwise fall back to `../context.txt`. Re-run with two different files (`personas/fortune.txt` and `personas/detective.txt`) and watch the personality change without editing code."

#### R

```r
args <- commandArgs(trailingOnly = TRUE)
context_path <- if (length(args) >= 1) args[[1]] else file.path("..", "context.txt")
```

**Reading it left to right (R):**
- `commandArgs(trailingOnly = TRUE)` → CLI args *without* the leading interpreter args.
- `if (...) X else Y` → R's expression-style if.
- `args[[1]]` → first arg (R is 1-indexed; use `[[ ]]` to extract).

#### Python

```python
import sys
context_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join("..", "context.txt")
```

**Reading it left to right (Python):**
- `sys.argv` → list of CLI args; `sys.argv[0]` is the script name, `[1]` is the first real arg.
- `X if cond else Y` → ternary expression.
- Guard with `len(sys.argv) > 1` to avoid `IndexError`.

#### C#

```csharp
string contextPath = args.Length > 0
    ? args[0]
    : Path.Combine("..", "..", "context.txt");
```

**Reading it left to right (C#):**
- `args` → top-level program `string[] args` parameter, available automatically.
- `cond ? X : Y` → ternary.
- `args.Length > 0` → guard against empty.

#### Run it (all three)

```powershell
Rscript chatbot.R ..\personas\fortune.txt
Rscript chatbot.R ..\personas\detective.txt

python chatbot.py ..\personas\fortune.txt
python chatbot.py ..\personas\detective.txt

dotnet run -- ..\..\personas\fortune.txt
dotnet run -- ..\..\personas\detective.txt
```

> The `--` before the C# argument is the `dotnet run` separator that says "everything after this goes to my program, not to the build tool."

**The story:** Every interview asks some variant of *"how would you make this configurable?"* The progression is always: hardcoded → file-loaded → CLI-loaded → env-var-loaded → config-file-loaded → remote-config-loaded. **This task is rung 3.** Once you have it in all three languages, you can argue your way through every rung above and below. The hidden lesson: every step in that ladder is the same idea — *push the value further from the source code, closer to the operator.* `context.txt` is one step. CLI args are the next. RAG retrieval is the rung where the value doesn't even exist until runtime.

**Analogy:** A record player. The code is the turntable. `context.txt` is the album. The CLI argument is the *album number* — slot in any record from your shelf, the turntable doesn't care.

**Expected output:** the bot's persona changes between runs without recompiling.

**Switches**

| Concept | R | Python | C# |
|---|---|---|---|
| CLI args | `commandArgs(trailingOnly = TRUE)` | `sys.argv[1:]` | `string[] args` (top-level) |
| First arg | `args[[1]]` | `sys.argv[1]` | `args[0]` |
| Indexing base | 1-indexed | 0-indexed | 0-indexed |
| Ternary | `if (cond) X else Y` | `X if cond else Y` | `cond ? X : Y` |

**Troubleshoot**

| Language | Symptom | Fix |
|---|---|---|
| R | Picks default even with an arg | You wrote `args[0]` (R is 1-indexed) — use `args[[1]]` |
| Python | `IndexError` | Missing `len(sys.argv) > 1` guard |
| C# | Args empty in Visual Studio | Set "Command line arguments" in the launch profile |
| C# | Args go to `dotnet`, not your program | You forgot the `--` separator before your args |

---

## Context-Loading Decision Guide

```
Got a "bot ignores my context.txt" problem?
  |
  +-- Did the file actually load?
  |     -> Print nchar/len/Length. Zero means path wrong or wrong cwd.
  |
  +-- Is the path resolved from the right cwd?
  |     -> R/Python: cd into the language folder before running.
  |     -> C#: cwd is bin/Debug/net8.0; count the `..` from there.
  |
  +-- Did UTF-8 decode correctly?
  |     -> Accented chars / emojis show as ? -> add encoding="UTF-8".
  |
  +-- Is context in the SYSTEM role?
  |     -> If it's in `user`, the model treats it as a 4000-word question.
  |
  +-- Is the system prompt sent on EVERY call?
  |     -> Yes if it's messages[0] and you re-send messages each turn.
  |
  +-- Does the context contain contradictions?
        -> Models obey concrete rules > vague rules. Tighten the prompt.
```

---

## Lab Checklist (20 Tasks, All Three Languages Per Task)

- [ ] 01 Build the repo skeleton
- [ ] 02 Write `.gitignore` with `.env` in it
- [ ] 03 Put `OPENAI_API_KEY` in `.env`
- [ ] 04 Write your first `context.txt`
- [ ] 05 Install dependencies (R: 3 packages, Python: 2, C#: 1)
- [ ] 06 Load `.env` and pull `OPENAI_API_KEY` (R, Python, C#)
- [ ] 07 Read `context.txt` as UTF-8 (R, Python, C#)
- [ ] 08 Build `system_prompt` by injecting context (R, Python, C#)
- [ ] 09 Seed `messages` with the system role (R, Python, C#)
- [ ] 10 Send the POST request (R, Python, C#)
- [ ] 11 Parse the JSON response and extract `content` (R, Python, C#)
- [ ] 12 Wrap it in `call_openai(messages)` (R, Python, C#)
- [ ] 13 Read one line of user input (R, Python, C#)
- [ ] 14 The quit condition (R, Python, C#)
- [ ] 15 Append a user message (R, Python, C#)
- [ ] 16 Append the assistant reply (R, Python, C#)
- [ ] 17 Assemble the main loop (R, Python, C#)
- [ ] 18 Run all three end-to-end
- [ ] 19 Swap `context.txt` to change behavior (all three at once)
- [ ] 20 Load context from a CLI arg (R, Python, C#)

---

## Common Pitfalls (across all three languages)

| Mistake | Symptom | Fix |
|---|---|---|
| Context loaded in `user` role | Bot answers the file as a question | Move to `role: "system"` |
| Forgot UTF-8 encoding flag | `?` boxes or mojibake | Pass `UTF-8` / `utf-8` / `Encoding.UTF8` explicitly |
| Hardcoded API key | Key leaks on first push | Move to `.env`, add to `.gitignore` |
| Ran from wrong cwd | `cannot open file '../context.txt'` | `cd R` / `cd python` / be aware of `bin/Debug/net8.0/` for C# |
| `.env` not at repo root | API key reads empty/None/null | Move `.env` next to `context.txt` |
| Forgot to append user turn | Bot replies to wrong question | Append *before* the API call |
| Forgot to append assistant turn | Bot has no memory | Append *after* the API call |
| R `[1]` instead of `[[1]]` | Prints `list(...)` instead of text | Use `[[1]]` to extract from a list |
| No timeout in HTTP call | Script hangs forever on bad network | Pass `timeout=60` / `req_timeout(60)` / `http.Timeout` |
| C# path counted from project folder | `DirectoryNotFoundException` | C# cwd is `bin/Debug/net8.0/`; count `..` from there |
| Edited `context.txt` mid-session | Old persona persists | Restart the script (file is read once at startup) |

---

## Career & Interview Strategy

**Self-learner**
- Finish all 20 tasks in R first, then Python, then C#? **No** — do each task in all three languages before moving to the next task. That's the compounding trick.

**Portfolio / GitHub**
- Pin this repo. Add a 30-second screen recording of swapping `context.txt` and watching three different bots (R, Python, C#) change personality at the same time. Hiring managers love it because it shows the data/code split *and* trilingual ability in one clip.

**AI Engineer interview**
- Practice saying out loud: *"The context belongs in the system role because it's a standing instruction, not a turn. The whole history goes on every call because the API is stateless. UTF-8 because Windows defaults to cp1252."* Three sentences, one job offer.

**RAG-system engineer (next stop)**
- The exact `call_openai(messages)` function you wrote here is the function a RAG system calls *after* the retriever returns chunks. Add one line — `system_prompt += retrieved_chunks` — and you have a primitive RAG bot. That's Project 5 and beyond.

**Prompt engineer**
- Version `context.txt` files in git. Tag releases. Diff personas across versions. You are now a prompt engineer with a workflow, not a person editing strings in source files.

---

## Related Projects

| Project | Connection |
|---|---|
| [`Hello_LLM`](https://github.com/kelvintechnical/Hello_LLM) | One-shot call — simplest possible version |
| [`Persona_Bot`](https://github.com/kelvintechnical/Persona_Bot) | Persona introduced, still in code |
| [`Chatbot_with_memory`](https://github.com/kelvintechnical/Chatbot_with_memory) | Memory introduced via `messages` history |
| **This lab (`ContextFromFile`)** | Persona externalized to `.txt` |
| [`PDF_Reader_Bot`](https://github.com/kelvintechnical/PDFReaderBot) | Same pattern, PDF reader instead of plain text |
| Later in the series | Multi-doc concatenation, top-K retrieval, full RAG |

---

## Why This Lab Is the Hardest One in the First Five

The first three projects only asked you to type code in **one** language. This project asks for **three** languages, **one** shared data file, **two** new concepts (UTF-8 file I/O and prompt injection), and **one** uncomfortable mental shift (data is not code).

If you quit the first time, you quit because the lab is genuinely 3× the surface area of the previous ones. The fix is **not** "try harder." The fix is **complete each task in all three languages before moving to the next task.** That way Python feels familiar by Task 6 (you just wrote R for it), and C# feels familiar by Task 10 (you just wrote two other versions). The trilingual payoff kicks in around Task 8 — you'll feel it.

---

## Author

**Kelvin R. Tobias**
[kelvinintech.com](https://kelvinintech.com) · [GitHub](https://github.com/kelvintechnical) · [LinkedIn](https://www.linkedin.com/in/kelvin-r-tobias-211949219)

Part of the compounding trilingual learning series: **build once, learn three times.**

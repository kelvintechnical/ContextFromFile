Read this **before** writing code for any project in this series.

---

## The Series Project List

- **Project 1 — Hello, LLM** — https://github.com/kelvintechnical/Hello_LLM  
  Authenticate, POST to OpenAI, parse JSON response. One hardcoded message.
- **Project 2 — Persona Bot (single turn)** — https://github.com/kelvintechnical/Persona_Bot  
  Add a system prompt that shapes model behavior. One user input, one response.
- **Project 3 — Chatbot with Memory** — https://github.com/kelvintechnical/Chatbot_with_memory  
  Add a loop. Append user message, get response, append assistant response. Messages list grows each turn.
- **Project 4 — Context from a File** — Inject `.txt` content into system_prompt. https://github.com/kelvintechnical/ContextFromFile

- **Project 5 — PDF Reader Bot** — Replace `.txt` with PDF parsing. https://github.com/kelvintechnical/PDFReaderBot

- **Project 6 — Add a Gradio UI** — Wrap chatbot in Gradio.
- **Project 7 — Your First Tool** — Single JSON tool schema + tool_calls.
- **Project 8 — Multi-Tool IF Router** — Two tools + handle_tool_calls().
- **Project 9 — Elegant Tool Router** — Refactor with globals().get().
- **Project 10 — Pushover + Lead Capture Bot**
- **Project 11 — The While Loop (no tools)**
- **Project 12 — Loop + One Action Tool**
- **Project 13 — Multi-step Task Agent**
- **Project 14 — Agent + Gradio UI**
- **Project 15 — Deploy to HuggingFace Spaces**

---

## Series Rules (Non-Negotiable)

1. Every project is a **complete rewrite from scratch**. Do not extend or copy the previous project.
2. Every project must include **ALL** skills from every previous project, retyped in full in all three languages.
3. **New skills** are always added at the **bottom** of each file, after all previously learned skills.
4. Every project README must include a **cross-language equivalency table** for every concept used so far.
5. Every new concept needs an inline comment explaining **what it does and why**.
6. **Variable names** (consistent across languages, C# uses idiomatic casing):
   - **Python/R:** `api_key`, `base_url`, `system_prompt`, `messages`, `call_openai()`
   - **C#:** `apiKey`, `baseUrl`, `systemPrompt`, `messages`, `CallOpenAI()`
7. README must end with **Skills Repeated** + **New Skill Introduced** sections.

---

## Master Skill Inventory (Projects 1–4)

This is the complete list of skills that must be retyped in every project from Project 4 onward.

### Project 1 — Hello, LLM (Skills 1–4)

| # | Skill | Python | R | C# |
|---|-------|--------|---|-----|
| 1 | Load API key from environment | `os.getenv("OPENAI_API_KEY")` after `load_dotenv(override=True)` | `Sys.getenv("OPENAI_API_KEY")` after `load_dot_env()` | `config["OPENAI_API_KEY"]?.Trim()` from user-secrets |
| 2 | Define base URL / endpoint | `base_url = "https://api.openai.com/v1/chat/completions"` | `base_url <- "https://..."` | `string baseUrl = "https://...";` |
| 3 | Build HTTP POST with JSON payload | `requests.post(url, headers=..., json=payload)` | `request(url) \|> req_headers() \|> req_body_json() \|> req_perform()` | `client.PostAsync(url, content)` async |
| 4 | Parse JSON response, extract assistant text | `response.json()["choices"][0]["message"]["content"]` | `resp_body_json(response)$choices[[1]]$message$content` | `JsonSerializer.Deserialize<JsonElement>(text).GetProperty("choices")[0]...` |

### Project 2 — Persona Bot (Skills 5–7)

| # | Skill | Python | R | C# |
|---|-------|--------|---|-----|
| 5 | Define system_prompt string | `system_prompt = "You are..."` | `system_prompt <- "You are..."` | `string systemPrompt = "You are...";` |
| 6 | Seed messages list with system role | `messages = [{"role": "system", "content": system_prompt}]` | `messages <- list(list(role = "system", content = system_prompt))` | `var messages = new List<Dictionary<string, string>> { ... }` |
| 7 | Single-turn user message + response | `messages.append({"role": "user", ...})` once | `append(messages, list(...))` once | `messages.Add(new Dictionary<string, string> { ... })` once |

### Project 3 — Chatbot with Memory (Skills 8–11)

| # | Skill | Python | R | C# |
|---|-------|--------|---|-----|
| 8 | Build infinite conversation loop with exit condition | `while True: ... if user_input.lower() == "quit": break` | `repeat { ... if (tolower(user_input) == "quit") break }` | `while (true) { ... if (userInput.ToLower() == "quit") break; }` |
| 9 | Read user input from stdin | `input("\nYou: ")` | `readLines(con="stdin", n=1)` | `Console.ReadLine()` |
| 10 | Append user message to messages BEFORE API call | `messages.append({"role": "user", "content": user_input})` | `messages <- append(messages, list(list(role = "user", content = user_input)))` | `messages.Add(new Dictionary<string, string> { { "role", "user" }, { "content", userInput } })` |
| 11 | Append assistant reply to messages AFTER API call | `messages.append({"role": "assistant", "content": response})` | `messages <- append(messages, list(list(role = "assistant", content = response)))` | `messages.Add(new Dictionary<string, string> { { "role", "assistant" }, { "content", response } })` |

### Project 4 — Context from a File (Skills 12–13)



| # | Skill | Python | R | C# |
|---|-------|--------|---|-----|
| 12 | Read `context.txt` from disk with UTF-8 + safe path into `context_text` | `context_path = Path("..") / "context.txt"; context_text = context_path.read_text(encoding="utf-8")` | `context_path <- file.path("..","context.txt"); context_text <- readLines(context_path, warn=FALSE, encoding="UTF-8") \|> paste(collapse="\n")` | `var contextPath = Path.Combine("..","context.txt"); string contextText = File.ReadAllText(contextPath, Encoding.UTF8);` |
| 13 | Inject file contents into `system_prompt` BEFORE seeding `messages` (backup base first) | `base_system_prompt = system_prompt; system_prompt = base_system_prompt + "\n\n" + context_text; messages = [{"role":"system","content":system_prompt}]` | `base_system_prompt <- system_prompt; system_prompt <- paste0(base_system_prompt, "\n\n", context_text); messages <- list(list(role="system", content=system_prompt))` | `string baseSystemPrompt = systemPrompt; systemPrompt = baseSystemPrompt + "\n\n" + contextText; var messages = new List<Dictionary<string,string>> { new() { ["role"] = "system", ["content"] = systemPrompt } };` |
---

## Sequential Step Rebuild Workflow

When starting any project from Project 4 onward, walk through ALL prior steps before introducing the new step. **Example for Project 4:**

**Rule:** The Project N step table must include **every skill** in the Master Skill Inventory up to Project N, in numeric order. New Project N skills are appended at the bottom using the **next available** step numbers.

| Step # | Task | Project Origin | Status |
|--------|------|----------------|--------|
| 1 | Load API key from environment | Project 1 | Reuse |
| 2 | Define base_url and headers | Project 1 | Reuse |
| 3 | Build HTTP POST with JSON payload | Project 1 | Reuse |
| 4 | Parse JSON response, extract assistant text | Project 1 | Reuse |
| 5 | Define system_prompt string | Project 2 | Reuse |
| 6 | Seed messages list with system role | Project 2 | Reuse |
| 7 | Single-turn user message + response | Project 2 | Reuse |
| 8 | Build infinite conversation loop with exit condition | Project 3 | Reuse |
| 9 | Read user input from stdin | Project 3 | Reuse |
| 10 | Append user message to messages BEFORE API call | Project 3 | Reuse |
| 11 | Append assistant reply to messages AFTER API call | Project 3 | Reuse |
| 12 | Read context.txt from disk with UTF-8 + safe path | **Project 4 — NEW** | New |
| 13 | Inject file contents into system_prompt BEFORE seeding messages | **Project 4 — NEW** | New |

By **Project 15**, the table will have **~40+ steps** spanning every project.

---

## Teaching Flow — Interactive, One Language at a Time

At the start of every project, the assistant must:

1. **Ask which language to start in** (R, Python, or C#) before writing any code.
2. **Show the full step table** so the learner sees what's being reused vs. new.
3. **Walk through Step 1 → Step N sequentially** in the chosen language.
4. **Stop and wait** between every step.
5. After the learner says "next step," reveal the next step's code only.
6. After all steps in language 1 are complete, learner says "next language."
7. Repeat in language 2, then language 3.

### Step Response Format

Every step response must contain:

1. **Step heading:** `Step X: [Description] (Project Y origin)`
2. **CONCEPT block:**
   =========================================
   CONCEPT: [High-level mental model]
   =========================================
   [What this does in 2–4 bullets]
3. **Code block** using the 4-comment pattern (see below):
   - `# TASK:` — plain English, no function names. Forces recall.
   - `# SYNTAX:` — explains the exact syntax used and why.
   - The actual line of code.
   - `# PYTHON:` — equivalent line as a comment.
   - `# C#:` — equivalent line as a comment.
4. **Verification:** How to test it works (1 line).
5. **STOP.** Wait for "next step".

### Comment Pattern (Mandatory for Every Code Line)

Every line of code in every step must follow this 4-comment pattern. The TASK comment lets the learner attempt the syntax themselves before reading the answer.

**Template:**

```<lang>
# TASK: [What needs to happen, in plain English. No function names.]
# SYNTAX: [Why this exact syntax/function/operator is used.]
<actual code line>
# PYTHON: <equivalent Python line>                       # any imports needed
# C#:     <equivalent C# line>                           // any usings needed
```

**Worked example (Step 1 — R):**

```r
# --- Step 1: Load API key from environment (Project 1) ---

# TASK: Load environment variables from a .env file located one directory up from the project root.
# SYNTAX: Call load_dot_env() with the `file =` argument. file.path("..", ".env") builds an OS-safe relative path.
load_dot_env(file = file.path("..", ".env"))
# PYTHON: load_dotenv(dotenv_path="../.env")             # from dotenv import load_dotenv
# C#:     Env.Load("../.env");                           // using DotNetEnv;

# TASK: Pull the OpenAI API key out of the environment and store it for use in request headers.
# SYNTAX: Sys.getenv("VAR_NAME") returns the value as a string (or "" if missing). Assign with `<-`.
api_key <- Sys.getenv("OPENAI_API_KEY")
# PYTHON: api_key = os.getenv("OPENAI_API_KEY")          # import os; returns None if missing
# C#:     string apiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY"); // returns null if missing
```

**Cross-language gotcha line** (include at the end of any step where it applies):

> Missing-var return: R → `""` · Python → `None` · C# → `null`

**Rules:**
- The `# PYTHON:` and `# C#:` comments appear in **every** language's code block, not just R. (When teaching Python, the equivalents become `# R:` and `# C#:`.)
- TASK comments must be **language-agnostic** — they describe intent, not syntax.
- If a concept has a non-obvious failure mode, add a 5th line: `# GOTCHA: ...`

**Worked example (Step 13 — R, inject context + reseed messages):**

```r
# --- Step 13: Inject file contents into system_prompt BEFORE seeding messages (Project 4) ---

# TASK: Save a copy of the original instructions before adding file context.
# SYNTAX: Use `<-` to assign the current string into a new variable name.
base_system_prompt <- system_prompt
# PYTHON: base_system_prompt = system_prompt
# C#:     string baseSystemPrompt = systemPrompt;

# TASK: Create a new system prompt by adding the context file text underneath the original instructions.
# SYNTAX: paste0() concatenates strings with no separator; "\n\n" inserts a blank line for readability.
system_prompt <- paste0(base_system_prompt, "\n\n", context_text)
# PYTHON: system_prompt = base_system_prompt + "\n\n" + context_text
# C#:     systemPrompt = baseSystemPrompt + "\n\n" + contextText;

# TASK: Start the chat history with exactly one system message containing the final system prompt.
# SYNTAX: list(list(...)) creates an outer list holding one inner list with role+content fields.
messages <- list(list(role = "system", content = system_prompt))
# PYTHON: messages = [{"role": "system", "content": system_prompt}]
# C#:     var messages = new List<Dictionary<string,string>> { new() { ["role"]="system", ["content"]=systemPrompt } };
```

### Trigger Phrases

- **"start with [language]"** — pick which language to begin
- **"next step"** — move to next step in same language
- **"next language"** — switch to next language, restart at Step 1
- **"redo step X"** — repeat a step (debugging)
- **"all three at once"** — show R, Python, C# side-by-side for current step

---

## Repository Structure (Every Project)
ProjectName/
├── R/
│   └── chatbot.R
├── Python/
│   ├── chatbot.py
│   └── requirements.txt
├── CSharp/
│   ├── CSharp.csproj
│   └── Program.cs
├── .env.example
├── .gitignore
└── README.md

---

## Terminal Setup — Start of Every Project

### Python — verify version and initialize

```powershell
python --version                        # must be 3.10+
cd Python
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### R — verify version and install packages

```powershell
Rscript --version                       # must be 4.x+
cd R
Rscript -e "install.packages(c('httr2','jsonlite','dotenv'), repos='https://cloud.r-project.org')"
```

### C# — verify version and initialize

```powershell
dotnet --version                        # must be 10.x
cd CSharp
dotnet new console --framework net10.0
dotnet add package Microsoft.Extensions.Configuration.UserSecrets
dotnet user-secrets init
dotnet user-secrets set "OPENAI_API_KEY" "your-key-here"
```

---

## README Template (Every Project)

Every project README must follow this structure:

```markdown
# Project N — [Name]

[1-2 sentence description]

## What This Project Does
- Bullet points describing functionality

## Repo Structure
[folder tree]

## Setup
[Setup commands for all three languages]

## Cross-Language Equivalency Table

[The full table from Master Skill Inventory, plus new skills from this project]

## Skills Repeated from Previous Projects

**Python:**
- Load API key from environment (Project 1)
- Define base URL and headers (Project 1)
- Build HTTP POST with JSON payload (Project 1)
- Parse JSON response (Project 1)
- Define system_prompt (Project 2)
- Seed messages with system role (Project 2)
- Build conversation loop with exit condition (Project 3)
- Read user input from stdin (Project 3)
- Append user message before API call (Project 3)
- Append assistant reply after API call (Project 3)

**R:**
- [Same skills, R syntax]

**C#:**
- [Same skills, C# syntax]

## New Skill Introduced (Project N)

**Python:**
- [New skill in Python]

**R:**
- [New skill in R]

**C#:**
- [New skill in C#]
```

---

## Critical Reminders

1. **No skipping prior steps.** Every project retypes Steps 1–N before adding new steps.
2. **No copying code.** Learner manually types every line.
3. **One step at a time.** No previewing the next step.
4. **Verify each step.** Don't move on until learner confirms it works.
5. **One language at a time.** Default order R → Python → C# unless overridden.
6. **CONCEPT comment block on every step.** Mental model first, then code.
7. **Every code line uses the 4-comment pattern:** TASK → SYNTAX → code → PYTHON equivalent → C# equivalent (rotated based on current language). No exceptions.
# Repeatable prompt — trilingual series (R, Python, C#)

Read this **before** writing code for any project in this series (Project 1 through Project 15).

---

## The full project list

- **Project 1 — Hello, LLM** — https://github.com/kelvintechnical/Hello_LLM  
  Authenticate, POST to OpenAI, parse JSON response. One hardcoded message.
- **Project 2 — Persona Bot (single turn)** — https://github.com/kelvintechnical/Persona_Bot  
  Add a system prompt that shapes model behavior. One user input, one response.
- **Project 3 — Chatbot with Memory** — https://github.com/kelvintechnical/Chatbot_with_memory  
  Add a loop. Append user message, get response, append assistant response. Messages list grows each turn.
- **Project 4 — Context from a File** — (this repo)  
  Read a `.txt` file and inject its contents into the system prompt.
- **Project 5 — PDF Reader Bot** — Replace the `.txt` file with a PDF using a PDF parsing library.
- **Project 6 — Add a Gradio UI** — Wrap the memory chatbot in `gr.ChatInterface` and launch locally.
- **Project 7 — Your First Tool (one function)** — Define a single JSON tool schema and handle the `tool_calls` branch.
- **Project 8 — Multi-Tool IF Router** — Add a second tool and build `handle_tool_calls()` with if/elif.
- **Project 9 — Elegant Tool Router (no IF)** — Refactor using `globals().get(tool_name)`.
- **Project 10 — Pushover + Lead Capture Bot** — Wire up Pushover and add `record_user_details` and `record_unknown_question` as tools.
- **Project 11 — The While Loop (no tools)** — Build the `while not done` loop as a standalone `loop()` function.
- **Project 12 — Loop + One Action Tool** — Add one tool back into the loop and give the agent a real task.
- **Project 13 — Multi-step Task Agent** — Give the agent a multi-step problem using `create_todos` and `mark_complete`.
- **Project 14 — Agent + Gradio UI** — Combine the agentic loop with the Gradio interface.
- **Project 15 — Deploy to HuggingFace Spaces** — Run `gradio deploy` and get a live URL.

---

## Series rules (non-negotiable)

1. Every project is a **complete rewrite from scratch**. Do not extend or copy the previous project.
2. Every project must include **ALL** skills from every previous project, written out **in full** in all three languages. Nothing summarized or replaced with “same as before.”
3. **New skills** are always added at the **bottom** of each file, after all previously learned skills.
4. Every project **README** must include a **cross-language equivalency table** for every concept used so far (template row examples):

| Concept | Python | R | C# |
| ------- | ------ | - | -- |
| Import library | `import requests` | `library(httr2)` | `using System.Net.Http;` |
| Read env var | `os.getenv()` | `Sys.getenv()` | `config["KEY"]` |

The table **grows** as the series progresses; by Project 15 it is a full reference card.

5. Every **new** concept needs an inline comment explaining **what it does and why**, not only syntax.
6. **Variable names** (same idea across languages; C# uses idiomatic casing):

   - **Python:** `api_key`, `base_url`, `system_prompt`, `messages`, `call_openai()`
   - **R:** `api_key`, `base_url`, `system_prompt`, `messages`, `call_openai()`
   - **C#:** `apiKey`, `baseUrl`, `systemPrompt`, `messages`, `CallOpenAI()`

7. The README must **end** with two clearly labeled sections:

   - **Skills repeated from previous projects** — bullet list, all three languages  
   - **New skill introduced this project** — bullet list, all three languages  

(Additional README notes such as “What this unlocks” come **after** those two sections when specified for a project.)

---

## Terminal setup — start of every project

Use this folder layout:

```text
Project_4_Context_from_File/
├── R/
│   └── chatbot.R
├── Python/
│   ├── chatbot.py
│   └── requirements.txt
├── CSharp/
│   ├── CSharp.csproj
│   └── Program.cs
├── context.txt
├── .env.example
├── .gitignore
└── README.md
```

### Python — verify version and initialize

```powershell
python --version                        # must be 3.10+
cd Python
python -m venv .venv
.venv\Scripts\Activate.ps1
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
dotnet new console -n CSharp --framework net10.0
dotnet add package Microsoft.Extensions.Configuration.UserSecrets
dotnet user-secrets init
dotnet user-secrets set "OPENAI_API_KEY" "your-key-here"
```

*(If the repo already contains `CSharp.csproj`, use `dotnet restore` / `dotnet run` from `CSharp/` instead of `dotnet new`.)*

---

## Project 4 brief (Context from a File)

Read a `.txt` file from disk and inject it into `system_prompt` **before** seeding `messages`. Memory loop, API call, and exit condition match Project 3 in behavior but are **rewritten from scratch** here.

### Skills to repeat (Projects 1–3)

**Project 1 — Hello LLM:** load API key; HTTP POST with headers + JSON; parse JSON for assistant text.  
**Project 2 — Persona Bot:** system persona string; seed `messages` with system role; loop + exit.  
**Project 3 — Chatbot with Memory:** append user message; send full history each call; append assistant reply.

### New skills (Project 4)

- File I/O: Python `open(..., encoding="utf-8")`; R `paste(readLines(file.path(...), ...), collapse="\n")` with UTF-8; C# `File.ReadAllText(..., Encoding.UTF8)`
- Path handling: Python `pathlib.Path`; R `file.path()`; C# `Path.Combine` / `AppContext.BaseDirectory`
- String injection into `system_prompt` before seeding `messages`
- Comment: **why** context belongs in the **system** role, not the user role
- Separation of concerns: external `.txt` changes behavior without editing source

### Format checklist

- Terminal setup first in assistant responses; README mirrors it at the top
- Order in prose/docs: **R**, then **Python**, then **C#** when describing implementations
- UTF-8 Windows gotcha in all three languages
- Sample `context.txt`
- README equivalency table for Projects **1–4**
- README ends with **Skills repeated** and **New skill introduced**; Project 4 also adds **What this unlocks** (RAG) after those sections

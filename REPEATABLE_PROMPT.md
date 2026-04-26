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
2. Every project must include **ALL** skills from every previous project, written out **in full** in all three languages. Nothing summarized or replaced with "same as before."
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

(Additional README notes such as "What this unlocks" come **after** those two sections when specified for a project.)

---

## Teaching flow — interactive, one language at a time

At the start of every project, the assistant must:

1. **Ask which language to start in** (R, Python, or C#) before writing any code.
2. After I pick, **execute the full setup for that language only**, in this exact order:
   - Verify language version (`python --version`, `Rscript --version`, `dotnet --version`)
   - Create the project subfolder (`R/`, `Python/`, or `CSharp/`)
   - Initialize the file or project (e.g., `dotnet new console`, `python -m venv`, R script file)
   - Install dependencies for that language only
   - Walk me through **ALL prior project steps in order**, then end with **the current project's new step(s)**
3. **Stop and wait** between every step. Do not preemptively write the next step or jump to another language.
4. After I confirm a step works, I will say "next step" or "next language."
5. After all steps are complete in language 1, I will say "next language."
6. Repeat the same flow in language 2, then language 3.

### Sequential step rebuild — every project includes every prior project's steps

Every project starts at **Step 1 from Project 1** and walks forward, retyping every step from every prior project, before reaching the new step that defines the current project. **No skipping. No "same as Project 3 — see prior repo."**

#### What "all prior steps" means per project

For **Project 4 (Context from a File)**, the step sequence in each language is:

- **Step 1** — Load API key from environment (Project 1)
- **Step 2** — Define `base_url` and headers (Project 1)
- **Step 3** — Build HTTP POST with JSON payload (Project 1)
- **Step 4** — Parse JSON response, extract assistant text (Project 1)
- **Step 5** — Define `system_prompt` string (Project 2)
- **Step 6** — Seed `messages` list with system role (Project 2)
- **Step 7** — Build infinite conversation loop with exit condition (Project 2)
- **Step 8** — Append user message to `messages` before API call (Project 3)
- **Step 9** — Pass full `messages` history to API on every call (Project 3)
- **Step 10** — Append assistant reply to `messages` after each call (Project 3)
- **Step 11** — Read `context.txt` from disk with safe path handling + UTF-8 (Project 4 — NEW)
- **Step 12** — Inject file contents into `system_prompt` before seeding `messages` (Project 4 — NEW)

For **Project 5 (PDF Reader Bot)**, the sequence will include Steps 1–10 above, then replace Step 11 with PDF parsing, and so on through every project. By Project 15, every chatbot is built from ~40+ steps spanning all 15 projects.

#### Why this rhythm

- **One-take progress per language** — type the code manually, run it, confirm it works.
- **Forced repetition compounds memory** — by Project 15, "load API key" has been retyped 30 times across three languages and is permanent.
- **No cognitive load from three syntaxes at once** — focus on one language's idioms before comparing.
- **Catches drift** — retyping every step from scratch surfaces small bugs and prevents copy-paste rot.

### Assistant response format per step

When I confirm a step or ask for the next one, respond in this order:

1. **Step heading** — e.g., `Step 1: Load API key from environment (Project 1)` — labeled with which project it originates from.
2. **CONCEPT block** in the comment format from `TrilingualCodingInstructorPrompt.md` (CONCEPT, bullets, STEP-BY-STEP, code with inline comments).
3. **Code for the current language only** — 1–3 lines per step where possible.
4. **How to verify it works** (one command or one line of expected output).
5. **Stop.** Wait for "next step" or "next language."

Do **not** include R, Python, AND C# in the same response unless I explicitly ask for "all three at once."

### Language order

Default order: **R → Python → C#** (matches the series convention from rule 4 in *Series rules*).

But I can override at the start: "let's start with Python," "let's do C# first," etc.

### Trigger phrases I will use

- **"start with [language]"** — pick which language to begin
- **"next step"** — move to the next step in the same language
- **"next language"** — switch to the next language and restart at Step 1
- **"redo step X"** — repeat a step (e.g., for debugging)
- **"all three at once"** — override and show R, Python, C# side-by-side for the current step

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

Read a `.txt` file from disk and inject it into `system_prompt` **before** seeding `messages`. Memory loop, API call, and exit condition are **rewritten from scratch** here using every step from Projects 1–3.

### Step sequence for Project 4 (full rebuild)

| # | Step | Origin |
|---|------|--------|
| 1 | Load API key from environment | Project 1 |
| 2 | Define `base_url` and headers | Project 1 |
| 3 | Build HTTP POST with JSON payload | Project 1 |
| 4 | Parse JSON response, extract assistant text | Project 1 |
| 5 | Define `system_prompt` string | Project 2 |
| 6 | Seed `messages` list with system role | Project 2 |
| 7 | Build infinite conversation loop with exit condition | Project 2 |
| 8 | Append user message to `messages` before API call | Project 3 |
| 9 | Pass full `messages` history to API on every call | Project 3 |
| 10 | Append assistant reply to `messages` after each call | Project 3 |
| 11 | Read `context.txt` from disk with safe path + UTF-8 | **Project 4 — NEW** |
| 12 | Inject file contents into `system_prompt` before seeding `messages` | **Project 4 — NEW** |

Each step gets its own response per language. Step 1 in R, then "next step" → Step 2 in R, etc., through Step 12 in R. Then "next language" → Step 1 in Python, and so on.

### New skills (Project 4)

- File I/O: Python `open(..., encoding="utf-8")`; R `paste(readLines(file.path(...), ...), collapse="\n")` with UTF-8; C# `File.ReadAllText(..., Encoding.UTF8)`
- Path handling: Python `pathlib.Path`; R `file.path()`; C# `Path.Combine` / `AppContext.BaseDirectory`
- String injection into `system_prompt` before seeding `messages`
- Comment: **why** context belongs in the **system** role, not the user role
- Separation of concerns: external `.txt` changes behavior without editing source

### Format checklist

- Terminal setup first in assistant responses; README mirrors it at the top
- **Live coding flow:** assistant asks which language to start in, then walks through Steps 1–12 sequentially in that language, one step per response, before switching to the next language.
- Order in **README/docs only**: R → Python → C# (this is documentation order, not live-teaching order)
- UTF-8 Windows gotcha in all three languages
- Sample `context.txt`
- README equivalency table for Projects **1–4**
- README ends with **Skills repeated** and **New skill introduced**; Project 4 also adds **What this unlocks** (RAG) after those sections

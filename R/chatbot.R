# --- Project 1: Hello LLM ---

library(httr2)
library(jsonlite)
library(dotenv)

# Load optional .env from the working directory into the process environment for local OPENAI_API_KEY (run from repo root).
dotenv::load_dot_env()

# Load API key from environment so secrets never live in source control.
api_key <- Sys.getenv("OPENAI_API_KEY")
if (!nzchar(api_key)) {
  stop("Set OPENAI_API_KEY in your environment or .env file before running.")
}

# Central place for the API endpoint so you can swap providers or versions later.
base_url <- "https://api.openai.com/v1/chat/completions"

call_openai <- function(messages) {
  # Build HTTP POST with JSON body, send chat history, return assistant text from JSON.
  req <- request(base_url) |>
    req_headers(
      Authorization = paste("Bearer", api_key),
      `Content-Type` = "application/json"
    ) |>
    req_body_json(list(model = "gpt-4o-mini", messages = messages))

  resp <- req_perform(req)
  # Parse JSON explicitly with jsonlite so the response shape is clear and consistent with other languages' parse step.
  parsed <- jsonlite::fromJSON(resp_body_string(resp), simplifyVector = FALSE)
  parsed$choices[[1]]$message$content
}

# --- Project 2: Persona Bot ---

run_chat <- function(system_prompt) {
  # Seed the messages list with the system role so the model always sees persona + file context first.
  messages <- list(list(role = "system", content = system_prompt))

  # Infinite conversation loop with exit condition (user types quit).
  cat("Chat with context loaded. Type 'quit' to exit.\n\n")

  repeat {
    user_text <- trimws(readline("You: "))
    if (tolower(user_text) == "quit") break
    if (!nzchar(user_text)) next

    # --- Project 3: Chatbot with Memory ---

    # Append user message to messages before calling API so this turn is part of the thread.
    messages <- append(messages, list(list(role = "user", content = user_text)))

    # Pass full messages history on every API call (call_openai receives the whole list).
    assistant_reply <- call_openai(messages)

    # Append assistant reply to messages after each turn so the next loop carries memory forward.
    messages <- append(messages, list(list(role = "assistant", content = assistant_reply)))

    cat("Assistant:", assistant_reply, "\n\n")
  }
}

# --- Project 4: Context from a File (new skills at bottom of file) ---

main <- function() {
  # Path handling: locate this script's directory, then join to repo-root context file safely across OSes.
  args <- commandArgs(trailingOnly = FALSE)
  file_flags <- args[startsWith(args, "--file=")]
  script_dir <- if (length(file_flags)) {
    dirname(normalizePath(sub("^--file=", "", file_flags[1])))
  } else {
    getwd()
  }
  context_path <- normalizePath(file.path(script_dir, "..", "context.txt"), mustWork = TRUE)

  # File I/O: readLines + paste preserves newlines; UTF-8 avoids Windows code-page corruption.
  # Windows gotcha: readLines without encoding = "UTF-8" assumes the native locale and can mangle UTF-8 files—always set it.
  file_context <- paste(
    readLines(context_path, encoding = "UTF-8", warn = FALSE),
    collapse = "\n"
  )

  # String injection: merge file text into the system string before we build the conversation.

  # Define a system persona string (base behavior before we layer file context on top).
  persona <- "You are a helpful assistant that stays faithful to the supplied context."
  system_prompt <- paste0(persona, "\n\n--- Context from file ---\n", file_context)

  # Prompt engineering: system role sets stable instructions and knowledge boundaries for the model;
  # putting this in the user role would make it look like a turn the human "said," which confuses multi-turn memory and priority.

  # Separation of concerns: editing context.txt changes behavior without editing this script.

  run_chat(system_prompt)
}

main()

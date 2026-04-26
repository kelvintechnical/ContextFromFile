# --- Project 1: Hello LLM ---

import os
from pathlib import Path

import requests
from dotenv import load_dotenv

# Load optional .env from the repo root so local development can supply OPENAI_API_KEY without exporting it in the shell.
_repo_root_for_env = Path(__file__).resolve().parent.parent
load_dotenv(_repo_root_for_env / ".env")

# Load API key from environment so secrets never live in source control.
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise RuntimeError("Set OPENAI_API_KEY in your environment or .env file before running.")

# Central place for the API endpoint so you can swap providers or versions later.
base_url = "https://api.openai.com/v1/chat/completions"


def call_openai(messages: list) -> str:
    """Build HTTP POST with JSON body, send chat history, return assistant text from JSON."""
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "gpt-4o-mini",
        "messages": messages,
    }
    response = requests.post(base_url, headers=headers, json=payload, timeout=120)
    response.raise_for_status()
    data = response.json()
    # Parse JSON response: the model reply lives under choices[0].message.content.
    return data["choices"][0]["message"]["content"]


# --- Project 2: Persona Bot ---


def run_chat(system_prompt: str) -> None:
    # Seed the messages list with the system role so the model always sees persona + file context first.
    messages = [{"role": "system", "content": system_prompt}]

    # Infinite conversation loop with exit condition (user types quit).
    print("Chat with context loaded. Type 'quit' to exit.\n")

    while True:
        user_text = input("You: ").strip()
        if user_text.lower() == "quit":
            break
        if not user_text:
            continue

        # --- Project 3: Chatbot with Memory ---

        # Append user message to messages before calling API so this turn is part of the thread.
        messages.append({"role": "user", "content": user_text})

        # Pass full messages history on every API call (call_openai receives the whole list).
        assistant_reply = call_openai(messages)

        # Append assistant reply to messages after each turn so the next loop carries memory forward.
        messages.append({"role": "assistant", "content": assistant_reply})

        print(f"Assistant: {assistant_reply}\n")


# --- Project 4: Context from a File (new skills at bottom of file) ---


def main() -> None:
    # Path handling: anchor to this script so the context file resolves the same on any machine.
    repo_root = Path(__file__).resolve().parent.parent
    context_path = repo_root / "context.txt"

    # File I/O: read external knowledge with open() and UTF-8 so Windows never mis-decodes the file as a legacy code page.
    # Windows gotcha: omitting encoding= often defaults to cp1252 (or similar) and corrupts UTF-8 text—always pass utf-8.
    with open(context_path, encoding="utf-8") as handle:
        file_context = handle.read()

    # String injection: merge file text into the system string before we build the conversation.

    # Define a system persona string (base behavior before we layer file context on top).
    persona = "You are a helpful assistant that stays faithful to the supplied context."
    system_prompt = f"{persona}\n\n--- Context from file ---\n{file_context}"

    # Prompt engineering: system role sets stable instructions and knowledge boundaries for the model;
    # putting this in the user role would make it look like a turn the human "said," which confuses multi-turn memory and priority.

    # Separation of concerns: editing context.txt changes behavior without editing this script.

    run_chat(system_prompt)


if __name__ == "__main__":
    main()

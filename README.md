---
title: Pokedex Agent
emoji: ⚡
colorFrom: yellow
colorTo: red
sdk: gradio
sdk_version: 5.23.1
app_file: app.py
pinned: false
tags:
- smolagents
- agent
- smolagent
- tool
- agent-course
---

# ⚡ Pokedex Agent

My first AI agent, built with [smolagents](https://github.com/huggingface/smolagents) for the [Hugging Face Agents Course](https://huggingface.co/learn/agents-course). Ask it about any Pokémon and it looks up the real stats from [PokéAPI](https://pokeapi.co/).

> **You:** What type is pikachu?
> **Agent:** electric

## How it works

This is **not** a single question-and-answer call to an LLM. It's an **agent loop**: the model thinks, writes some Python code that calls a tool, sees the result, and repeats until it has an answer (up to `max_steps=6`).

For "What type is pikachu?":

1. **LLM call #1** – The model gets the question plus the list of available tools (from `prompts.yaml`) and writes code: `pokemon_info(name="pikachu")`
2. **On your machine** – smolagents runs that code, so `pokemon_info` calls PokéAPI and gets back `Pikachu: type(s) electric; ...`
3. **LLM call #2** – The model sees that result and writes `final_answer("electric")`
4. Done. The answer appears in the chat.

That's 2 LLM calls for one question, and harder questions take more steps.

### Where things run

| Part | Runs on |
|---|---|
| The model "thinking" (`Qwen/Qwen2.5-Coder-32B-Instruct`) | Hugging Face servers |
| Tools (`pokemon_info`, the PokéAPI request) | Your machine |
| Python code the model writes | Your machine, in smolagents' restricted interpreter |
| Gradio chat UI | Your machine |

The model is called through `HfApiModel`, which uses **Hugging Face's hosted inference API**. Your Hugging Face token identifies you and uses your free quota or credits. Nothing runs through Ollama or a local model. To run the model locally instead, you'd swap `HfApiModel` for a local model class.

The model never calls PokéAPI itself. It only writes code saying which tool to use, and your machine runs it and sends back the result.

## Project layout

| File | What it does |
|---|---|
| `app.py` | Defines the tools, the model, and the agent, then launches the UI |
| `prompts.yaml` | System prompt and templates that teach the model how to write tool-calling code |
| `Gradio_UI.py` | The chat interface |
| `tools/final_answer.py` | The tool the agent calls to finish with an answer |

## Step 1: Get a Hugging Face token

The agent calls the model through Hugging Face, so you need a token with the right permission. A token that's valid but lacks this permission still fails, with `403 Forbidden`.

1. Go to https://huggingface.co/settings/tokens.
2. Click **Create new token** and choose **Fine-grained**. To use an existing token, click **⋮ → Edit permissions** next to it instead.
3. Under **Inference**, tick **"Make calls to Inference Providers"**.
4. Save, then copy the token (it starts with `hf_`).

### Put it in `.env`

Copy `.env.example` to `.env` and paste your token in:

```
HF_TOKEN=hf_your_token_here
```

Rules for this file:
- The name must be **`HF_TOKEN` in capitals**. `hf_token=` is silently ignored.
- Don't add quotes or spaces around the `=`.
- Never commit it. `.env` is already in `.gitignore` and `.dockerignore`.

> 💡 **Two places your token can come from.** Docker reads the token in `.env`. Running locally with `huggingface-cli login` saves a token on your machine (`~/.cache/huggingface/token`) instead. These can be **different tokens with different permissions**, so the app can work locally and fail in Docker. If that happens, check the token in `.env`.

## Step 2a: Run with Docker (easiest)

No Python setup needed, just [Docker Desktop](https://www.docker.com/products/docker-desktop/). Make sure Docker Desktop is open and running first.

1. Set up your token as described in Step 1.
2. Build and run:
   ```bash
   docker compose up --build
   ```
3. Open http://localhost:7860. Press `Ctrl + C` to stop.

After the first build, `docker compose up` is enough. Add `--build` again after you change the code.

## Step 2b: Run locally without Docker

**Use Python 3.12.** Python 3.14 breaks Gradio 5.23.1 (`AttributeError: 'NoneType' object has no attribute 'wait'`). Check your version with `python3 --version`.

First-time setup:

```bash
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
huggingface-cli login     # paste the token from Step 1
```

Every time after that:

```bash
source .venv/bin/activate   # your prompt should start with (.venv)
python app.py
```

Then open http://127.0.0.1:7860.

The packages are installed **only inside `.venv`**. Running `python3 app.py` without activating it uses your system Python, which doesn't have them. In VS Code, run **Python: Select Interpreter** and pick the `.venv` one so the ▶ Run button uses it too.

> ⚠️ The UI launches with `share=True`, which also creates a public `gradio.live` link. Anyone with that link can use your agent and your Hugging Face credits. Set `share=False` in `Gradio_UI.py` to keep it local.

## Troubleshooting

| Error | Fix |
|---|---|
| `ModuleNotFoundError: No module named 'smolagents'` | You're not using the venv. Run `source .venv/bin/activate` first. |
| `'NoneType' object has no attribute 'wait'` | Your venv uses Python 3.14. Rebuild it with Python 3.12 (see above). |
| `403 Forbidden ... does not have sufficient permissions to call Inference Providers` | Your token lacks the "Make calls to Inference Providers" permission. Edit it or create a new one (Step 1). |
| Works locally but fails in Docker | Docker uses the token in `.env`, while local runs use your `huggingface-cli login` token. Fix the one in `.env`. |
| `401 Unauthorized` / token not picked up | Check that `.env` says `HF_TOKEN=` in capitals with no quotes. |
| App starts on port **7861** instead of 7860, or Docker says the port is in use | Another copy is already running. Press `Ctrl + C` in its terminal, or run `docker compose down`. |
| `Cannot connect to the Docker daemon` | Docker Desktop isn't running. Open it and wait for it to start. |
| Agent doesn't answer / hangs | The model may be overloaded. Try another model, or the endpoint mentioned in `app.py`. |

## What we fixed along the way

Notes from getting this running the first time:

1. **Wrong Python.** `python3 app.py` failed with `No module named 'smolagents'` because the packages were only in `.venv`. Fix: activate the venv first.
2. **Python 3.14 too new.** The venv was built on Python 3.14, and Gradio 5.23.1 crashed with `'NoneType' object has no attribute 'wait'`. In 3.14, `asyncio.get_event_loop()` raises an error when no event loop is running, so Gradio's `stop_event` ended up as `None`. Fix: rebuild the venv on Python 3.12 and pin `gradio==5.23.1` in `requirements.txt`.
3. **`.env` format.** The file had `hf_token=...` in lowercase. Hugging Face only reads `HF_TOKEN`. Fix: use capitals.
4. **Token permissions.** In Docker the token was valid but every model call returned `403 Forbidden`. It worked locally only because a different token was saved by `huggingface-cli login`. Fix: tick "Make calls to Inference Providers" on the token.
5. **Dockerized it.** We added a `Dockerfile` (Python 3.12), `compose.yaml`, and `.dockerignore` so nobody has to deal with steps 1 and 2 again.

## Ideas for more tools

- Compare two Pokémon's base stats
- Look up type weaknesses
- Get a Pokémon's sprite with the image generation tool

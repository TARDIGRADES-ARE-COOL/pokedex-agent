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

## Running it locally

**Use Python 3.12.** Python 3.14 breaks Gradio 5.23.1 (`AttributeError: 'NoneType' object has no attribute 'wait'`).

```bash
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

huggingface-cli login     # paste a token from https://huggingface.co/settings/tokens
python app.py
```

Then open http://127.0.0.1:7860.

> ⚠️ The UI launches with `share=True`, which also creates a public `gradio.live` link. Anyone with that link can use your agent and your Hugging Face credits. Set `share=False` in `Gradio_UI.py` to keep it local.

## Troubleshooting

| Error | Fix |
|---|---|
| `ModuleNotFoundError: No module named 'smolagents'` | You're not using the venv. Run `source .venv/bin/activate` first. |
| `'NoneType' object has no attribute 'wait'` | Your venv uses Python 3.14. Rebuild it with Python 3.12 (see above). |
| Agent doesn't answer / hangs | The model may be overloaded. Try another model, or the endpoint mentioned in `app.py`. |

## Ideas for more tools

- Compare two Pokémon's base stats
- Look up type weaknesses
- Get a Pokémon's sprite with the image generation tool

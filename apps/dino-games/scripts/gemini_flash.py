#!/usr/bin/env python3

import os
from google import genai
from google.genai.types import HarmCategory, HarmBlockThreshold

# 1. AUTHENTICATION
# This pulls the key you saved in your .env
api_key = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=api_key)

# MODEL
#for m in client.models.list():
#    print(m.name, m.display_name)

MODEL_NAME = client.models.get(GEMINI_MODEL="gemini-2.5-flash")
model_info = client.models.get(model=MODEL_NAME)
# Quick test prompt (dino-themed!)
response = client.models.generate_content(
    model=MODEL_NAME,  
    contents="You're a wise old T-Rex game master in a dino adventure game. Describe a fun, short encounter with a sneaky velociraptor pack in 3-4 sentences.",
    # Optional: safety + generation config
    config=genai.types.GenerateContentConfig(
        temperature=0.9,          # more creative
        max_output_tokens=300,
        safety_settings=[
            genai.types.SafetySetting(
                category=HarmCategory.HARM_CATEGORY_HARASSMENT,
                threshold=HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            ),
            # Add DANGEROUS_CONTENT etc. if needed
        ]
    )
)

print("\n=== Dino Encounter ===")
print(response.text)


#!/usr/bin/env python3

import os
from google import genai
from google.genai.types import HarmCategory, HarmBlockThreshold

# 1. AUTHENTICATION
# This pulls the key you saved in your .env
api_key = os.getenv("GEMINI_API_KEY")
client = genai.Client() 

# 2. SAFETY FILTERS (The "Child-Safe" Shield)
# We set these to be very strict to ensure the "Toy Aesthetic" is maintained.
safety_settings = {
    HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
    HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
    HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
    HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
}

# 3. THE "PERMANENT" STYLE (Your Boilerplate)
STYLE_BOILERPLATE = (
    "1024x1024 px, high-poly 3D animation style, cute toy aesthetic, "
    "vibrant colors, smooth clay textures, diagonal high-angle view, "
    "isolated on white background. No realism, no gore, simplified shapes. "
    "A deep-welled plastic lunch tray with a toy fork and spoon."
)

# 4. INITIALIZE THE MODEL
# We use Gemini 1.5 Flash for speed and image generation
model = genai.GenerativeModel(
    model_name='gemini-1.5-flash',
    safety_settings=safety_settings
)

def create_dino_prompt(species, ingredients):
    """
    Combines the style boilerplate with specific dinosaur diet items.
    """
    ingredient_list = ", ".join(ingredients)
    action_description = f"The tray wells are filled with: {ingredient_list}."
    
    return f"{STYLE_BOILERPLATE} {action_description} This tray is for a baby {species}."

# --- EXAMPLE USAGE ---
# ingredients = ["fan-shaped yellow ginkgo leaves", "fuzzy green moss", "brown pine cones"]
# prompt = create_dino_prompt("Diplodocus", ingredients)
# print(prompt)

#!/usr/bin/env python3
import os
from google import genai
from google.genai import types

MODEL_ID = 'gemini-2.5-flash-image'

# 1. AUTHENTICATION
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

# 2. CONFIGURATION
config = types.GenerateContentConfig(
    # response_modalities tells the model to output an image instead of just text
    response_modalities=["IMAGE"], 
    temperature=0.7,
    safety_settings=[
        types.SafetySetting(
            category=types.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
            threshold=types.HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
        ),
    ],
)

# 3. THE GENERATOR FUNCTION
def generate_dino_image(species, ingredients):
    prompt = (
        f"1024x1024 px, high-poly 3D animation style, cute toy aesthetic, "
        f"vibrant colors, smooth clay textures, diagonal high-angle view. "
        f"A plastic lunch tray with wells containing: {', '.join(ingredients)}. "
        f"Isolated on white background. Friendly toy look for a baby {species}."
    )
    
    print(f"Generating tray for {species} using {MODEL_ID}...")
    
    # We use gemini-2.0-flash which supports native image generation
    response = client.models.generate_content(
        model=MODEL_ID,
        contents=prompt,
        config=config
    )
    
    # 4. SAVING THE IMAGE
    # The image data is stored in the first 'part' of the first 'candidate'
    for part in response.candidates[0].content.parts:
        if part.inline_data:
            filename = f"{species.lower()}_tray.png"
            with open(filename, "wb") as f:
                f.write(part.inline_data.data)
            print(f"Success! Saved to {filename}")
            return
            
    print("Error: No image was generated in the response.")

# --- EXECUTION ---
if __name__ == "__main__":
    # Test with a Diplodocus
    test_ingredients = ["yellow fan-shaped ginkgo leaves", "smooth brown pine cones", "feathery ferns"]
    generate_dino_image("Diplodocus", test_ingredients)

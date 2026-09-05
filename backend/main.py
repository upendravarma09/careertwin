import os
import json

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
from google import genai

load_dotenv()

app = FastAPI(title="CareerTwin AI Backend")

api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    raise RuntimeError("GEMINI_API_KEY is missing from .env")

client = genai.Client(api_key=api_key)


class CareerRequest(BaseModel):
    name: str
    current_role: str
    skills: str
    experience: str
    career_goal: str


@app.get("/")
def home():
    return {
        "status": "online",
        "message": "CareerTwin AI Backend is running"
    }


@app.post("/analyze")
def analyze_career(request: CareerRequest):

    prompt = f"""
You are CareerTwin, an expert AI career advisor.

Analyze this person's career profile:

Name: {request.name}
Current role or education: {request.current_role}
Skills: {request.skills}
Experience level: {request.experience}
Target career: {request.career_goal}

The target career can be ANY career that exists today or may emerge
in the future. It can be technical, non-technical, creative,
scientific, medical, business, professional, or any other field.

Determine:

1. A realistic career match score from 0 to 100.
2. The user's strongest relevant skills.
3. The most important missing skills or competencies.
4. A personalized step-by-step roadmap.
5. A concise recommendation for the user's next step.

Return ONLY valid JSON in exactly this structure:

{{
    "match_score": 0,
    "strengths": [],
    "skill_gaps": [],
    "roadmap": [],
    "recommendation": ""
}}
"""

    try:
        response = client.models.generate_content(
           model="gemini-3.6-flash",
            contents=prompt
        )

        result_text = response.text.strip()

        if result_text.startswith("```"):
            result_text = result_text.replace("```json", "").replace("```", "").strip()

        result = json.loads(result_text)

        return result

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="Gemini returned invalid JSON."
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )
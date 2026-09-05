import os
from pathlib import Path
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import types
from pydantic import BaseModel

# Locate and load .env relative to this file's folder
env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=env_path)

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise RuntimeError("GEMINI_API_KEY is missing from .env")

client = genai.Client(api_key=api_key)

app = FastAPI(title="CareerTwin AI Backend")

# Allow all origins (including any localhost port used by Flutter Web)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://.*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

class ProfileRequest(BaseModel):
    name: str
    current_role: str
    skills: str
    experience: str
    career_goal: str

class CareerAnalysisResponse(BaseModel):
    match_score: int
    strengths: list[str]
    skill_gaps: list[str]
    roadmap: list[str]
    recommendation: str

@app.get("/")
def root():
    return {"status": "online", "message": "CareerTwin AI Backend is running"}

@app.post("/analyze", response_model=CareerAnalysisResponse)
def analyze_career(profile: ProfileRequest):
    prompt = f"""
    Analyze the career trajectory for this candidate against standard industry benchmarks:
    - Name: {profile.name}
    - Current Role / Education: {profile.current_role}
    - Existing Skills: {profile.skills}
    - Experience Level: {profile.experience}
    - Target Career Goal: {profile.career_goal}

    Evaluate:
    1. match_score: A realistic match percentage integer (0 to 100).
    2. strengths: A list of 3-5 existing skills or attributes relevant to the target career.
    3. skill_gaps: A list of 3-5 critical missing technical/practical skills.
    4. roadmap: Exactly 5 progressive milestone steps to achieve this career.
    5. recommendation: A clear, high-impact tactical piece of advice.
    """

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=CareerAnalysisResponse,
                temperature=0.2,
            ),
        )

        return CareerAnalysisResponse.model_validate_json(response.text)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
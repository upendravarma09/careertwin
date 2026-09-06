import os
from typing import List

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from google import genai
from google.genai import types


# --------------------------------------------------
# Environment
# --------------------------------------------------

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    raise RuntimeError("GEMINI_API_KEY is not set in backend/.env")


# --------------------------------------------------
# Gemini client
# --------------------------------------------------

client = genai.Client(api_key=GEMINI_API_KEY)

# Keep this configurable through .env.
# Your previous Gemini model error recommended gemini-3.6-flash.
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3.6-flash")


# --------------------------------------------------
# FastAPI
# --------------------------------------------------

app = FastAPI(
    title="CareerTwin AI Backend",
    description="Gemini-powered CareerTwin career analysis API",
    version="1.0.0",
)


# --------------------------------------------------
# CORS
# --------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --------------------------------------------------
# Request model
# --------------------------------------------------

class ProfileRequest(BaseModel):
    name: str = ""
    current_role: str
    skills: str
    experience: str = ""
    career_goal: str


# --------------------------------------------------
# Response model
# --------------------------------------------------

class AnalysisResponse(BaseModel):
    match_score: int = Field(ge=0, le=100)
    strengths: List[str]
    skill_gaps: List[str]
    roadmap: List[str]


# --------------------------------------------------
# Health check
# --------------------------------------------------

@app.get("/")
async def root():
    return {
        "status": "online",
        "service": "CareerTwin AI Backend",
        "ai": "Google Gemini",
        "model": GEMINI_MODEL,
    }


# --------------------------------------------------
# Analyze career profile
# --------------------------------------------------

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_profile(payload: ProfileRequest):

    prompt = f"""
You are CareerTwin, an AI Career Architect.

Analyze the following professional profile and determine how ready
the person is for their career goal.

PROFILE

Name:
{payload.name}

Current Role:
{payload.current_role}

Skills:
{payload.skills}

Experience:
{payload.experience}

Career Goal:
{payload.career_goal}

Your analysis must:

1. Calculate a realistic match score from 0 to 100.
2. Identify the person's strongest existing skills or advantages.
3. Identify the most important missing skills.
4. Create a practical learning roadmap to move from the current role
   toward the target career.

Be specific and practical.

Return ONLY valid JSON matching the requested response schema.
"""


    try:
        response = client.models.generate_content(
            model=GEMINI_MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=AnalysisResponse,
                temperature=0.2,
            ),
        )

        # The Gemini SDK provides the generated text here.
        raw_text = response.text

        if not raw_text:
            raise ValueError("Gemini returned an empty response")

        return AnalysisResponse.model_validate_json(raw_text)

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Gemini error: {str(e)}",
        )
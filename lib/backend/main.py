import os
from typing import List
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google import genai
from google.genai import types

# Load environment variables
load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise RuntimeError("GEMINI_API_KEY is not set in backend/.env")

client = genai.Client(api_key=api_key)

# ----------------- FastAPI Setup -----------------
app = FastAPI(title="CareerTwin Backend API")

# CORSMiddleware handles preflight requests automatically
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,  # must be False when using "*"
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------- Models -----------------
class ProfileRequest(BaseModel):
    current_role: str
    target_role: str
    skills: List[str]

class AnalysisResponse(BaseModel):
    match_score: int
    missing_skills: List[str]
    recommended_projects: List[str]
    learning_roadmap: List[str]
    summary: str

# ----------------- Routes -----------------
@app.get("/")
def health_check():
    return {"status": "healthy"}

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_profile(payload: ProfileRequest):
    if not payload.skills:
        raise HTTPException(status_code=400, detail="At least one skill required.")

    prompt = f"""
    Current Role: {payload.current_role}
    Target Role: {payload.target_role}
    Current Skills: {', '.join(payload.skills)}
    
    Evaluate career readiness, provide a match score (0-100), missing skills, 2-3 portfolio projects, and a chronological roadmap.
    """

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=AnalysisResponse,
                temperature=0.2,
            ),
        )

        # Extract JSON safely from Gemini response
        raw_text = response.candidates[0].content.parts[0].text
        return AnalysisResponse.model_validate_json(raw_text)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gemini error: {str(e)}")

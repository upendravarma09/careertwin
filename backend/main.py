import os
from typing import List, Union
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from google import genai
from google.genai import types

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise RuntimeError("GEMINI_API_KEY is not set in backend/.env")

# Initialize official Google GenAI Client
client = genai.Client(api_key=api_key)

app = FastAPI(title="CareerTwin Backend API")

# Setup CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Handle preflight OPTIONS requests cleanly
@app.options("/{full_path:path}")
async def preflight_handler(full_path: str):
    return {}

# ----------------- Schemas -----------------
class ProfileRequest(BaseModel):
    current_role: str
    target_role: str = ""
    career_goal: str = ""
    skills: Union[str, List[str]]

class AnalysisResponse(BaseModel):
    match_score: int = Field(
        ..., 
        description="Score between 0 and 100 representing role readiness."
    )
    missing_skills: List[str] = Field(
        ..., 
        description="Key technical or professional skills missing for the target role."
    )
    recommended_projects: List[str] = Field(
        ..., 
        description="2-3 practical portfolio projects to build relevant competencies."
    )
    learning_roadmap: List[str] = Field(
        ..., 
        description="Chronological step-by-step milestones to transition successfully."
    )
    summary: str = Field(
        ..., 
        description="Actionable summary evaluating the candidate's transition potential."
    )

# ----------------- Routes -----------------
@app.get("/")
def health_check():
    return {"status": "healthy", "service": "CareerTwin API"}

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_profile(payload: ProfileRequest):
    target = payload.target_role or payload.career_goal
    if not target:
        raise HTTPException(status_code=400, detail="Target role or career goal is required.")

    skills_str = payload.skills if isinstance(payload.skills, str) else ", ".join(payload.skills)
    if not skills_str.strip():
        raise HTTPException(status_code=400, detail="At least one skill is required.")

    prompt = f"""
    You are an elite career intelligence engine and technical mentor.
    Analyze this transition:
    
    Current Role: {payload.current_role}
    Target Role: {target}
    Current Skills: {skills_str}
    
    Evaluate career readiness, calculate an objective match score (0-100), identify missing skills,
    propose 2-3 portfolio projects, and outline a step-by-step chronological learning roadmap.
    """

    # Active models sequence
    models_to_try = [
        'gemini-3.6-flash',
        'gemini-3.5-flash',
    ]
    last_error = None

    for model_name in models_to_try:
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=AnalysisResponse,
                ),
            )
            return AnalysisResponse.model_validate_json(response.text)
        except Exception as e:
            last_error = e
            error_str = str(e)
            # Skip to fallback if capacity (503), quota, or model retirement occurs
            if any(marker in error_str for marker in ["404", "503", "NOT_FOUND", "UNAVAILABLE", "RESOURCE_EXHAUSTED"]):
                continue
            raise HTTPException(status_code=500, detail=f"AI Engine Error ({model_name}): {error_str}")

    raise HTTPException(status_code=503, detail=f"All candidate models unavailable. Last error: {last_error}")
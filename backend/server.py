# backend/server.py

import os
import time
from contextlib import asynccontextmanager

from dotenv import load_dotenv
load_dotenv(".env")

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# from src.modules.game.game_routes import router as game_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("[STARTUP] Hotel Management backend running (in-memory storage for now).")
    yield
    print("[SHUTDOWN] Server shutting down.")


app = FastAPI(title="Hotel Management Backend", version="1.0.0", lifespan=lifespan)


allowed_origins = [
    origin.strip()
    for origin in os.getenv("FRONTEND_URI", "").split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def log_request_time(request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    print(f"{request.method} {request.url.path} - {(time.perf_counter() - start) * 1000:.2f} ms")
    return response






@app.get("/health")
async def health():
    return {"status": "ok"}


if __name__ == "__main__":     
    
    uvicorn.run(
        "server:app",
        host="localhost",
        port=int(os.getenv("PORT", 8005)),
        reload=os.getenv("NODE_ENV") != "production"
    )

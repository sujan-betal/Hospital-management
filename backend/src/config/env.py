"""Centralised `.env` loading.

Every module used to call ``load_dotenv()`` with no path, which only locates
``.env`` when the process happens to be started from the ``backend/``
directory. When the server was launched from anywhere else (e.g. the repo
root) the SMTP / database secrets were silently missing and transactional
emails were dropped without error. Loading from an absolute path makes the
configuration independent of the working directory.
"""

import os

from dotenv import load_dotenv

BACKEND_DIR = os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
)
ENV_PATH = os.path.join(BACKEND_DIR, ".env")


def load_env(override: bool = False) -> None:
    """Load the backend `.env` file. Existing environment variables win by
    default so deployed runtimes (Render, Docker, CI) can still provide
    secrets via the platform."""
    load_dotenv(ENV_PATH, override=override)


load_env()

# ------------------------------------------------------------------------------
# Stage 1 - Build

FROM python:alpine AS build-image

ENV VENV=/workspace/.venv/
WORKDIR /workspace/

RUN python -m venv ${VENV} 

ENV PATH="${VENV}/bin:$PATH"
ENV PYTHONPATH="${VENV}/bin:$PYTHONPATH"

RUN pip install --no-cache-dir --upgrade pip setuptools wheel uv

# Copier les fichiers de configuration de dépendances
COPY pyproject.toml .
COPY uv.lock .

# Installation des dépendances
RUN uv sync

# ------------------------------------------------------------------------------
# Stage 2 - Run

FROM python:alpine AS run-image

ENV VENV=/workspace/.venv/

WORKDIR /workspace/

EXPOSE 8000

COPY --from=build-image ${VENV} ${VENV}

ENV PATH="${VENV}/bin:${PATH}"
ENV PYTHONPATH="${VENV}/bin:${PYTHONPATH}"
ENV PYTHONDONOTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

ARG CACHEBUST=1

# Add App
COPY src/handlers/ src/handlers/
COPY src/irc/ src/irc/
COPY src/config.py src/config.py
COPY src/main.py src/main.py

# Run
CMD ["python", "src/main.py"]

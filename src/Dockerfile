# Build stage: install dependencies
FROM python:3.11-slim-bookworm AS builder
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get upgrade -y --no-install-recommends \
  && apt-get install -y --no-install-recommends build-essential curl git \
  && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Run stage: copy app and run Chainlit
FROM python:3.11-slim-bookworm
ARG FILENAME
ARG PORT=8000
ENV FILENAME=${FILENAME}
WORKDIR /app

RUN apt-get update && apt-get upgrade -y --no-install-recommends && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY $FILENAME .
COPY chainlit.md .
COPY .chainlit ./.chainlit

EXPOSE $PORT
CMD ["/bin/sh", "-c", "exec chainlit run $FILENAME --port=$PORT"]

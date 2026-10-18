FROM python:3.12-slim

RUN pip install --no-cache-dir "mkdocs==1.6.1" "mkdocs-material==9.7.7" "watchfiles==1.3.0"

WORKDIR /docs
COPY watch.py /docs/watch.py

EXPOSE 8000

CMD ["python", "watch.py"]

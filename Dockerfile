FROM python:3.12-slim

RUN pip install --no-cache-dir "mkdocs==1.6.1" "mkdocs-material==9.7.0" "mkdocs-catppuccin==0.1.1" "watchfiles==1.1.1"

WORKDIR /docs
COPY watch.py /docs/watch.py

EXPOSE 8000

CMD ["python", "watch.py"]

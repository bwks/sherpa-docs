FROM python:3.12-slim

RUN pip install --no-cache-dir "mkdocs==1.6.1" mkdocs-material watchfiles

# Default working directory for mkdocs-material image is /docs
WORKDIR /docs
COPY watch.py /docs/watch.py

EXPOSE 8000

# Optional: keep the same entrypoint so you can run:
#   docker run --rm -it -p 8000:8000 -v ${PWD}:/docs mkdocs-catppuccin serve
# ENTRYPOINT ["mkdocs"]
CMD ["python", "watch.py"]

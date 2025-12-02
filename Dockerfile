# Start from official mkdocs-material image
FROM squidfunk/mkdocs-material

# Install Catppuccin theme for MkDocs
RUN pip install --no-cache-dir mkdocs-catppuccin

# Default working directory for mkdocs-material image is /docs
WORKDIR /docs

EXPOSE 8000

# Optional: keep the same entrypoint so you can run:
#   docker run --rm -it -p 8000:8000 -v ${PWD}:/docs mkdocs-catppuccin serve
ENTRYPOINT ["mkdocs"]
CMD ["serve", "-a", "0.0.0.0:8000"]

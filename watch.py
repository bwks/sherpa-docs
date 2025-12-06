from watchfiles import run_process

if __name__ == "__main__":
    run_process(
        ".",  # watch /docs (WORKDIR)
        target="mkdocs serve -a 0.0.0.0:8000",
        target_type="command",  # force command mode
        recursive=True,
        # optional: avoid loops if you have a local build dir
        # ignore_paths=['site'],
    )

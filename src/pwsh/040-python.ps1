function pyenv {
    python -m venv .venv
    .\.venv\Scripts\activate
}

function pyi {
    pip install -r requirements.txt
}

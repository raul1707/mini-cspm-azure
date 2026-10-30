"""Harmless demo app. The point of the lab is the OLD base image and OLD
packages (known CVEs), not an exploitable application. Debug mode stays off."""
from flask import Flask

app = Flask(__name__)


@app.get("/")
def home():
    return "mini CSPM Azure lab: nothing to see here.\n"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)

---
name: flask-development
description: Build Python web applications with Flask 3+, using the application factory pattern and Blueprints. Use when developing Flask projects — blueprint structure, routes, authentication, error handling, working with sessions, implementing forms, configuring flask extensions, Jinja2 templates, CLI commands, logging, security, and deployment. Also use when the user mentions Flask routes, blueprints, app factory, Flask-Login, Flask-WTF, or any Flask extension, even if they don't explicitly say "Flask development."
---

# Flask Development Skill

Target: **Flask 3.x** (Python 3.9+)

### Minimal Working Example

```python
# app.py
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return {"message": "Hello, World!"}

if __name__ == "__main__":
    app.run(debug=True)
```

Run: `uv run flask --app app run --debug`

## Core Patterns

### Application Factory

Always use the application factory pattern for production Flask applications:

```python
# app/__init__.py
from flask import Flask
from app.extensions import login_manager
from config import Config


def create_app(config_class=Config):
    """Application factory function."""
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialize extensions
    login_manager.init_app(app)

    # Register blueprints
    from app.main import bp as main_bp
    from app.auth import bp as auth_bp

    app.register_blueprint(main_bp)
    app.register_blueprint(auth_bp, url_prefix="/auth")

    # Register error handlers
    from app.errors import register_error_handlers
    register_error_handlers(app)

    return app
```

**Key Benefits**:

- Multiple app instances with different configs (testing)
- Avoids circular imports
- Extensions initialized once, bound to app later

### Extensions Module

Centralizing extensions in a separate file prevents circular imports — other modules can import extensions without importing `app`.

```python
# app/extensions.py
from flask_login import LoginManager

login_manager = LoginManager()
login_manager.login_view = "auth.login"
login_manager.login_message_category = "info"
```

### Configuration

Separate configurations for different environments:

```python
# config.py
import os
from dataclasses import dataclass
from dotenv import load_dotenv

load_dotenv()

@dataclass
class Config:
    """Base configuration."""
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-key")

@dataclass
class DevelopmentConfig(Config):
    """Development configuration."""
    DEBUG = True

@dataclass
class TestingConfig(Config):
    """Testing configuration."""
    TESTING = True
    WTF_CSRF_ENABLED = False

@dataclass
class ProductionConfig(Config):
    """Production configuration."""
    DEBUG = False

config = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
    "testing": TestingConfig,
    "default": DevelopmentConfig,
}
```

### Entry Point

```python
# run.py
from app import create_app

app = create_app()

if __name__ == "__main__":
    app.run()
```

Run: `flask --app run run --debug`

### Creating a Blueprint

Blueprints organize routes into logical groups.

```python
# app/main/__init__.py
from flask import Blueprint

bp = Blueprint("main", __name__)

from app.main import routes  # Import routes after bp is created
```

```python
# app/main/routes.py
from flask import render_template, jsonify
from app.main import bp


@bp.route("/")
def index():
    return render_template("main/index.html")


@bp.route("/api/health")
def health():
    return jsonify({"status": "ok"})
```

### MethodViews

MethodViews map HTTP methods to class methods, which is useful when a single URL needs to handle multiple methods with distinct logic:

```python
# app/items/views.py
from flask import render_template, redirect, url_for, request
from flask.views import MethodView

from app.items import bp


class ItemView(MethodView):
    """CRUD operations for a single item."""

    def get(self, item_id: int) -> str:
        item = get_item_or_404(item_id)
        return render_template("items/detail.html", item=item)

    def post(self) -> str:
        # Handle item creation from form
        create_item(request.form)
        return redirect(url_for("items.list"))

    def delete(self, item_id: int) -> tuple:
        delete_item(item_id)
        return "", 204


# Register the view with the blueprint
item_view = ItemView.as_view("item")
bp.add_url_rule("/items/", view_func=item_view, methods=["POST"])
bp.add_url_rule("/items/<int:item_id>", view_func=item_view, methods=["GET", "DELETE"])
```

### Async Views

Flask 3.x has native async support. Use async views for I/O-bound operations:

```python
import asyncio
import httpx


@bp.route("/external-data")
async def get_external_data():
    async with httpx.AsyncClient() as client:
        response = await client.get("https://api.example.com/data")
        return response.json()


@bp.route("/multiple-sources")
async def get_multiple_sources():
    async with httpx.AsyncClient() as client:
        results = await asyncio.gather(
            client.get("https://api1.example.com/data"),
            client.get("https://api2.example.com/data"),
        )
        return {"source1": results[0].json(), "source2": results[1].json()}
```

### Context Locals (g, request, session)

```python
from flask import g, request, session, current_app

@app.before_request
def load_user():
    user_id = session.get("user_id")
    g.user = get_user(user_id) if user_id else None

@app.route("/profile")
def profile():
    if not g.user:
        return redirect(url_for("auth.login"))
    return render_template("profile.html", user=g.user)

# Access configuration via current_app (not the app instance directly)
def send_email(to: str, subject: str, body: str):
    smtp_server = current_app.config["SMTP_SERVER"]
    # ...
```

### CLI Commands

Register custom CLI commands for management tasks:

```python
import click
from flask import Flask


def register_cli(app: Flask):
    @app.cli.command("seed")
    @click.argument("count", default=10)
    def seed_data(count):
        """Seed the application with sample data."""
        click.echo(f"Seeding {count} records...")
        # ... create sample data
        click.echo("Done")
```

Run: `flask --app run seed 50`

### Logging

```python
import logging
from flask import Flask


def configure_logging(app: Flask):
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter(
        "[%(asctime)s] %(levelname)s in %(module)s: %(message)s"
    ))
    app.logger.addHandler(handler)
    app.logger.setLevel(logging.INFO)

# Use within request context
@bp.route("/action")
def some_action():
    current_app.logger.info("Action performed by user %s", g.user)
    return "ok"
```

### Security Best Practices

```python
from flask_wtf.csrf import CSRFProtect
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_cors import CORS
from flask_talisman import Talisman

csrf = CSRFProtect()
limiter = Limiter(key_func=get_remote_address)

def create_app(config_name: str = "default") -> Flask:
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    csrf.init_app(app)
    limiter.init_app(app)
    CORS(app, resources={r"/api/*": {"origins": app.config["ALLOWED_ORIGINS"]}})

    if not app.debug:
        Talisman(app, content_security_policy=app.config["CSP_POLICY"])

    return app

# Rate limiting on sensitive routes
@auth_bp.route("/login", methods=["POST"])
@limiter.limit("5 per minute")
def login():
    pass
```

### Error Handling

```python
# app/errors.py
from flask import jsonify, Flask


class APIError(Exception):
    """Base API error class."""
    status_code = 500

    def __init__(self, message: str, status_code: int = None):
        super().__init__()
        self.message = message
        if status_code is not None:
            self.status_code = status_code

    def to_dict(self) -> dict:
        return {"error": self.message}


class NotFoundError(APIError):
    status_code = 404


class ValidationError(APIError):
    status_code = 400


class AuthenticationError(APIError):
    status_code = 401


def register_error_handlers(app: Flask):
    @app.errorhandler(APIError)
    def handle_api_error(error):
        response = jsonify(error.to_dict())
        response.status_code = error.status_code
        return response

    @app.errorhandler(404)
    def handle_404(error):
        return jsonify({"error": "Resource not found"}), 404

    @app.errorhandler(500)
    def handle_500(error):
        app.logger.error(f"Server error: {error}")
        return jsonify({"error": "Internal server error"}), 500
```

## Authentication

For authentication patterns with Flask-Login (forms, routes, protecting routes, custom decorators), see `references/authentication.md`.

## Critical Rules

### Always Do

1. **Use application factory pattern** — enables testing, avoids globals
2. **Put extensions in separate file** — prevents circular imports
3. **Import routes at bottom of blueprint `__init__.py`** — after `bp` is created
4. **Use `current_app` not `app`** — inside request context

### Never Do

1. **Never import `app` in modules that `app` imports** — causes circular imports
2. **Never store secrets in code** — use environment variables
3. **Never use `app.run()` in production** — use Gunicorn
4. **Never skip CSRF protection** — keep Flask-WTF enabled for form submissions

## Common Errors & Fixes

### Circular Import Error

**Error**: `ImportError: cannot import name 'X' from partially initialized module`

**Fix**: Use deferred imports inside the factory function:

```python
# WRONG
from app.models import User  # at module level in app/__init__.py

# RIGHT
def create_app():
    # ... setup ...
    from app.models import User  # inside factory
```

### Working Outside Application Context

**Error**: `RuntimeError: Working outside of application context`

**Fix**: Wrap code in `app.app_context()`:

```python
app = create_app()
with app.app_context():
    # now current_app, g, etc. are available
    do_something()
```

### Blueprint Not Found

**Error**: `werkzeug.routing.BuildError: Could not build url for endpoint`

**Fix**: Include the blueprint name prefix in `url_for()`:

```python
# WRONG
url_for("login")

# RIGHT
url_for("auth.login")
```

### CSRF Token Missing

**Error**: `Bad Request: The CSRF token is missing`

**Fix**: Include the token in templates:

```html
<form method="post">
    {{ form.hidden_tag() }}
    <!-- form fields -->
</form>
```

## Testing

```python
# tests/conftest.py
import pytest
from app import create_app
from config import TestingConfig


@pytest.fixture
def app():
    app = create_app(TestingConfig)
    yield app


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def runner(app):
    return app.test_cli_runner()
```

```python
# tests/test_main.py
def test_index(client):
    response = client.get("/")
    assert response.status_code == 200
```

Run: `uv run pytest`

## Deployment

### Development

```bash
flask --app run run --debug
```

### Production with Gunicorn

```bash
uv add gunicorn
uv run gunicorn -w 4 -b 0.0.0.0:8000 "run:app"
```

### Environment Variables (.env)

```
SECRET_KEY=your-production-secret-key
FLASK_ENV=production
```

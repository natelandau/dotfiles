---
name: flask-development
description: Build Python web applications with Flask, using the application factory pattern, and Blueprints. Covers project structure, authentication, and configuration management. Use when developing Flask projects – blueprint structure, routes, authentication, error handling, working with sessions, implementing forms, configuring flask extensions, and more.
---

# Flask Development Skill

## Purpose

Build Python web applications with Flask, using the application factory pattern, and Blueprints. Covers project structure, authentication, and configuration management.

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
from app.extensions import db, login_manager
from config import Config


def create_app(config_class=Config):
    """Application factory function."""
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialize extensions
    db.init_app(app)
    login_manager.init_app(app)

    # Register blueprints
    from app.main import bp as main_bp
    from app.auth import bp as auth_bp

    app.register_blueprint(main_bp)
    app.register_blueprint(auth_bp, url_prefix="/auth")

    # Create database tables
    with app.app_context():
        db.create_all()

    return app
```

**Key Benefits**:

- Multiple app instances with different configs (testing)
- Avoids circular imports
- Extensions initialized once, bound to app later

### Extensions Module

```python
# app/extensions.py
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager

db = SQLAlchemy()
login_manager = LoginManager()
login_manager.login_view = "auth.login"
login_manager.login_message_category = "info"
```

**Why separate file?**: Prevents circular imports - models can import `db` without importing `app`.

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
    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL", "sqlite:///app.db")
    SQLALCHEMY_TRACK_MODIFICATIONS = False

@dataclass
class DevelopmentConfig(Config):
    """Development configuration."""
    DEBUG = True

@dataclass
class TestingConfig(Config):
    """Testing configuration."""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
    WTF_CSRF_ENABLED = False

@dataclass
class ProductionConfig(Config):
    """Production configuration."""
    DEBUG = False

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
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

Blueprints are used to organize routes into logical groups.

```python
# app/main/__init__.py
from flask import Blueprint

bp = Blueprint("main", __name__)

from app.main import routes  # Import routes after bp is created!
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

### MethodViews for more complex routes

```python
# app/auth/views.py
from flask import Blueprint
from flask.views import MethodView
from vclient import companies_service


bp = Blueprint("index", __name__)


class IndexView(MethodView):
    """Home page view."""

    def get(self) -> str:
        """Render the landing page."""

        return render_template("main/index.html")

    def post(self) -> str:
        """Handle the POST request."""

        return render_template("main/index.html")

    def put(self) -> str:
        """Handle the PUT request."""

        return render_template("main/index.html")

    def delete(self) -> str:
        """Handle the DELETE request."""

        return render_template("main/index.html")
```

### Async Views

Use async views for I/O-bound operations:

```python
from flask import Flask
import asyncio
import httpx

app = Flask(__name__)

@app.route('/external-data')
async def get_external_data():
    """Async route handler for external API calls."""
    async with httpx.AsyncClient() as client:
        response = await client.get('https://api.example.com/data')
        return response.json()

@app.route('/multiple-sources')
async def get_multiple_sources():
    """Fetch from multiple sources concurrently."""
    async with httpx.AsyncClient() as client:
        results = await asyncio.gather(
            client.get('https://api1.example.com/data'),
            client.get('https://api2.example.com/data'),
        )
        return {'source1': results[0].json(), 'source2': results[1].json()}
```

### Context Locals (g, request, session)

Use Flask context locals properly:

```python
from flask import g, request, session, current_app

@app.before_request
def load_user():
    """Load current user into g for request duration."""
    user_id = session.get('user_id')
    if user_id:
        g.user = User.query.get(user_id)
    else:
        g.user = None

@app.route('/profile')
def profile():
    """Use g.user set by before_request."""
    if not g.user:
        return redirect(url_for('auth.login'))
    return render_template('profile.html', user=g.user)

# Access configuration via current_app
def send_email(to: str, subject: str, body: str):
    """Send email using app configuration."""
    smtp_server = current_app.config['SMTP_SERVER']
    # ... send email
```

### Security Best Practices

Implement proper security measures:

```python
# app/__init__.py
from flask import Flask
from flask_wtf.csrf import CSRFProtect
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_cors import CORS
from flask_talisman import Talisman

csrf = CSRFProtect()
limiter = Limiter(key_func=get_remote_address)

def create_app(config_name: str = 'default') -> Flask:
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    # Security extensions
    csrf.init_app(app)
    limiter.init_app(app)

    # CORS for API endpoints
    CORS(app, resources={r"/api/*": {"origins": app.config['ALLOWED_ORIGINS']}})

    # Security headers (HTTPS, CSP, etc.)
    if not app.debug:
        Talisman(app, content_security_policy=app.config['CSP_POLICY'])

    return app

# Rate limiting on routes
@users_bp.route('/login', methods=['POST'])
@limiter.limit("5 per minute")
def login():
    """Login endpoint with rate limiting."""
    pass

# Exempt CSRF for API endpoints (use token auth instead)
@users_bp.route('/api/users', methods=['POST'])
@csrf.exempt
def api_create_user():
    """API endpoint with token authentication."""
    pass
```

### Error Handling with errorhandler

Implement centralized error handling:

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
        return {'error': self.message}

class NotFoundError(APIError):
    status_code = 404

class ValidationError(APIError):
    status_code = 400

class AuthenticationError(APIError):
    status_code = 401

def register_error_handlers(app: Flask):
    """Register error handlers with the application."""

    @app.errorhandler(APIError)
    def handle_api_error(error):
        response = jsonify(error.to_dict())
        response.status_code = error.status_code
        return response

    @app.errorhandler(404)
    def handle_404(error):
        return jsonify({'error': 'Resource not found'}), 404

    @app.errorhandler(500)
    def handle_500(error):
        app.logger.error(f'Server error: {error}')
        return jsonify({'error': 'Internal server error'}), 500

    @app.errorhandler(Exception)
    def handle_exception(error):
        app.logger.exception('Unhandled exception')
        return jsonify({'error': 'An unexpected error occurred'}), 500
```

## Authentication with Flask-Login

### Auth Forms

```python
# app/auth/forms.py
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SubmitField
from wtforms.validators import DataRequired, Email, Length, EqualTo, ValidationError
from app.models import User


class LoginForm(FlaskForm):
    email = StringField("Email", validators=[DataRequired(), Email()])
    password = PasswordField("Password", validators=[DataRequired()])
    remember = BooleanField("Remember Me")
    submit = SubmitField("Login")


class RegistrationForm(FlaskForm):
    email = StringField("Email", validators=[DataRequired(), Email()])
    password = PasswordField("Password", validators=[DataRequired(), Length(min=8)])
    confirm = PasswordField("Confirm Password", validators=[
        DataRequired(), EqualTo("password", message="Passwords must match")
    ])
    submit = SubmitField("Register")

    def validate_email(self, field):
        if User.query.filter_by(email=field.data).first():
            raise ValidationError("Email already registered.")
```

### Auth Routes

```python
# app/auth/routes.py
from flask import render_template, redirect, url_for, flash, request
from flask_login import login_user, logout_user, login_required, current_user
from app.auth import bp
from app.auth.forms import LoginForm, RegistrationForm
from app.extensions import db
from app.models import User


@bp.route("/register", methods=["GET", "POST"])
def register():
    if current_user.is_authenticated:
        return redirect(url_for("main.index"))

    form = RegistrationForm()
    if form.validate_on_submit():
        user = User(email=form.email.data)
        user.set_password(form.password.data)
        db.session.add(user)
        db.session.commit()
        flash("Registration successful! Please log in.", "success")
        return redirect(url_for("auth.login"))

    return render_template("auth/register.html", form=form)


@bp.route("/login", methods=["GET", "POST"])
def login():
    if current_user.is_authenticated:
        return redirect(url_for("main.index"))

    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data).first()
        if user and user.check_password(form.password.data):
            login_user(user, remember=form.remember.data)
            next_page = request.args.get("next")
            flash("Logged in successfully!", "success")
            return redirect(next_page or url_for("main.index"))
        flash("Invalid email or password.", "danger")

    return render_template("auth/login.html", form=form)


@bp.route("/logout")
@login_required
def logout():
    logout_user()
    flash("You have been logged out.", "info")
    return redirect(url_for("main.index"))
```

### Protecting Routes

```python
from flask_login import login_required, current_user

@bp.route("/dashboard")
@login_required
def dashboard():
    return render_template("main/dashboard.html", user=current_user)
```

### Custom Decorators for Auth/Validation

Create reusable decorators:

```python
# app/decorators.py
from functools import wraps
from flask import g, jsonify, request

def login_required(f):
    """Decorator to require authentication."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if g.user is None:
            return jsonify({'error': 'Authentication required'}), 401
        return f(*args, **kwargs)
    return decorated_function

def admin_required(f):
    """Decorator to require admin privileges."""
    @wraps(f)
    @login_required
    def decorated_function(*args, **kwargs):
        if not g.user.is_admin:
            return jsonify({'error': 'Admin privileges required'}), 403
        return f(*args, **kwargs)
    return decorated_function

def validate_json(*required_fields):
    """Decorator to validate required JSON fields."""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not request.is_json:
                return jsonify({'error': 'Content-Type must be application/json'}), 400

            data = request.get_json()
            missing = [field for field in required_fields if field not in data]
            if missing:
                return jsonify({'error': f'Missing required fields: {missing}'}), 400

            return f(*args, **kwargs)
        return decorated_function
    return decorator

# Usage
@users_bp.route('/profile', methods=['PUT'])
@login_required
@validate_json('email')
def update_profile():
    """Update user profile."""
    return UserService.update_user(g.user.id, **request.json)
```

## Critical Rules

### Always Do

1. **Use application factory pattern** - Enables testing, avoids globals
2. **Put extensions in separate file** - Prevents circular imports
3. **Import routes at bottom of blueprint `__init__.py`** - After `bp` is created
4. **Use `current_app` not `app`** - Inside request context
5. **Use `with app.app_context()`** - When accessing db outside requests

### Never Do

1. **Never import `app` in models** - Causes circular imports
2. **Never access `db` before app context** - RuntimeError
3. **Never store secrets in code** - Use environment variables
4. **Never use `app.run()` in production** - Use Gunicorn
5. **Never skip CSRF protection** - Keep Flask-WTF enabled or implement your own CSRF protection

## Common Errors & Fixes

### Circular Import Error

**Error**: `ImportError: cannot import name 'X' from partially initialized module`

**Cause**: Models importing app, app importing models

**Fix**: Use extensions.py pattern:

```python
# WRONG - circular import
# app/__init__.py
from app.models import User  # models.py imports db from here!

# RIGHT - deferred import
# app/__init__.py
def create_app():
    # ... setup ...
    from app.models import User  # Import inside factory
```

### Working Outside Application Context

**Error**: `RuntimeError: Working outside of application context`

**Cause**: Accessing `current_app`, `g`, or `db` outside request

**Fix**:

```python
# WRONG
from app import create_app
app = create_app()
users = User.query.all()  # No context!

# RIGHT
from app import create_app
app = create_app()
with app.app_context():
    users = User.query.all()  # Has context
```

### Blueprint Not Found

**Error**: `werkzeug.routing.BuildError: Could not build url for endpoint`

**Cause**: Using wrong blueprint prefix in `url_for()`

**Fix**:

```python
# WRONG
url_for("login")

# RIGHT - include blueprint name
url_for("auth.login")
```

### CSRF Token Missing

**Error**: `Bad Request: The CSRF token is missing`

**Cause**: Form submission without CSRF token

**Fix**: Include token in templates:

```html
<form method="post">
    {{ form.hidden_tag() }}
    <!-- Adds CSRF token -->
    <!-- form fields -->
</form>
```

---

## Testing

```python
# tests/conftest.py
import pytest
from app import create_app
from app.extensions import db
from config import TestingConfig


@pytest.fixture
def app():
    app = create_app(TestingConfig)
    with app.app_context():
        db.create_all()
        yield app
        db.drop_all()


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


def test_register(client):
    response = client.post("/auth/register", data={
        "email": "test@example.com",
        "password": "testpass123",
        "confirm": "testpass123",
    }, follow_redirects=True)
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

### Docker

```dockerfile
FROM python:3.12-slim

WORKDIR /app
COPY . .

RUN pip install uv && uv sync

EXPOSE 8000
CMD ["uv", "run", "gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "run:app"]
```

### Environment Variables (.env)

```
SECRET_KEY=your-production-secret-key
DATABASE_URL=postgresql://user:pass@localhost/dbname
FLASK_ENV=production
```

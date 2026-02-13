# Authentication Flows

## Overview

The Catalog Tool implements a **hybrid authentication system** supporting both traditional username/password authentication (Flask-Security) and modern OAuth2 authentication (Firebase). This dual approach provides flexibility for different deployment scenarios while maintaining security best practices.

---

## Authentication Architecture

### High-Level Components

```
┌─────────────────────────────────────────────────┐
│          Authentication Layer                    │
│                                                  │
│  ┌──────────────────┐    ┌──────────────────┐   │
│  │  Flask-Security  │    │     Firebase     │   │
│  │                  │    │      Auth        │   │
│  │  - Username/Pass │    │  - OAuth2/OIDC  │   │
│  │  - Email verify  │    │  - Social login  │   │
│  │  - Password reset│    │  - Token verify  │   │
│  └────────┬─────────┘    └────────┬─────────┘   │
│           │                       │             │
│           └───────────┬───────────┘             │
│                       │                         │
│              ┌────────▼─────────┐               │
│              │   User Model     │               │
│              │  - email         │               │
│              │  - password      │               │
│              │  - firebase_uid  │               │
│              │  - auth_method   │               │
│              └──────────────────┘               │
└─────────────────────────────────────────────────┘
```

---

## Flask-Security Authentication

### User Model Schema

```python
class User(db.Model, UserMixin):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    username = db.Column(db.String(255), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)  # Argon2 hashed
    
    # Auth tracking
    auth_method = db.Column(db.String(20), default='flask-security')
    firebase_uid = db.Column(db.String(128), unique=True, nullable=True)
    
    # Flask-Security trackable
    current_login_at = db.Column(db.DateTime)
    last_login_at = db.Column(db.DateTime)
    current_login_ip = db.Column(db.String(100))
    last_login_ip = db.Column(db.String(100))
    login_count = db.Column(db.Integer, default=0)
    
    # Role-based access
    roles = db.relationship('Role', secondary='roles_users',
                          backref=db.backref('users', lazy='dynamic'))
    
    # Admin flag
    is_admin = db.Column(db.Boolean, default=False)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
```

### Configuration

```python
# config.py
class Config:
    # Flask-Security
    SECURITY_PASSWORD_SALT = os.environ.get('SECURITY_PASSWORD_SALT')
    SECURITY_REGISTERABLE = True
    SECURITY_TRACKABLE = True
    SECURITY_RECOVERABLE = True
    SECURITY_USERNAME_ENABLE = True
    SECURITY_PASSWORD_HASH = 'argon2'
    
    # Session management
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
    PERMANENT_SESSION_LIFETIME = timedelta(days=7)
```

---

## Login Flow (Flask-Security)

### Step-by-Step Process

```
┌─────────────────────────────────────────────┐
│ 1. User Submits Login Form                 │
│    POST /login                              │
│    Form: {email/username, password}         │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. Flask-Security Validation                │
│    - Lookup user by email or username       │
│    - Hash submitted password with Argon2    │
│    - Compare with stored hash               │
└────────────────┬────────────────────────────┘
                 │
          ┌──────┴──────┐
          │  Valid?     │
          └──────┬──────┘
                 │
       ┌─────────┴─────────┐
       │ Yes               │ No
       │                   │
┌──────▼──────┐    ┌───────▼────────┐
│ 3a. Success │    │ 3b. Failure    │
│             │    │                │
│ - Create    │    │ - Flash error  │
│   session   │    │ - Redirect to  │
│ - Track     │    │   login page   │
│   login     │    │ - Log attempt  │
│   metadata  │    └────────────────┘
│ - Redirect  │
│   to /      │
└─────────────┘
```

### Code Implementation

```python
@app.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        # Find user by email or username
        user = User.query.filter(
            (User.email == form.email_or_username.data) |
            (User.username == form.email_or_username.data)
        ).first()
        
        if user and user.verify_password(form.password.data):
            # Login successful
            login_user(user, remember=form.remember_me.data)
            
            # Update tracking fields
            user.current_login_at = datetime.utcnow()
            user.current_login_ip = request.remote_addr
            user.login_count += 1
            db.session.commit()
            
            flash('Login successful', 'success')
            return redirect(url_for('index'))
        else:
            flash('Invalid credentials', 'error')
    
    return render_template('login.html', form=form)
```

---

## Registration Flow (Flask-Security)

### Step-by-Step Process

```
┌─────────────────────────────────────────────┐
│ 1. User Submits Registration Form          │
│    POST /register                           │
│    Form: {email, username, password}        │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. Validation                               │
│    - Email format valid?                    │
│    - Email unique?                          │
│    - Username unique?                       │
│    - Password meets requirements?           │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 3. Create User Record                       │
│    - Hash password with Argon2              │
│    - Set auth_method: 'flask-security'      │
│    - Assign default 'user' role             │
│    - Generate confirmation token (optional) │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 4. Send Confirmation Email (if enabled)     │
│    - Generate unique token                  │
│    - Send email with confirmation link      │
│    - User clicks link to activate           │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 5. Auto-login or Redirect                   │
│    - Create session (if email confirmed)    │
│    - Redirect to dashboard                  │
└─────────────────────────────────────────────┘
```

### Code Implementation

```python
@app.route('/register', methods=['GET', 'POST'])
def register():
    form = RegisterForm()
    if form.validate_on_submit():
        # Check if user exists
        if User.query.filter_by(email=form.email.data).first():
            flash('Email already registered', 'error')
            return render_template('register.html', form=form)
        
        if User.query.filter_by(username=form.username.data).first():
            flash('Username already taken', 'error')
            return render_template('register.html', form=form)
        
        # Create new user
        user = User(
            email=form.email.data,
            username=form.username.data,
            auth_method='flask-security'
        )
        user.password = hash_password(form.password.data)  # Argon2
        
        # Assign default role
        user_role = Role.query.filter_by(name='user').first()
        user.roles.append(user_role)
        
        db.session.add(user)
        db.session.commit()
        
        # Auto-login
        login_user(user)
        flash('Registration successful', 'success')
        return redirect(url_for('index'))
    
    return render_template('register.html', form=form)
```

---

## Firebase Authentication

### Firebase Configuration

```python
# config.py
FIREBASE_CONFIG = {
    'apiKey': os.environ.get('FIREBASE_API_KEY'),
    'authDomain': os.environ.get('FIREBASE_AUTH_DOMAIN'),
    'projectId': os.environ.get('FIREBASE_PROJECT_ID'),
}
```

### Firebase Login Flow

```
┌─────────────────────────────────────────────┐
│ 1. User Clicks "Continue with Firebase"    │
│    Frontend: firebase.auth().signInWithPopup()│
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. Firebase Authentication UI               │
│    - Email/password                         │
│    - Google                                 │
│    - GitHub                                 │
│    - etc.                                   │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 3. Firebase Returns ID Token                │
│    idToken = result.user.getIdToken()       │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 4. Client Sends Token to Backend            │
│    POST /api/auth/firebase                  │
│    Body: {id_token: "..."}                  │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 5. Backend Verifies Token                   │
│    decoded = firebase_admin.auth.verify_id_token(token)│
│    firebase_uid = decoded['uid']            │
│    email = decoded['email']                 │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 6. Find or Create User                      │
│    user = User.query.filter_by(firebase_uid=uid).first()│
│    if not user:                             │
│      user = User(email=email, firebase_uid=uid)│
│      user.auth_method = 'firebase'          │
│      db.session.add(user)                   │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 7. Create Session                           │
│    login_user(user)                         │
│    Track login metadata                     │
│    Return success response                  │
└─────────────────────────────────────────────┘
```

### Backend Implementation

```python
@app.route('/api/auth/firebase', methods=['POST'])
def firebase_auth():
    data = request.get_json()
    id_token = data.get('id_token')
    
    if not id_token:
        return jsonify({'status': 'error', 'message': 'Missing token'}), 400
    
    try:
        # Verify Firebase token
        decoded_token = firebase_admin.auth.verify_id_token(id_token)
        firebase_uid = decoded_token['uid']
        email = decoded_token.get('email')
        
        # Find or create user
        user = User.query.filter_by(firebase_uid=firebase_uid).first()
        
        if not user:
            # Create new user from Firebase
            user = User(
                email=email,
                username=email.split('@')[0],  # Generate username
                firebase_uid=firebase_uid,
                auth_method='firebase'
            )
            # No password needed for Firebase users
            user.password = generate_random_hash()  # Placeholder
            
            # Assign default role
            user_role = Role.query.filter_by(name='user').first()
            user.roles.append(user_role)
            
            db.session.add(user)
            db.session.commit()
        
        # Create session
        login_user(user)
        
        # Track login
        user.current_login_at = datetime.utcnow()
        user.current_login_ip = request.remote_addr
        user.login_count += 1
        db.session.commit()
        
        return jsonify({
            'status': 'success',
            'user': {
                'email': user.email,
                'username': user.username,
                'is_admin': user.is_admin
            }
        }), 200
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 401
```

### Frontend Implementation

```javascript
// firebase-auth.js
import { initializeApp } from 'firebase/app';
import { getAuth, signInWithPopup, GoogleAuthProvider } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "[CONFIGURED_VIA_ENV]",
  authDomain: "[CONFIGURED_VIA_ENV]",
  projectId: "[CONFIGURED_VIA_ENV]"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const provider = new GoogleAuthProvider();

async function signInWithFirebase() {
  try {
    const result = await signInWithPopup(auth, provider);
    const idToken = await result.user.getIdToken();
    
    // Send token to backend
    const response = await fetch('/api/auth/firebase', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id_token: idToken })
    });
    
    const data = await response.json();
    
    if (data.status === 'success') {
      window.location.href = '/';
    } else {
      alert('Authentication failed');
    }
  } catch (error) {
    console.error('Firebase auth error:', error);
  }
}
```

---

## Password Recovery Flow

### Step-by-Step Process

```
┌─────────────────────────────────────────────┐
│ 1. User Requests Password Reset             │
│    POST /reset-password                     │
│    Form: {email}                            │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. Generate Reset Token                     │
│    - Create unique token (random UUID)      │
│    - Set expiration (24 hours)              │
│    - Store in database or cache             │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 3. Send Reset Email                         │
│    - Email with reset link                  │
│    - Link: /reset-password/{token}          │
│    - SMTP configured via MAIL_SERVER env    │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 4. User Clicks Link                         │
│    GET /reset-password/{token}              │
│    - Validate token                         │
│    - Check expiration                       │
│    - Display new password form              │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 5. User Submits New Password                │
│    POST /reset-password/{token}             │
│    Form: {password, password_confirm}       │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 6. Update Password                          │
│    - Hash new password with Argon2          │
│    - Update user.password                   │
│    - Invalidate token                       │
│    - Auto-login or redirect to login        │
└─────────────────────────────────────────────┘
```

### Email Configuration

```python
# config.py
MAIL_SERVER = os.environ.get('MAIL_SERVER', 'smtp.example.com')
MAIL_PORT = int(os.environ.get('MAIL_PORT', 587))
MAIL_USE_TLS = os.environ.get('MAIL_USE_TLS', 'true').lower() == 'true'
MAIL_USERNAME = os.environ.get('MAIL_USERNAME')
MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')
MAIL_DEFAULT_SENDER = os.environ.get('MAIL_DEFAULT_SENDER', 'noreply@distro-nation.com')
```

---

## Session Management

### Session Lifecycle

```
┌─────────────────────────────────────────────┐
│ User Logs In                                │
│ - Session created with unique ID            │
│ - Session cookie sent to browser            │
│ - Cookie attributes: Secure, HttpOnly, SameSite│
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ Subsequent Requests                         │
│ - Browser sends session cookie              │
│ - Flask loads session data                  │
│ - current_user populated                    │
│ - @login_required checks session validity   │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ Session Expiration                          │
│ - Default: 7 days (PERMANENT_SESSION_LIFETIME)│
│ - Can be extended with "Remember Me"        │
│ - Inactive sessions expire                  │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ User Logs Out                               │
│ - POST /logout                              │
│ - Session deleted from server               │
│ - Cookie removed from browser               │
│ - Redirect to login page                    │
└─────────────────────────────────────────────┘
```

### Session Security Configuration

```python
# config.py
class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY')
    SESSION_COOKIE_SECURE = True  # HTTPS only
    SESSION_COOKIE_HTTPONLY = True  # No JavaScript access
    SESSION_COOKIE_SAMESITE = 'Lax'  # CSRF protection
    PERMANENT_SESSION_LIFETIME = timedelta(days=7)
```

---

## Role-Based Access Control (RBAC)

### Role Model

```python
class Role(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True)
    description = db.Column(db.String(255))

# Default roles
roles = [
    {'name': 'admin', 'description': 'Administrator with full access'},
    {'name': 'user', 'description': 'Regular user with standard access'}
]
```

### Authorization Decorators

```python
from functools import wraps
from flask_login import current_user

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            return redirect(url_for('login'))
        
        if not current_user.is_admin:
            abort(403)  # Forbidden
        
        return f(*args, **kwargs)
    return decorated_function

# Usage
@app.route('/admin/dashboard')
@admin_required
def admin_dashboard():
    return render_template('admin.html')
```

### Permission Checks

```python
# In templates
{% if current_user.is_admin %}
  <a href="/admin">Admin Panel</a>
{% endif %}

# In views
if current_user.has_role('admin'):
    # Allow administrative action
    pass
else:
    flash('Permission denied', 'error')
    return redirect(url_for('index'))
```

---

## Security Best Practices

### Password Hashing (Argon2)

```python
from passlib.hash import argon2

# Hashing
hashed = argon2.hash('user_password')

# Verification
is_valid = argon2.verify('user_password', hashed)
```

**Argon2 Benefits:**
- Memory-hard (resistant to GPU/ASIC attacks)
- Configurable time/memory cost
- Winner of Password Hashing Competition

### CSRF Protection

```python
from flask_wtf.csrf import CSRFProtect

csrf = CSRFProtect(app)

# Automatic CSRF protection for all POST requests
# Token embedded in forms automatically
```

### SQL Injection Prevention

```python
# SAFE: SQLAlchemy parameterized queries
User.query.filter_by(email=user_input).first()

# UNSAFE: String concatenation
db.session.execute(f"SELECT * FROM user WHERE email = '{user_input}'")
```

### XSS Prevention

```html
<!-- Jinja2 auto-escapes by default -->
<p>{{ user.username }}</p>  <!-- Safe -->

<!-- Bypass escaping (use with caution) -->
<p>{{ user.bio | safe }}</p>  <!-- Only if content is trusted -->
```

---

## Login Tracking & Audit

### Tracked Metadata

```python
class User(db.Model):
    # Automatic tracking by Flask-Security
    current_login_at = db.Column(db.DateTime)
    last_login_at = db.Column(db.DateTime)
    current_login_ip = db.Column(db.String(100))
    last_login_ip = db.Column(db.String(100))
    login_count = db.Column(db.Integer, default=0)
```

### Audit Queries

```python
# Recent logins
recent_logins = User.query.filter(
    User.last_login_at > datetime.utcnow() - timedelta(days=7)
).order_by(User.last_login_at.desc()).all()

# Failed login attempts (via custom logging)
failed_attempts = FailedLogin.query.filter(
    FailedLogin.ip_address == request.remote_addr,
    FailedLogin.created_at > datetime.utcnow() - timedelta(hours=1)
).count()

if failed_attempts > 5:
    # Block IP or require CAPTCHA
    pass
```

---

## Summary

The Catalog Tool authentication system provides:

- **Dual Authentication**: Flask-Security (traditional) and Firebase (OAuth2)
- **Security**: Argon2 password hashing, CSRF protection, secure session management
- **Flexibility**: Support for email/username login and social authentication
- **Tracking**: Comprehensive audit trail of login activity
- **RBAC**: Role-based access control for admin and user permissions
- **Recovery**: Secure password reset flow with email verification

This hybrid approach balances security, usability, and deployment flexibility while maintaining industry best practices for authentication and authorization.

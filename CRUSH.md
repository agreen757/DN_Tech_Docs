# CRUSH.md - Agent Guidelines for DN_Tech_Docs

## Build Commands
- Build documentation: `sphinx-build -b html . _build/html`
- Build specific format: `sphinx-build -b [html|pdf|htmlzip] . _build/[format]`
- Install dependencies: `pip install -r requirements.txt`
- Local preview: `cd _build/html && python -m http.server 8000`
- Clean build: `rm -rf _build/`
- Test ReadTheDocs build: `python -m sphinx -b html . _build/html`

## ReadTheDocs Setup
- Configuration file: `.readthedocs.yaml`
- Master document: `index.rst`
- If changing toctree, test build locally first
- Images must be in `_static/images/[app-name]/`
- Use relative links between documents

## Documentation Style
- Use Markdown (.md) for all documentation files
- Follow MyST Markdown syntax for advanced formatting
- Maintain consistent heading hierarchy (# for title, ## for sections)
- Use code blocks with language specification (```python)
- Link to other documents using relative paths

## File Organization
- Place application-specific docs in applications/[app-name]/
- Backend operations apps in applications/backend-operations/
- Common infrastructure in architecture/, networking/, security/
- API documentation in api/ directory
- Follow existing directory structure for new content
- Images should be in _static/images/[app-name]/

## Naming Conventions
- Use kebab-case for filenames (example-file-name.md)
- Start each file with a clear # Title
- Include README.md in each directory to explain contents
- Use descriptive, specific filenames that indicate content

## Backend Operations Applications
- **Claims Report System**: Documentation in applications/backend-operations/claims-report.rst
  - Build: `cd claims-report && docker-compose up`
  - Deploy: `cd claims-report && sh deploy.sh`
  - Local run: `cd claims-report && make run`

- **Audit Report System**: Documentation in applications/backend-operations/audit-report.rst
  - Build: `cd audit-report && docker build -t audit-report .`
  - Run: `cd audit-report && docker compose up`
  - Configure: Set MONTH and YEAR environment variables

## Content Guidelines
- Keep technical documentation factual and concise
- Include diagrams for complex architectures
- Document AWS resources with account IDs redacted
- Reference specific versions of technologies when relevant
- Maintain separation between application-specific and shared infrastructure docs
# Channel Population Tools Integration

## Overview

The CRM application includes a comprehensive **Channel Population Tools Suite** for discovering and onboarding music industry contacts (reaction channels, playlist curators) into the Firestore database.

**Location:** `~/Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/`

---

## Tools Suite Components

### 1. YouTube & Spotify Channel Autopopulator

**Purpose:** Automated discovery and Firestore integration for music reaction channels and playlist curators.

**Script:** `main.py` (orchestrator + CLI)

**Capabilities:**
- YouTube channel search with configurable queries
- Spotify playlist curator discovery
- OAuth-based authentication (AWS API Gateway token endpoint)
- Email extraction and validation
- Topic channel filtering (excludes auto-generated content)
- Subscriber threshold filtering
- API quota tracking and rate limiting
- CSV export and Firestore integration
- Comprehensive test suite (294+ unit tests)

**Authentication:**
- **OAuth via AWS API Gateway** (Recommended)
  - Endpoint: `YOUTUBE_TOKEN_URL` environment variable
  - API Key: `DN_API_KEY` environment variable
- Legacy YouTube API keys supported but deprecated

**Configuration Files:**
- `.env` - OAuth credentials and Firebase settings
- `search-config.json` - Search queries, filters, and thresholds

**Output:**
- CSV files: `output/youtube_reaction_channels.csv`, `output/spotify_playlist_channels.csv`
- JSON report: `output/report.json`
- Firestore writes: Direct integration with CRM database (production mode)

**Testing:**
- Test mode available: `python3 main.py --test --verbose` (CSV only, no Firestore writes)
- Full pytest suite: `pytest -v` (294+ tests)

---

### 2. YouTube Curator Discovery Tool

**Purpose:** Production-ready standalone tool for finding YouTube playlist curators with contact information.

**Location:** `youtube-curator-discovery/` subdirectory

**Script:** `youtube_curator_discovery.py`

**Capabilities:**
- Genre-specific curator discovery (30 pre-configured search queries)
- Smart email extraction (handles obfuscated formats: @ → (at), . → (dot), etc.)
- Social media detection (Instagram, Twitter/X handles)
- Curator signal detection (playlist-focused channel identification)
- Advanced filtering (min subscribers, min playlists, curator keywords)
- Cross-query deduplication (prevents duplicate channels)
- Rate limiting and quota management
- Progress logging with detailed statistics
- CSV export with comprehensive channel data
- JSON backup for raw data processing

**Authentication:**
- **Integrated OAuth** (Feb 6, 2026) - Shares parent `.env` credentials
- No separate API key required
- Uses same AWS API Gateway token endpoint as autopopulator

**Configuration:**
- `config.json` - Genre queries, filtering thresholds, export settings
- Shares parent `.env` for OAuth credentials

**Output:**
- Timestamped CSV: `curators_YYYYMMDD_HHMMSS.csv`
- JSON backup: `curators_YYYYMMDD_HHMMSS.json`
- Execution log: `curator_discovery.log`

**Key Features:**
- 30 genre-specific searches (indie, hip-hop, electronic, R&B, pop, rock, metal, etc.)
- Handles email obfuscation: `contact (at) example [dot] com` → `contact@example.com`
- Extracts social media: Instagram (@username), Twitter/X (@username)
- Curator keywords: "playlist", "curator", "submission", "send music", etc.
- Min thresholds: Configurable subscriber count (default: 100+), playlist count (default: 5+)

---

## Integration Architecture

### Credential Sharing

Both tools share the same OAuth credentials from a single `.env` file:

```
scripts/channel-population/
├── .env                          # ← Shared OAuth credentials
│   ├── YOUTUBE_TOKEN_URL
│   ├── DN_API_KEY
│   ├── SPOTIFY_CLIENT_ID (optional)
│   ├── SPOTIFY_CLIENT_SECRET (optional)
│   └── FIREBASE_CREDENTIALS_PATH (production only)
│
├── main.py                       # Autopopulator (reads .env)
├── search-config.json            # Autopopulator queries
│
└── youtube-curator-discovery/
    ├── config.json               # Curator tool settings (no credentials)
    └── youtube_curator_discovery.py  # Reads credentials from ../.env
```

**Migration Complete:** As of Feb 6, 2026, the curator discovery tool no longer requires a separate YouTube API key. It uses the same OAuth setup via `../.env`.

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     Discovery Phase                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐           ┌──────────────────┐       │
│  │  Autopopulator   │           │  Curator Tool    │       │
│  │    (main.py)     │           │ (subdirectory)   │       │
│  └────────┬─────────┘           └────────┬─────────┘       │
│           │                              │                  │
│           ├─ Reaction channels           ├─ Playlist curators│
│           ├─ Spotify playlists           ├─ Genre-specific   │
│           ├─ Topic filtering             ├─ Social media     │
│           └─ Email extraction            └─ Obfuscation handling│
│                                                              │
└─────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────┐
│                      Output Phase                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────┐         ┌────────────────────┐     │
│  │ CSV Files          │         │ JSON Files         │     │
│  │ ├─ youtube_*.csv   │         │ ├─ curators_*.json │     │
│  │ ├─ spotify_*.csv   │         │ └─ report.json     │     │
│  │ └─ curators_*.csv  │         └────────────────────┘     │
│  └────────────────────┘                                     │
│           │                                                  │
│           └─────────────┐                                    │
│                         ↓                                    │
│               ┌──────────────────┐                          │
│               │ Review & Merge   │                          │
│               │ (Manual/Scripted)│                          │
│               └─────────┬────────┘                          │
│                         ↓                                    │
│               ┌──────────────────┐                          │
│               │ Firestore CRM DB │                          │
│               │ (Production)     │                          │
│               └──────────────────┘                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Usage Workflows

### Workflow 1: Reaction Channel Outreach

**Goal:** Find reaction channels for music promotion.

```bash
cd ~/Work/mailer_frontend/payouts-mailer-app/scripts/channel-population

# Test run (CSV only)
python3 main.py --test --verbose

# Review results
cat output/report.json
cat output/youtube_reaction_channels.csv

# Production run (Firestore writes)
python3 main.py --verbose
```

**Expected Yield:** 5-15% email discovery rate (most channels don't publish emails)

---

### Workflow 2: Playlist Placement Campaign

**Goal:** Find playlist curators with contact info for song placements.

```bash
cd ~/Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/youtube-curator-discovery

# Run curator discovery (uses parent .env for OAuth)
python3 youtube_curator_discovery.py

# Review results
cat curators_*.csv

# Check logs for details
tail -f curator_discovery.log
```

**Expected Yield:** 10-20% email + 25-40% social media contact info

**Output Example:**
| channel_id | title | subscriber_count | playlist_count | emails | instagram | twitter |
|------------|-------|------------------|----------------|--------|-----------|---------|
| UCxxx... | Indie Vibes | 15,430 | 47 | contact@indie.com | indievibes | indievibes |
| UCyyy... | Chill Beats | 8,920 | 23 | promo@chill.net | chillbeats | chillbeatsYT |

---

### Workflow 3: Comprehensive Discovery

**Goal:** Maximize channel coverage by running both tools.

```bash
cd ~/Work/mailer_frontend/payouts-mailer-app/scripts/channel-population

# Step 1: Run autopopulator for reaction channels
python3 main.py --test --verbose

# Step 2: Run curator discovery for playlist curators
cd youtube-curator-discovery
python3 youtube_curator_discovery.py

# Step 3: Review both outputs
cd ..
cat output/youtube_reaction_channels.csv
cat youtube-curator-discovery/curators_*.csv

# Step 4: Merge/filter results as needed
# (Manual Excel/Sheets merge or scripted pandas processing)

# Step 5: Production Firestore write (if approved)
python3 main.py --verbose
```

---

## Tool Comparison

| Feature | Autopopulator | Curator Discovery |
|---------|--------------|-------------------|
| **Primary Target** | Reaction channels | Playlist curators |
| **Search Queries** | Configurable (`search-config.json`) | 30 genre-specific (hard-coded) |
| **Email Extraction** | Basic validation | Advanced obfuscation handling |
| **Social Media** | No | Yes (Instagram, Twitter) |
| **Firestore Integration** | Yes (production mode) | No (CSV/JSON only) |
| **Deduplication** | Per-run | Cross-query (global) |
| **Filtering** | Topic channels, min subs | Min playlists, curator signals |
| **Test Coverage** | 294+ unit tests | Manual testing |
| **Best Use Case** | CRM database population | Targeted outreach campaigns |

---

## API Quota Management

### YouTube Data API v3 Quotas

Both tools share the same daily quota limit:

- **Daily Limit:** 10,000 units (free tier)
- **Search Query:** 100 units per call
- **Channel Details:** 1 unit per channel
- **Playlist List:** 1 unit per channel

### Quota Usage Examples

**Autopopulator (4 queries, 200 channels):**
```
4 queries × 100 units = 400 units
200 channels × 1 unit (details) = 200 units
200 channels × 1 unit (playlists) = 200 units
Total: ~800 units (8% of daily quota)
```

**Curator Discovery (30 queries, 500 channels):**
```
30 queries × 100 units = 3,000 units
500 channels × 1 unit (details) = 500 units
500 channels × 1 unit (playlists) = 500 units
Total: ~4,000 units (40% of daily quota)
```

**Combined Run (Same Day):**
```
Autopopulator: 800 units
Curator Tool: 4,000 units
Total: 4,800 units (48% of daily quota) ✅ Safe
```

### Quota Best Practices

1. **Monitor Usage:** Both tools log quota consumption in real-time
2. **Split Runs:** Run autopopulator today, curator tool tomorrow if needed
3. **Reduce Queries:** Lower `max_results_per_query` in configs
4. **Check Console:** View actual usage at [Google Cloud Console](https://console.cloud.google.com/apis/dashboard)
5. **Request Increase:** Apply for quota increase if needed (1-2 day approval)

---

## Configuration Reference

### Autopopulator Configuration

**File:** `search-config.json`

```json
{
  "youtube_reaction": {
    "enabled": true,
    "queries": [
      {
        "q": "music reaction",
        "genre": "General",
        "max_results": 50,
        "min_subscribers": 10000
      }
    ]
  },
  "spotify_playlists": {
    "enabled": false
  },
  "filters": {
    "requireEmail": true,
    "excludeTopicChannels": true,
    "minSubscribers": 5000
  }
}
```

### Curator Tool Configuration

**File:** `youtube-curator-discovery/config.json`

```json
{
  "search_queries": [
    "indie music playlist curator",
    "hip hop playlist curator",
    "electronic music playlists"
  ],
  "search_settings": {
    "max_results_per_query": 50,
    "rate_limit_delay_seconds": 1
  },
  "filtering": {
    "min_subscribers": 100,
    "min_playlists": 5
  },
  "export_settings": {
    "include_json_backup": true,
    "output_directory": "."
  }
}
```

**Note:** No YouTube API key in curator config - uses parent `.env` OAuth credentials.

---

## Authentication Setup

### OAuth Configuration (Both Tools)

**File:** `.env` (root of channel-population directory)

```bash
# YouTube OAuth (AWS API Gateway)
YOUTUBE_TOKEN_URL=https://cjed05n28l.execute-api.us-east-1.amazonaws.com/staging/ikey
DN_API_KEY=EdYMZvxaTw3dxJ4S3mDGg3NAjIEke2LzaLihtkRp

# Spotify (Optional - autopopulator only)
SPOTIFY_CLIENT_ID=your_client_id_here
SPOTIFY_CLIENT_SECRET=your_client_secret_here

# Firebase (Production mode - autopopulator only)
FIREBASE_CREDENTIALS_PATH=path/to/firebase-credentials.json
```

### How OAuth Works

1. **Token Request:** Tool calls `YOUTUBE_TOKEN_URL` with `DN_API_KEY` header
2. **Token Response:** AWS API Gateway returns time-limited OAuth token
3. **API Calls:** Tool uses token for all YouTube Data API v3 operations
4. **Token Refresh:** Automatic when token expires

**Benefits:**
- No need to manage Google Cloud Console API keys
- Centralized access control via AWS API Gateway
- Automatic token refresh
- Shared credentials across tools

---

## Documentation

### Autopopulator Documentation

**Location:** `~/Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/docs/`

- **[API.md](../../Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/docs/API.md)** - Complete API reference
- **[DEVELOPMENT.md](../../Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/docs/DEVELOPMENT.md)** - Developer guide
- **[OAUTH.md](../../Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/docs/OAUTH.md)** - OAuth setup guide
- **[INTEGRATIONS.md](../../Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/docs/INTEGRATIONS.md)** - Firestore integration
- **[ARCHITECTURE.md](../../Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/docs/ARCHITECTURE.md)** - System architecture

### Curator Tool Documentation

**Location:** `~/Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/youtube-curator-discovery/`

- **[README.md](../../Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/youtube-curator-discovery/README.md)** - Complete user guide
- **[START_HERE.md](../../Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/youtube-curator-discovery/START_HERE.md)** - Quick start guide
- **[OAUTH_MIGRATION.md](../../Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/youtube-curator-discovery/OAUTH_MIGRATION.md)** - Credential sharing details
- **[MIGRATION_COMPLETE.md](../../Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/youtube-curator-discovery/MIGRATION_COMPLETE.md)** - Integration test results
- **[PROJECT_SUMMARY.md](../../Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/youtube-curator-discovery/PROJECT_SUMMARY.md)** - Tool capabilities
- **[QUICKSTART.md](../../Work/mailer_frontend/payouts-mailer-app/scripts/channel-population/youtube-curator-discovery/QUICKSTART.md)** - 5-minute setup

---

## Testing

### Autopopulator Test Suite

**Location:** `scripts/channel-population/tests/`

**Run Tests:**
```bash
cd ~/Work/mailer_frontend/payouts-mailer-app/scripts/channel-population

# Run all tests (294+ tests)
pytest -v

# Run with coverage
pytest --cov=. --cov-report=term-missing

# Run specific module tests
pytest test_email_extractor.py -v
pytest test_youtube_api.py -v
```

**Coverage:**
- EmailExtractor: 48 tests
- YouTubeAPI: 22 tests
- SpotifyAPI: 26 tests
- FirestoreDB: 13 tests
- YouTubeChannelPopulator: 98 tests
- SpotifyPlaylistPopulator: 21 tests
- CSVExporter: 42 tests
- CLI: 18 tests
- Main Integration: 22 tests

### Curator Tool Testing

**Location:** `youtube-curator-discovery/`

**Test Approach:**
- Manual integration testing
- OAuth credential verification
- Sample query execution
- Output validation

**Run Test:**
```bash
cd youtube-curator-discovery
python3 youtube_curator_discovery.py
# Verify CSV/JSON outputs and log file
```

---

## Troubleshooting

### Common Issues

**Issue:** "Token retrieval failed with status 403"
- **Cause:** Invalid `DN_API_KEY` or `YOUTUBE_TOKEN_URL`
- **Fix:** Verify `.env` credentials, check endpoint accessibility

**Issue:** "Quota exceeded"
- **Cause:** Daily 10,000 unit limit reached
- **Fix:** Wait for quota reset (midnight PT), reduce `max_results`, or request increase

**Issue:** "No channels added" / "Zero yield"
- **Cause:** Normal behavior - most channels lack public emails
- **Fix:** Lower `min_subscribers` threshold, add more queries, try different search terms

**Issue:** "Configuration key contains placeholder value"
- **Cause:** Spotify credentials not set (optional feature)
- **Fix:** Disable Spotify in config or add real credentials

### Debug Logs

**Autopopulator:**
```bash
# Enable verbose logging
python3 main.py --test --verbose

# Check quota usage
grep "Quota used" logs/*.log
```

**Curator Tool:**
```bash
# Tail live log
tail -f curator_discovery.log

# Review completed run
cat curator_discovery.log | grep "ERROR\|WARNING"
```

---

## Integration Status

### OAuth Migration - ✅ Complete (Feb 6, 2026)

- **Status:** Production-ready
- **Verification:** Both tools tested with shared `.env` credentials
- **Documentation:** All guides updated (OAUTH_MIGRATION.md, MIGRATION_COMPLETE.md)
- **Benefits:**
  - Single credential file for both tools
  - Simplified setup (no duplicate API keys)
  - Consistent authentication across suite
  - Easier maintenance and rotation

### Firestore Integration - ✅ Complete

- **Status:** Production-ready (autopopulator only)
- **Mode:** Test mode (CSV) or production mode (Firestore writes)
- **Collection:** Channels stored in CRM Firestore database
- **Deduplication:** Firestore IDs prevent duplicate entries

### Testing - ✅ Complete

- **Autopopulator:** 294+ unit tests, full pytest coverage
- **Curator Tool:** Manual integration testing, OAuth verified
- **Combined Run:** Tested with both tools in same day (quota safe)

---

## Future Enhancements

### Potential Improvements

1. **Automated Merging:** Script to combine autopopulator + curator CSV outputs
2. **Curator Firestore Integration:** Add direct database writes to curator tool
3. **Scheduler Integration:** Cron jobs for periodic discovery runs
4. **Result Deduplication:** Global dedup across both tools
5. **Enhanced Filtering:** Machine learning for curator quality scoring
6. **API Gateway Monitoring:** Dashboard for OAuth token usage
7. **Webhook Integration:** Real-time notifications when high-value channels found

---

## Related Documentation

### CRM Application

- **[api-integrations.md](./api-integrations.md)** - AWS API Gateway, OAuth setup
- **[data-flow-patterns.md](./data-flow-patterns.md)** - Firestore data architecture
- **[authentication-flows.md](./authentication-flows.md)** - OAuth flows and token management

### Project Context

- **Project Tag:** `channels-autopopulator`
- **TaskMaster TUI:** Available in project task tracking
- **Completion:** 93% (14/15 tasks) as of Feb 6, 2026

---

## Contact & Support

For issues, questions, or feature requests related to the Channel Population Tools Suite:

1. Check tool-specific documentation (links above)
2. Review troubleshooting sections in READMEs
3. Verify OAuth credentials in `.env`
4. Check Google Cloud Console for quota usage
5. Review logs for detailed error messages

---

**Last Updated:** February 6, 2026  
**Integration Status:** Production-ready ✅  
**OAuth Migration:** Complete ✅  
**Documentation:** Comprehensive ✅

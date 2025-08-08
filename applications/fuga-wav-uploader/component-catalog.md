# FUGA WAV Uploader Component Catalog

## Overview

This component catalog provides a comprehensive overview of all major components in the FUGA WAV Uploader application, organized by functional modules and architectural layers.

## Module Organization

### Backend Flask Blueprints

#### Upload Routes Module (`blueprints/upload_routes.py`)
**Purpose**: Handles file upload operations and health check functionality
**Location**: `blueprints/upload_routes.py`
**Key Features**:
- Multi-file WAV upload processing
- File validation and format checking
- Health check endpoint for monitoring
- Upload progress tracking
- Error handling and user feedback

**Dependencies**:
- Flask framework
- File validation utilities
- FUGA API client
- AWS utilities (if configured)

**Integration Points**:
- Connects to FUGA asset creation endpoints
- Integrates with file validation utilities
- Provides status updates to frontend components

#### FUGA Authentication Module (`blueprints/fuga_auth_routes.py`)
**Purpose**: Manages FUGA API authentication and session handling
**Location**: `blueprints/fuga_auth_routes.py`
**Key Features**:
- FUGA API login and authentication
- Session token management
- Authentication status tracking
- Credential validation

**Dependencies**:
- FUGA API client
- Flask session management
- Configuration management

**Integration Points**:
- Required by all FUGA API operations
- Provides authentication tokens for subsequent requests
- Validates user credentials against FUGA platform

#### Product Management Module (`blueprints/fuga_product_routes.py`)
**Purpose**: Handles FUGA product (album) creation and management
**Location**: `blueprints/fuga_product_routes.py`
**Key Features**:
- Album/product creation in FUGA system
- Product metadata management
- Territory configuration for distribution
- Album artwork upload and processing
- Product retrieval and updates

**Dependencies**:
- FUGA API client
- File handling utilities
- Authentication module

**Integration Points**:
- Creates FUGA products for album releases
- Manages album-level metadata and artwork
- Configures distribution territories

#### Asset Management Module (`blueprints/fuga_asset_routes.py`)
**Purpose**: Manages individual track assets and audio file uploads
**Location**: `blueprints/fuga_asset_routes.py`
**Key Features**:
- Track/asset creation in FUGA system
- Audio file upload to FUGA platform
- Asset metadata assignment
- Contributor management (artists, producers, writers)
- Audio format validation and processing

**Dependencies**:
- FUGA API client
- Audio processing utilities
- File validation
- ffmpeg for audio analysis

**Integration Points**:
- Creates individual track assets within FUGA products
- Handles direct audio file uploads to FUGA
- Validates WAV file formats and rejects floating point files

#### Data Management Module (`blueprints/fuga_data_routes.py`)
**Purpose**: Fetches and caches FUGA reference data
**Location**: `blueprints/fuga_data_routes.py`
**Key Features**:
- Artists, labels, people, and genres data retrieval
- Local caching of FUGA reference data
- Data refresh and synchronization
- Search functionality for cached data

**Dependencies**:
- FUGA API client
- JSON file handling
- Data synchronization utilities

**Integration Points**:
- Provides reference data for frontend autocomplete components
- Caches frequently accessed FUGA data locally
- Supports search and filtering operations

#### Search Routes Module (`blueprints/fuga_search_routes.py`)
**Purpose**: Provides search functionality for local cached data
**Location**: `blueprints/fuga_search_routes.py`
**Key Features**:
- Local search for artists, labels, people
- Fuzzy matching and filtering
- Performance-optimized search algorithms
- Search result ranking and sorting

**Dependencies**:
- Cached FUGA data files
- Search algorithms
- Data filtering utilities

**Integration Points**:
- Powers frontend autocomplete and search components
- Provides fast local search without FUGA API calls
- Supports real-time search suggestions

#### Data Synchronization Module (`blueprints/fuga_sync_routes.py`)
**Purpose**: Manages data synchronization and status reporting
**Location**: `blueprints/fuga_sync_routes.py`
**Key Features**:
- Automatic data refresh scheduling
- Manual data synchronization triggers
- Sync status tracking and reporting
- Data backup and versioning

**Dependencies**:
- FUGA API client
- Scheduling utilities
- File system operations

**Integration Points**:
- Maintains fresh reference data for the application
- Provides sync status to frontend components
- Handles data consistency and backup operations

### Frontend React Components

#### Main Upload Interface Module

##### TrackUploader Component (`frontend/src/TrackUploader.tsx`)
**Purpose**: Primary upload interface and workflow orchestration
**Location**: `frontend/src/TrackUploader.tsx`
**Props**: 
- Configuration objects for FUGA API settings
- Authentication state management
**Key Features**:
- Drag-and-drop file upload interface
- Multi-step upload workflow management
- Real-time progress tracking
- Comprehensive error handling and user feedback
- Form validation and submission

**Dependencies**:
- React hooks for state management
- Material-UI components
- API service layer
- Validation utilities

**Integration Points**:
- Orchestrates all upload workflow components
- Manages global application state
- Handles communication with backend APIs

#### Album Management Components

##### AlbumImageUploader Component (`frontend/src/components/album/AlbumImageUploader.tsx`)
**Purpose**: Album artwork upload and preview functionality
**Location**: `frontend/src/components/album/AlbumImageUploader.tsx`
**Props**:
- `onImageSelect`: Callback for image selection
- `currentImage`: Current album artwork state
- `disabled`: Upload disabled state
**Key Features**:
- Image file selection and validation
- Image preview and cropping
- Upload progress tracking
- Format validation (JPG, PNG, etc.)

**Dependencies**:
- File input handling
- Image processing utilities
- Upload progress components

**Integration Points**:
- Provides album artwork for FUGA product creation
- Integrates with main upload workflow
- Validates image formats and dimensions

##### AlbumMetadataForm Component (`frontend/src/components/album/AlbumMetadataForm.tsx`)
**Purpose**: Album-level metadata input and validation
**Location**: `frontend/src/components/album/AlbumMetadataForm.tsx`
**Props**:
- `albumData`: Album metadata object
- `onAlbumChange`: Metadata change callback
- `errors`: Validation error state
- `labels`: Available labels for selection
**Key Features**:
- Comprehensive album metadata input fields
- Real-time validation and error display
- Label and artist autocomplete
- UPC code validation and formatting

**Dependencies**:
- Form validation hooks
- Autocomplete components
- Label and artist data

**Integration Points**:
- Provides metadata for FUGA product creation
- Validates required fields before submission
- Integrates with reference data components

##### AlbumSummary Component (`frontend/src/components/album/AlbumSummary.tsx`)
**Purpose**: Album information display and review
**Location**: `frontend/src/components/album/AlbumSummary.tsx`
**Props**:
- `albumData`: Complete album information
- `tracks`: Array of track objects
- `onEdit`: Edit mode callback
**Key Features**:
- Formatted album information display
- Track listing with metadata
- Edit and review functionality
- Pre-submission validation summary

**Dependencies**:
- Display formatting utilities
- Track components
- Edit mode management

**Integration Points**:
- Final review step in upload workflow
- Displays complete album and track information
- Provides edit access to all components

#### Track Management Components

##### TrackItem Component (`frontend/src/components/track/TrackItem.tsx`)
**Purpose**: Individual track display and management
**Location**: `frontend/src/components/track/TrackItem.tsx`
**Props**:
- `track`: Track data object
- `onUpdate`: Track update callback
- `onDelete`: Track deletion callback
- `artists`: Available artists for selection
- `people`: Available people for contributor roles
**Key Features**:
- Track metadata display and editing
- Contributor management interface
- Audio file information display
- Track-specific validation

**Dependencies**:
- Track metadata forms
- Contributor management
- Audio metadata utilities

**Integration Points**:
- Displays track information within track lists
- Provides editing interface for track metadata
- Manages track-specific contributors and roles

##### TrackList Component (`frontend/src/components/track/TrackList.tsx`)
**Purpose**: Collection of tracks with bulk operations
**Location**: `frontend/src/components/track/TrackList.tsx`
**Props**:
- `tracks`: Array of track objects
- `onTracksUpdate`: Bulk update callback
- `artists`: Available artists
- `people`: Available people
**Key Features**:
- Drag-and-drop track reordering
- Bulk metadata operations
- Track validation status display
- Add/remove track functionality

**Dependencies**:
- TrackItem components
- Drag-and-drop utilities
- Bulk operation handlers

**Integration Points**:
- Manages collection of track components
- Provides bulk operations for efficiency
- Validates all tracks before submission

##### TrackMetadataForm Component (`frontend/src/components/track/TrackMetadataForm.tsx`)
**Purpose**: Detailed track metadata input and validation
**Location**: `frontend/src/components/track/TrackMetadataForm.tsx`
**Props**:
- `trackData`: Track metadata object
- `onTrackChange`: Track change callback
- `genres`: Available genres
- `artists`: Available artists
- `people`: Available contributors
**Key Features**:
- Comprehensive track metadata fields
- ISRC code validation and generation
- Genre and language selection
- Contributor role assignment

**Dependencies**:
- Form validation utilities
- Genre and language data
- ISRC validation

**Integration Points**:
- Provides detailed metadata for FUGA asset creation
- Validates required fields and formats
- Integrates with autocomplete components

#### Common UI Components

##### FileUploadButton Component (`frontend/src/components/common/FileUploadButton.tsx`)
**Purpose**: Reusable file upload interface
**Location**: `frontend/src/components/common/FileUploadButton.tsx`
**Props**:
- `onFileSelect`: File selection callback
- `acceptedTypes`: Allowed file types
- `multiple`: Multiple file selection
- `disabled`: Upload disabled state
**Key Features**:
- Drag-and-drop file selection
- File type validation
- Multiple file handling
- Visual upload states

**Dependencies**:
- File input handling
- Drag-and-drop events
- File validation utilities

**Integration Points**:
- Used throughout application for file uploads
- Provides consistent upload interface
- Validates file types before processing

##### ProgressIndicator Component (`frontend/src/components/common/ProgressIndicator.tsx`)
**Purpose**: Visual progress tracking for uploads
**Location**: `frontend/src/components/common/ProgressIndicator.tsx`
**Props**:
- `progress`: Current progress percentage
- `phase`: Current operation phase
- `error`: Error state information
- `onCancel`: Cancel operation callback
**Key Features**:
- Real-time progress visualization
- Phase-based progress tracking
- Error state display
- Cancellation support

**Dependencies**:
- Progress calculation utilities
- Error handling components
- Material-UI progress components

**Integration Points**:
- Displays progress for all upload operations
- Provides user feedback during processing
- Handles error states and recovery

##### StyledComponents (`frontend/src/components/common/StyledComponents.tsx`)
**Purpose**: Reusable styled UI components
**Location**: `frontend/src/components/common/StyledComponents.tsx`
**Key Features**:
- Consistent styling across application
- Theme-aware component styling
- Responsive design utilities
- Custom Material-UI component extensions

**Dependencies**:
- Styled-components library
- Material-UI theme system
- Custom theme configuration

**Integration Points**:
- Provides consistent styling throughout application
- Maintains design system compliance
- Supports responsive layouts

##### UploadErrorHandler Component (`frontend/src/components/common/UploadErrorHandler.tsx`)
**Purpose**: Comprehensive error handling and user feedback
**Location**: `frontend/src/components/common/UploadErrorHandler.tsx`
**Props**:
- `error`: Error object with details
- `onRetry`: Retry operation callback
- `onDismiss`: Error dismissal callback
**Key Features**:
- User-friendly error message formatting
- FUGA API error parsing
- Retry and recovery options
- Error categorization and guidance

**Dependencies**:
- Error parsing utilities
- User feedback components
- Recovery action handlers

**Integration Points**:
- Handles errors from all application operations
- Provides consistent error user experience
- Supports error recovery workflows

#### Input Components

##### ChipInput Component (`frontend/src/components/ChipInput.tsx`)
**Purpose**: Multi-select input with chip-based display
**Location**: `frontend/src/components/ChipInput.tsx`
**Props**:
- `options`: Available selection options
- `value`: Currently selected values
- `onChange`: Selection change callback
- `label`: Input field label
**Key Features**:
- Multi-select with visual chips
- Autocomplete functionality
- Add/remove individual selections
- Keyboard navigation support

**Dependencies**:
- Material-UI Autocomplete
- Chip components
- Input validation

**Integration Points**:
- Used for genre, territory, and contributor selection
- Provides consistent multi-select interface
- Supports dynamic option loading

##### LabelAutocomplete Component (`frontend/src/components/LabelAutocomplete.tsx`)
**Purpose**: Label selection with search and autocomplete
**Location**: `frontend/src/components/LabelAutocomplete.tsx`
**Props**:
- `labels`: Available labels
- `onLabelSelect`: Label selection callback
- `value`: Current label value
**Key Features**:
- Real-time label search
- New label creation support
- Fuzzy matching for search results
- Label validation and formatting

**Dependencies**:
- Label data from backend
- Search algorithms
- Autocomplete components

**Integration Points**:
- Provides label selection for albums
- Connects to cached label data
- Supports label creation workflow

##### PersonChipInput Component (`frontend/src/components/PersonChipInput.tsx`)
**Purpose**: People/contributor selection with role assignment
**Location**: `frontend/src/components/PersonChipInput.tsx`
**Props**:
- `people`: Available people
- `onPeopleChange`: People selection callback
- `roles`: Available contributor roles
- `value`: Current people selection
**Key Features**:
- People selection with role assignment
- Multiple role support per person
- Search and autocomplete functionality
- Role validation and constraints

**Dependencies**:
- People data from backend
- Role definitions
- Multi-select components

**Integration Points**:
- Manages track and album contributors
- Connects to cached people data
- Validates contributor roles

##### StringChipInput Component (`frontend/src/components/StringChipInput.tsx`)
**Purpose**: Generic string-based multi-select input
**Location**: `frontend/src/components/StringChipInput.tsx`
**Props**:
- `values`: Current string values
- `onChange`: Value change callback
- `placeholder`: Input placeholder text
- `validation`: String validation rules
**Key Features**:
- Free-form string input
- Multi-value support with chips
- Input validation and formatting
- Add/remove string values

**Dependencies**:
- String validation utilities
- Chip display components
- Input handling

**Integration Points**:
- Used for custom metadata fields
- Provides flexible string input
- Supports validation requirements

##### TerritoriesChipInput Component (`frontend/src/components/TerritoriesChipInput.tsx`)
**Purpose**: Territory selection for distribution configuration
**Location**: `frontend/src/components/TerritoriesChipInput.tsx`
**Props**:
- `territories`: Available territories
- `onTerritoriesChange`: Territory change callback
- `value`: Selected territories
**Key Features**:
- Global territory selection
- Region-based grouping
- All/none selection shortcuts
- Territory validation and constraints

**Dependencies**:
- Territory definitions
- Geographic data
- Multi-select components

**Integration Points**:
- Configures album distribution territories
- Validates territory selections
- Supports region-based operations

### Utility Modules

#### Backend Utilities

##### Shared State Module (`utils/shared_state.py`)
**Purpose**: Global state management for Flask application
**Location**: `utils/shared_state.py`
**Key Features**:
- Global variables for application state
- Session management utilities
- Configuration state tracking
- Thread-safe state operations

**Integration Points**:
- Shared across all Flask blueprints
- Maintains global application configuration
- Provides state consistency

##### AWS Utils Module (`utils/aws_utils.py`)
**Purpose**: AWS service integration utilities
**Location**: `utils/aws_utils.py`
**Key Features**:
- AWS service client management
- Error handling for AWS operations
- Configuration management
- Service integration abstractions

**Integration Points**:
- Supports AWS ECS deployment
- Provides AWS service abstractions
- Handles AWS authentication and configuration

##### File Utils Module (`utils/file_utils.py`)
**Purpose**: File handling and validation utilities
**Location**: `utils/file_utils.py`
**Key Features**:
- File format validation
- Audio file analysis
- File size and type checking
- Temporary file management

**Integration Points**:
- Used by upload routes for file validation
- Provides file processing utilities
- Supports audio format detection

##### FUGA Utils Module (`utils/fuga_utils.py`)
**Purpose**: Common FUGA API utilities and error handling
**Location**: `utils/fuga_utils.py`
**Key Features**:
- FUGA API response processing
- Error code translation
- Common API operations
- Response formatting utilities

**Integration Points**:
- Shared across all FUGA-related blueprints
- Provides consistent API error handling
- Abstracts common FUGA operations

#### Frontend Utilities

##### Audio Utils (`frontend/src/utils/audioUtils.ts`)
**Purpose**: Audio file processing and metadata extraction
**Location**: `frontend/src/utils/audioUtils.ts`
**Key Features**:
- WAV metadata extraction
- Audio format validation
- Duration calculation
- Sample rate detection

**Integration Points**:
- Processes audio files before upload
- Provides metadata for track forms
- Validates audio file formats

##### Icon Utils (`frontend/src/utils/iconUtils.tsx`)
**Purpose**: Icon management and display utilities
**Location**: `frontend/src/utils/iconUtils.tsx`
**Key Features**:
- Material-UI icon abstractions
- Custom icon components
- Icon theme integration
- Icon state management

**Integration Points**:
- Provides consistent iconography
- Supports theme-based icon styling
- Used throughout UI components

##### Local Cache (`frontend/src/utils/localCache.ts`)
**Purpose**: Client-side data caching and management
**Location**: `frontend/src/utils/localCache.ts`
**Key Features**:
- Browser localStorage management
- Cache expiration handling
- Data serialization utilities
- Cache invalidation strategies

**Integration Points**:
- Caches FUGA reference data locally
- Improves application performance
- Reduces API calls for static data
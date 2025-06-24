# Local Development Environment

## Overview

This directory contains the local development environment for the Arrgh Email Processor workflow. It enables rapid prototyping and testing of LangChain/LangGraph logic before deployment to n8n.

## Directory Structure

```
local-development/
├── notebooks/          # Jupyter notebooks for development
├── python/            # Python modules and utilities
├── test-data/         # Sample email data for testing
├── deploy/            # Deployment scripts and configs
├── requirements.txt   # Python dependencies
└── README.md         # This file
```

## Setup

### 1. Create Virtual Environment

```bash
cd workflows/arrgh-email-processor/local-development
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Environment Variables

Create a `.env` file in this directory:

```bash
# AI Model API Keys
ANTHROPIC_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here
GOOGLE_API_KEY=your_key_here

# n8n Configuration
N8N_API_KEY=your_n8n_api_key
N8N_BASE_URL=https://n8n.paulbonneville.com

# AWS Configuration (for testing S3 integration)
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_DEFAULT_REGION=us-west-2

# Development Settings
DEBUG=true
LOG_LEVEL=DEBUG
```

### 4. Start Jupyter

```bash
jupyter notebook
```

## Development Workflow

### 1. Prototyping Phase
- Use `notebooks/langchain-agent-dev.ipynb` for main development
- Experiment with LangGraph workflows
- Test with sample email data

### 2. Simulation Phase
- Use `notebooks/n8n-input-simulation.ipynb` to test n8n compatibility
- Validate input/output formats
- Test error handling

### 3. Export Phase
- Use `notebooks/deployment-export.ipynb` to generate n8n configs
- Export optimized code for n8n deployment
- Validate configuration format

## Key Features

### n8n Node Simulation
The `python/n8n_langchain_simulator.py` module provides local simulation of n8n's AI Agent node behavior, enabling accurate testing before deployment.

### Configuration Export
The `python/n8n_config_exporter.py` module automatically generates n8n node configurations from local LangGraph implementations.

### Real Data Testing
The `test-data/` directory contains actual email samples from webhook tests, ensuring development uses realistic data.

## Best Practices

1. **Always test with real email data** from the test-data directory
2. **Use the n8n simulator** to validate compatibility before deployment
3. **Export configurations** using the provided utilities
4. **Version control** all development work
5. **Document decisions** in the planning folder

## Troubleshooting

### Common Issues

1. **Package Installation Failures**
   - Ensure Python 3.8+ is being used
   - Update pip: `pip install --upgrade pip`
   - Try installing packages individually

2. **API Key Issues**
   - Check `.env` file is properly formatted
   - Verify API keys are valid and have proper permissions
   - Ensure environment variables are loaded in notebooks

3. **Memory/Performance Issues**
   - Limit conversation buffer size during development
   - Use smaller models for initial testing
   - Monitor token usage carefully

## Next Steps

1. Set up the virtual environment and install dependencies
2. Configure API keys in `.env` file
3. Start with the main development notebook
4. Review sample email data in test-data directory
5. Begin prototyping email processing logic
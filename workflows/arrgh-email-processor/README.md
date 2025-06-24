# Arrgh Email Processor - n8n Workflow Documentation

## Overview
This n8n workflow processes inbound emails received through AWS SES (Simple Email Service). Emails sent to your configured domain are automatically processed, parsed, and can trigger custom business logic.

**Current Status**: Enhanced with AI-powered email processing using LangChain agents and comprehensive local development environment.

## Architecture Flow

```
📧 Email sent to @your-subdomain.your-domain.com
    ↓
🌐 DNS MX record routes to AWS SES
    ↓
📦 SES stores email in S3 bucket
    ↓
🔔 SNS notification sent to n8n webhook
    ↓
⚙️ n8n workflow processes the notification
    ↓
🤖 AI Agent analyzes and categorizes email content
    ↓
📊 Enhanced business logic with intelligent processing
    ↓
✅ Response sent back to AWS
```

## Current Workflow Components

### Production Workflow (ID: B59fialntF5x0ZUC)
**Status**: Active | **Last Updated**: 2025-06-23T21:56:44.748Z

#### Node Structure:
1. **Webhook** - Entry point for SNS notifications
2. **Is Subscription Confirmation?** - Routes SNS subscription confirmations
3. **Confirm Subscription** - Handles AWS SNS subscription confirmation
4. **Subscription Response** - Responds to subscription confirmations
5. **Is Email Notification?** - Validates email notification messages
6. **Parse Email Metadata** - Extracts email metadata from SNS payload
7. **Download Email from S3** - Retrieves email content from S3 storage
8. **Parse Email Content** - Parses raw email into structured data
9. **Process Content** - Basic Python processing (ready for AI enhancement)
10. **Success Response** - Returns processing confirmation
11. **Send email** - Test email sending capability

### Enhanced Development Architecture (Ready for Deployment)
The development environment provides tools to enhance the current **Process Content** node with:
- **AI Agent**: Intelligent email categorization and analysis
- **Memory Buffer**: Conversation context and thread tracking
- **Advanced Processing**: Entity extraction and action recommendations

## Local Development Environment

### 🚀 Quick Start

```bash
# Navigate to development environment
cd workflows/arrgh-email-processor/local-development

# Set up Python environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your configuration:
#   - Replace EMAIL_DOMAIN with your domain
#   - Replace EMAIL_SUBDOMAIN with your subdomain
#   - Add your AI model API keys
#   - Configure your n8n instance URL

# Start Jupyter development
jupyter notebook
```

### 🔐 Environment Configuration

Edit the `.env` file to configure your domain and credentials:

```bash
# Your domain configuration
EMAIL_DOMAIN=yourdomain.com
EMAIL_SUBDOMAIN=yoursubdomain

# This creates: yoursubdomain.yourdomain.com
# Configure test email addresses:
TEST_EMAIL_INVOICE=invoices@yoursubdomain.yourdomain.com
TEST_EMAIL_SUPPORT=support@yoursubdomain.yourdomain.com
# ... etc

# Add your API keys
ANTHROPIC_API_KEY=your_key_here
N8N_API_KEY=your_n8n_key
# ... etc
```

### 📁 Development Structure

```
workflows/arrgh-email-processor/
├── planning/                    # 📋 Project documentation & architecture
│   ├── development-plan.md      # Main development roadmap
│   ├── langchain-node-analysis.md # n8n LangChain integration analysis
│   ├── workflow-architecture.md # Enhanced workflow design
│   └── requirements-analysis.md # Technical requirements & acceptance criteria
├── local-development/           # 🔧 Development workspace
│   ├── notebooks/               # 📓 Jupyter development environment
│   │   ├── langchain-agent-dev.ipynb     # Main AI agent development
│   │   ├── n8n-input-simulation.ipynb    # n8n compatibility testing
│   │   └── deployment-export.ipynb       # Configuration generation
│   ├── python/                  # 🐍 Utilities and simulators
│   │   ├── n8n_langchain_simulator.py    # Local n8n node simulation
│   │   └── n8n_config_exporter.py        # n8n configuration generator
│   ├── test-data/              # 🧪 Real email samples & test data
│   │   ├── sample-sns-payloads.json      # SNS notification examples
│   │   ├── sample-email-content.json     # Email content samples
│   │   └── n8n-node-inputs.json         # n8n input/output formats
│   ├── deploy/                  # 🚀 Generated deployment configurations
│   ├── requirements.txt        # Python dependencies
│   └── README.md              # Development setup guide
└── scripts/                    # Existing deployment and test scripts
    ├── test-sns-webhook.sh     # Webhook testing
    └── Arrgh_Email_Processor.json # Current workflow export
```

### 🔬 Development Workflow

#### 1. **Local Prototyping Phase**
- Use **`langchain-agent-dev.ipynb`** for full LangChain/LangGraph development
- Test with real email data samples
- Develop custom tools for email categorization and entity extraction
- Iterate quickly with immediate feedback

#### 2. **Compatibility Testing Phase**
- Use **`n8n-input-simulation.ipynb`** to test n8n format compatibility
- Validate input/output structures match n8n expectations
- Test error handling and edge cases
- Simulate complete workflow execution

#### 3. **Configuration Export Phase**
- Use **`deployment-export.ipynb`** to generate n8n node configurations
- Export AI Agent, Memory, and Python node configs
- Generate deployment scripts and validation

#### 4. **Deployment Phase**
- Import generated configurations into n8n
- Replace current **Process Content** node with AI-enhanced version
- Test with real webhook data
- Monitor performance and accuracy

### 🤖 AI Enhancement Features

#### **Intelligent Email Categorization**
- **Invoice**: Payment requests, billing information, amounts, due dates
- **Support**: Help requests, technical issues, urgent problems
- **Sales**: Business opportunities, proposals, meeting requests
- **General**: Newsletters, announcements, general correspondence
- **Spam**: Unwanted or suspicious emails

#### **Entity Extraction**
- **Financial**: Invoice numbers, amounts, due dates, payment terms
- **Contacts**: Names, email addresses, phone numbers
- **Dates**: Meeting times, deadlines, event dates
- **Keywords**: Important terms and phrases for routing

#### **Priority Assessment**
- **High**: Urgent requests, critical issues, time-sensitive matters
- **Medium**: Standard business requests, invoices, follow-ups
- **Low**: General information, newsletters, non-urgent items

#### **Action Recommendations**
- **Routing**: Forward to appropriate teams or systems
- **Scheduling**: Set reminders for due dates and follow-ups
- **Integration**: Connect with CRM, ticketing, or payment systems
- **Automation**: Trigger workflows based on email content

### 🧪 Test Data Available

#### **Sample Email Types**
- **Invoice Email**: Complete billing information with amounts and due dates
- **Support Email**: Urgent production system issue with contact details
- **Sales Email**: Partnership opportunity with meeting requests
- **General Email**: Technology newsletter with event information

#### **SNS Payload Examples**
- Subscription confirmation messages
- Email notification payloads for different email types
- Real webhook input formats from AWS SES

#### **n8n Node Formats**
- Complete input/output examples for each workflow node
- Memory buffer context examples
- AI agent response formats

## Current Workflow Details

### Data Flow

#### SNS Subscription Confirmation Flow
```
Webhook → Is Subscription Confirmation? (TRUE)
    ↓
Confirm Subscription → Subscription Response
```

#### Email Processing Flow
```
Webhook → Is Subscription Confirmation? (FALSE)
    ↓
Is Email Notification? (TRUE)
    ↓
Parse Email Metadata
    ↓
Download Email from S3
    ↓
Parse Email Content
    ↓
Process Content (🚀 Ready for AI Enhancement)
    ↓
Success Response
```

### Current Process Content Node
**Language**: Python  
**Current Logic**:
- Logs email details (from, subject, body preview)
- Basic categorization (invoice, support, general)
- Returns processing summary

**Enhancement Ready**: This node is designed to be replaced with the AI-enhanced version developed in the local environment.

## Configuration Requirements

### AWS Prerequisites
1. **SES Domain Verification**: Your domain verified in AWS SES
2. **MX Record**: DNS MX record pointing to AWS SES inbound endpoints
3. **S3 Bucket**: For email storage (configured in environment variables)
4. **SNS Topic**: For real-time notifications to n8n
5. **IAM Permissions**: n8n needs S3 read access

### n8n Configuration

#### Required Credentials
- **AWS Credentials**: For S3 bucket access (configure in n8n)
- **SMTP Credentials**: For email sending capabilities (if needed)

#### Webhook Configuration
- **Path**: `inbound-email` (or as configured in environment variables)
- **Method**: POST
- **Response Mode**: responseNode
- **URL**: `https://your-n8n-instance.com/webhook/inbound-email`

#### AWS S3 Integration
- **Bucket**: Configured via environment variables
- **Region**: Configured via environment variables
- **Authentication**: AWS credentials with S3 read permissions

## Enhanced Development Capabilities

### 🔧 Utilities Available

#### **n8n Node Simulator**
- **AI Agent Simulator**: Local simulation of n8n's LangChain agent behavior
- **Memory Simulator**: Buffer window memory with conversation tracking
- **Python Code Simulator**: Execute and test Python node logic locally
- **Workflow Simulator**: End-to-end workflow execution testing

#### **Configuration Exporter**
- **AI Agent Nodes**: Generate LangChain agent configurations
- **Memory Nodes**: Create memory buffer and persistent memory configs
- **Python Nodes**: Export preprocessing and postprocessing code
- **Complete Workflows**: Generate full n8n workflow JSON

#### **Testing Framework**
- **Real Data Testing**: Use actual email samples from webhook tests
- **Input/Output Validation**: Ensure n8n compatibility
- **Error Simulation**: Test failure scenarios and recovery
- **Performance Analysis**: Measure processing times and token usage

### 🎯 Ready for Enhancement

The current workflow is production-ready and can be enhanced with AI capabilities through the development environment. The **Process Content** node is specifically designed as the integration point for AI-powered email processing.

**Next Steps for AI Integration**:
1. Develop AI logic in `langchain-agent-dev.ipynb`
2. Test compatibility in `n8n-input-simulation.ipynb`
3. Export configurations in `deployment-export.ipynb`
4. Deploy enhanced nodes to replace current **Process Content**

## Testing

### Current Test Capabilities
```bash
# Test webhook with various email types
./scripts/test-sns-webhook.sh test

# Test specific email notification
./scripts/test-sns-webhook.sh email

# Test subscription confirmation
./scripts/test-sns-webhook.sh confirm
```

### Development Environment Testing
```bash
# Start Jupyter for interactive development
cd local-development
jupyter notebook

# Run notebook-based tests with real data
# Execute n8n compatibility simulations
# Generate and validate configurations
```

## Security and Performance

### Current Security Measures
- AWS credentials with minimal S3 read permissions
- HTTPS webhook endpoints
- 30-day email retention policy in S3
- Secure credential storage in n8n

### Performance Characteristics
- **Processing Time**: Current workflow processes emails in ~2-3 seconds
- **Scalability**: Handles moderate email volumes efficiently
- **Cost**: Minimal AWS charges for S3 storage and SNS notifications
- **Reliability**: Built-in retry mechanisms and error handling

### AI Enhancement Considerations
- **Token Usage**: Monitor AI model consumption and costs
- **Processing Time**: AI analysis may add 1-3 seconds per email
- **Accuracy**: Target >95% categorization accuracy
- **Fallback**: Graceful degradation to basic processing if AI fails

## Troubleshooting

### Common Issues
1. **Webhook not triggering**: Check SNS subscription status
2. **S3 download fails**: Verify AWS credentials and permissions
3. **Email parsing errors**: Check email format and encoding
4. **Processing failures**: Review Python code execution logs

### Development Environment Issues
1. **Dependencies**: Ensure all Python packages are installed correctly
2. **API Keys**: Verify AI model credentials in `.env` file
3. **Jupyter**: Check notebook kernel and environment activation
4. **Compatibility**: Validate n8n input/output format matching

---

**🚀 Ready to enhance your email processing with AI!** Use the local development environment to build sophisticated email analysis capabilities, then seamlessly deploy to your production n8n workflow.
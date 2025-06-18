# Google Cloud Cleanup Instructions

If you need to clean up Google Cloud resources from the failed Cloud Run deployment, run these commands:

## 1. Delete Cloud Run Services
```bash
gcloud run services delete n8n --region=us-central1 --quiet
gcloud run services delete n8n-simple --region=us-central1 --quiet  
gcloud run services delete n8n-stable --region=us-central1 --quiet
```

## 2. Delete Cloud SQL Instance
```bash
gcloud sql instances delete n8n-db --quiet
```

## 3. Delete Secrets
```bash
gcloud secrets delete n8n-auth-password --quiet
gcloud secrets delete n8n-db-password --quiet
gcloud secrets delete n8n-encryption-key --quiet
```

## 4. Check for Remaining Resources
```bash
# List any remaining Cloud Run services
gcloud run services list --region=us-central1

# List SQL instances
gcloud sql instances list

# List secrets
gcloud secrets list
```

## Note
- These commands will permanently delete the resources
- The Cloud SQL instance deletion will remove all data
- You're keeping the GCP project for future GKE deployment
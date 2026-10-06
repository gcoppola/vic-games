#!/usr/bin/env bash
# ONE-TIME setup, run in Google Cloud Shell as the project owner. Lets GitHub Actions in gcoppola/vic-games (main branch
# only) deploy to gs://vic-games via Workload Identity Federation. No service-account key is created. Safe to re-run.
set -euo pipefail
PROJECT=lmemvp1 BUCKET=vic-games REPO=gcoppola/vic-games OWNER_ID=12781484 POOL=github-actions PROVIDER=vic-games SA=vic-games-deployer
SA_EMAIL="$SA@$PROJECT.iam.gserviceaccount.com"
NUM=$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')

gcloud services enable iam.googleapis.com iamcredentials.googleapis.com sts.googleapis.com --project "$PROJECT"

# the deployer: may only manage objects in the (already public) games bucket
gcloud iam service-accounts describe "$SA_EMAIL" --project "$PROJECT" >/dev/null 2>&1 ||
  gcloud iam service-accounts create "$SA" --project "$PROJECT" --display-name "vic-games deploy (GitHub Actions)"
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" --member "serviceAccount:$SA_EMAIL" --role roles/storage.objectAdmin >/dev/null

# trust GitHub's OIDC tokens — but only from this repo, owned by this account, on main
gcloud iam workload-identity-pools describe "$POOL" --project "$PROJECT" --location global >/dev/null 2>&1 ||
  gcloud iam workload-identity-pools create "$POOL" --project "$PROJECT" --location global --display-name "GitHub Actions"
gcloud iam workload-identity-pools providers describe "$PROVIDER" --project "$PROJECT" --location global --workload-identity-pool "$POOL" >/dev/null 2>&1 ||
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER" --project "$PROJECT" --location global --workload-identity-pool "$POOL" \
    --display-name "vic-games repo" --issuer-uri "https://token.actions.githubusercontent.com" \
    --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner_id=assertion.repository_owner_id,attribute.ref=assertion.ref" \
    --attribute-condition "assertion.repository=='$REPO' && assertion.repository_owner_id=='$OWNER_ID' && assertion.ref=='refs/heads/main'"

gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" --project "$PROJECT" --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/projects/$NUM/locations/global/workloadIdentityPools/$POOL/attribute.repository/$REPO" >/dev/null

echo
echo "Done. Provider: projects/$NUM/locations/global/workloadIdentityPools/$POOL/providers/$PROVIDER"
[ "$NUM" = "292617444643" ] || echo "NOTE: project number differs from the one in .github/workflows/deploy.yml — update workload_identity_provider there."
echo "Next: GitHub → gcoppola/vic-games → Actions → 'Deploy to gs://vic-games' → Run workflow (or just merge to main)."

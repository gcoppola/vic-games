# ONE-TIME setup, run in Windows PowerShell as the project owner (needs gcloud installed + signed in).
# Lets GitHub Actions in gcoppola/vic-games (main branch only) deploy to gs://vic-games via Workload Identity
# Federation. No service-account key is created. Safe to re-run. Same steps as setup-github-deploy.sh.
$Project='lmemvp1'; $Bucket='vic-games'; $Repo='gcoppola/vic-games'; $OwnerId='12781484'
$Pool='github-actions'; $Provider='vic-games'; $Sa='vic-games-deployer'
$SaEmail="$Sa@$Project.iam.gserviceaccount.com"

if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) { Write-Error 'gcloud is not installed. Get it from https://cloud.google.com/sdk/docs/install'; exit 1 }
if (-not (gcloud auth list --filter=status:ACTIVE --format='value(account)')) { gcloud auth login }

$Num = gcloud projects describe $Project --format='value(projectNumber)'
if (-not $Num) { Write-Error "Cannot read project $Project - is this the right Google account?"; exit 1 }

gcloud services enable iam.googleapis.com iamcredentials.googleapis.com sts.googleapis.com --project $Project

# the deployer: may only manage objects in the (already public) games bucket
gcloud iam service-accounts describe $SaEmail --project $Project 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { gcloud iam service-accounts create $Sa --project $Project --display-name 'vic-games deploy (GitHub Actions)' }
gcloud storage buckets add-iam-policy-binding "gs://$Bucket" --member "serviceAccount:$SaEmail" --role roles/storage.objectAdmin | Out-Null

# trust GitHub's OIDC tokens - but only from this repo, owned by this account, on main
gcloud iam workload-identity-pools describe $Pool --project $Project --location global 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { gcloud iam workload-identity-pools create $Pool --project $Project --location global --display-name 'GitHub Actions' }
gcloud iam workload-identity-pools providers describe $Provider --project $Project --location global --workload-identity-pool $Pool 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  gcloud iam workload-identity-pools providers create-oidc $Provider --project $Project --location global --workload-identity-pool $Pool `
    --display-name 'vic-games repo' --issuer-uri 'https://token.actions.githubusercontent.com' `
    --attribute-mapping 'google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner_id=assertion.repository_owner_id,attribute.ref=assertion.ref' `
    --attribute-condition "assertion.repository=='$Repo' && assertion.repository_owner_id=='$OwnerId' && assertion.ref=='refs/heads/main'"
}
gcloud iam service-accounts add-iam-policy-binding $SaEmail --project $Project --role roles/iam.workloadIdentityUser `
  --member "principalSet://iam.googleapis.com/projects/$Num/locations/global/workloadIdentityPools/$Pool/attribute.repository/$Repo" | Out-Null

Write-Host ''
Write-Host "Done. Provider: projects/$Num/locations/global/workloadIdentityPools/$Pool/providers/$Provider"
if ($Num -ne '292617444643') { Write-Host 'NOTE: project number differs from the one in .github/workflows/deploy.yml - update workload_identity_provider there.' }
Write-Host 'Next: GitHub -> gcoppola/vic-games -> Actions -> "Deploy to gs://vic-games" -> Re-run (or just merge to main).'
